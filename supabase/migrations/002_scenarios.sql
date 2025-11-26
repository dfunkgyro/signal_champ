-- Create scenarios table
CREATE TABLE IF NOT EXISTS scenarios (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    author_name TEXT,
    category TEXT NOT NULL CHECK (category IN ('rushHour', 'emergency', 'trackMaintenance', 'custom', 'tutorial', 'challenge')),
    difficulty TEXT NOT NULL CHECK (difficulty IN ('beginner', 'intermediate', 'advanced', 'expert')),
    is_public BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    downloads INTEGER DEFAULT 0,
    rating NUMERIC(3, 2) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
    rating_count INTEGER DEFAULT 0,

    -- Layout data
    canvas_width NUMERIC DEFAULT 7000,
    canvas_height NUMERIC DEFAULT 1200,
    tracks JSONB DEFAULT '[]'::jsonb,
    signals JSONB DEFAULT '[]'::jsonb,
    points JSONB DEFAULT '[]'::jsonb,
    block_sections JSONB DEFAULT '[]'::jsonb,
    train_spawns JSONB DEFAULT '[]'::jsonb,

    -- Objectives and constraints
    objectives JSONB DEFAULT '[]'::jsonb,
    time_limit INTEGER,
    max_trains INTEGER,

    -- Metadata
    tags TEXT[] DEFAULT '{}',
    thumbnail_url TEXT,
    metadata JSONB
);

-- Create scenario ratings table
CREATE TABLE IF NOT EXISTS scenario_ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scenario_id UUID NOT NULL REFERENCES scenarios(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rating NUMERIC(3, 2) NOT NULL CHECK (rating >= 0 AND rating <= 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(scenario_id, user_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_scenarios_author_id ON scenarios(author_id);
CREATE INDEX IF NOT EXISTS idx_scenarios_is_public ON scenarios(is_public);
CREATE INDEX IF NOT EXISTS idx_scenarios_is_featured ON scenarios(is_featured);
CREATE INDEX IF NOT EXISTS idx_scenarios_category ON scenarios(category);
CREATE INDEX IF NOT EXISTS idx_scenarios_difficulty ON scenarios(difficulty);
CREATE INDEX IF NOT EXISTS idx_scenarios_downloads ON scenarios(downloads DESC);
CREATE INDEX IF NOT EXISTS idx_scenarios_rating ON scenarios(rating DESC);
CREATE INDEX IF NOT EXISTS idx_scenarios_created_at ON scenarios(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_scenarios_updated_at ON scenarios(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_scenarios_tags ON scenarios USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_scenario_ratings_scenario_id ON scenario_ratings(scenario_id);
CREATE INDEX IF NOT EXISTS idx_scenario_ratings_user_id ON scenario_ratings(user_id);

-- Enable Row Level Security
ALTER TABLE scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE scenario_ratings ENABLE ROW LEVEL SECURITY;

-- Policies for scenarios table
-- Anyone can read public scenarios
CREATE POLICY "Public scenarios are viewable by everyone"
    ON scenarios FOR SELECT
    USING (is_public = true);

-- Users can read their own scenarios
CREATE POLICY "Users can view their own scenarios"
    ON scenarios FOR SELECT
    USING (auth.uid() = author_id);

-- Users can create their own scenarios
CREATE POLICY "Users can create scenarios"
    ON scenarios FOR INSERT
    WITH CHECK (auth.uid() = author_id);

-- Users can update their own scenarios
CREATE POLICY "Users can update their own scenarios"
    ON scenarios FOR UPDATE
    USING (auth.uid() = author_id);

-- Users can delete their own scenarios
CREATE POLICY "Users can delete their own scenarios"
    ON scenarios FOR DELETE
    USING (auth.uid() = author_id);

-- Policies for scenario_ratings table
-- Users can read all ratings
CREATE POLICY "Ratings are viewable by everyone"
    ON scenario_ratings FOR SELECT
    USING (true);

-- Users can create ratings
CREATE POLICY "Authenticated users can create ratings"
    ON scenario_ratings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own ratings
CREATE POLICY "Users can update their own ratings"
    ON scenario_ratings FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own ratings
CREATE POLICY "Users can delete their own ratings"
    ON scenario_ratings FOR DELETE
    USING (auth.uid() = user_id);

-- Function to increment scenario downloads
CREATE OR REPLACE FUNCTION increment_scenario_downloads(scenario_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE scenarios
    SET downloads = downloads + 1
    WHERE id = scenario_id;
END;
$$;

-- Function to update scenario rating
CREATE OR REPLACE FUNCTION update_scenario_rating(scenario_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE scenarios s
    SET
        rating = COALESCE((
            SELECT AVG(rating)::numeric(3,2)
            FROM scenario_ratings
            WHERE scenario_ratings.scenario_id = s.id
        ), 0),
        rating_count = COALESCE((
            SELECT COUNT(*)
            FROM scenario_ratings
            WHERE scenario_ratings.scenario_id = s.id
        ), 0)
    WHERE s.id = scenario_id;
END;
$$;

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_scenarios_updated_at
    BEFORE UPDATE ON scenarios
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert pre-built challenge scenarios
INSERT INTO scenarios (
    id,
    name,
    description,
    author_id,
    author_name,
    category,
    difficulty,
    is_public,
    is_featured,
    canvas_width,
    canvas_height,
    tracks,
    signals,
    points,
    block_sections,
    train_spawns,
    objectives,
    time_limit,
    max_trains,
    tags
) VALUES
-- Rush Hour Challenge
(
    gen_random_uuid(),
    'Morning Rush Hour',
    'Handle the morning rush hour with multiple trains arriving simultaneously. Manage signal priorities and prevent delays while maintaining safety.',
    (SELECT id FROM auth.users LIMIT 1),
    'Rail Champ Team',
    'rushHour',
    'intermediate',
    true,
    true,
    7000,
    1200,
    '[]'::jsonb,
    '[]'::jsonb,
    '[]'::jsonb,
    '[]'::jsonb,
    '[
        {
            "id": "train_1",
            "trainType": "m1",
            "x": 100,
            "y": 500,
            "direction": "east",
            "spawnDelaySeconds": 0,
            "destination": "Platform 3"
        },
        {
            "id": "train_2",
            "trainType": "m2",
            "x": 6900,
            "y": 600,
            "direction": "west",
            "spawnDelaySeconds": 30,
            "destination": "Platform 1"
        },
        {
            "id": "train_3",
            "trainType": "cbtcM1",
            "x": 100,
            "y": 700,
            "direction": "east",
            "spawnDelaySeconds": 60,
            "destination": "Platform 2"
        }
    ]'::jsonb,
    '[
        {
            "id": "obj_1",
            "description": "Successfully dispatch all 3 trains to their destinations",
            "type": "deliver",
            "parameters": {"count": 3},
            "points": 300
        },
        {
            "id": "obj_2",
            "description": "Avoid any collisions",
            "type": "avoid_collision",
            "parameters": {},
            "points": 200
        },
        {
            "id": "obj_3",
            "description": "Complete within time limit",
            "type": "time_limit",
            "parameters": {"seconds": 300},
            "points": 100
        }
    ]'::jsonb,
    300,
    3,
    ARRAY['rush-hour', 'beginner-friendly', 'time-trial']
),
-- Emergency Scenario
(
    gen_random_uuid(),
    'Emergency Track Blockage',
    'A track blockage has occurred! Reroute trains using alternative routes while emergency crews work on the main line.',
    (SELECT id FROM auth.users LIMIT 1),
    'Rail Champ Team',
    'emergency',
    'advanced',
    true,
    true,
    7000,
    1200,
    '[]'::jsonb,
    '[]'::jsonb,
    '[]'::jsonb,
    '[]'::jsonb,
    '[
        {
            "id": "train_1",
            "trainType": "m1",
            "x": 1000,
            "y": 500,
            "direction": "east",
            "spawnDelaySeconds": 0,
            "destination": "Platform 4"
        },
        {
            "id": "train_2",
            "trainType": "m2",
            "x": 2000,
            "y": 500,
            "direction": "east",
            "spawnDelaySeconds": 0,
            "destination": "Platform 4"
        }
    ]'::jsonb,
    '[
        {
            "id": "obj_1",
            "description": "Reroute all trains via crossover",
            "type": "deliver",
            "parameters": {"useAlternateRoute": true},
            "points": 400
        },
        {
            "id": "obj_2",
            "description": "Maintain safe separation between trains",
            "type": "avoid_collision",
            "parameters": {},
            "points": 300
        },
        {
            "id": "obj_3",
            "description": "Handle emergency within 5 minutes",
            "type": "time_limit",
            "parameters": {"seconds": 300},
            "points": 200
        }
    ]'::jsonb,
    300,
    2,
    ARRAY['emergency', 'rerouting', 'advanced']
),
-- Track Maintenance
(
    gen_random_uuid(),
    'Weekend Track Maintenance',
    'Coordinate train movements while track maintenance is in progress. Limited routes available with reduced speed zones.',
    (SELECT id FROM auth.users LIMIT 1),
    'Rail Champ Team',
    'trackMaintenance',
    'intermediate',
    true,
    true,
    7000,
    1200,
    '[]'::jsonb,
    '[]'::jsonb,
    '[]'::jsonb,
    '[]'::jsonb,
    '[
        {
            "id": "train_1",
            "trainType": "m1",
            "x": 100,
            "y": 600,
            "direction": "east",
            "spawnDelaySeconds": 0,
            "destination": "Depot"
        }
    ]'::jsonb,
    '[
        {
            "id": "obj_1",
            "description": "Navigate through maintenance zones safely",
            "type": "deliver",
            "parameters": {"avoidMaintenanceZones": true},
            "points": 300
        },
        {
            "id": "obj_2",
            "description": "Respect reduced speed limits",
            "type": "efficiency",
            "parameters": {"maxSpeed": 20},
            "points": 200
        }
    ]'::jsonb,
    600,
    1,
    ARRAY['maintenance', 'slow-zones', 'planning']
),
-- Tutorial Scenario
(
    gen_random_uuid(),
    'Basic Operations Tutorial',
    'Learn the basics of train control: setting routes, managing signals, and operating points. Perfect for beginners!',
    (SELECT id FROM auth.users LIMIT 1),
    'Rail Champ Team',
    'tutorial',
    'beginner',
    true,
    true,
    7000,
    1200,
    '[]'::jsonb,
    '[]'::jsonb,
    '[]'::jsonb,
    '[]'::jsonb,
    '[
        {
            "id": "train_1",
            "trainType": "m1",
            "x": 100,
            "y": 500,
            "direction": "east",
            "spawnDelaySeconds": 0,
            "destination": "Platform 1"
        }
    ]'::jsonb,
    '[
        {
            "id": "obj_1",
            "description": "Set a route for the train",
            "type": "deliver",
            "parameters": {"routeRequired": true},
            "points": 100
        },
        {
            "id": "obj_2",
            "description": "Successfully deliver train to platform",
            "type": "deliver",
            "parameters": {"count": 1},
            "points": 100
        }
    ]'::jsonb,
    null,
    1,
    ARRAY['tutorial', 'beginner', 'learn']
)
ON CONFLICT (id) DO NOTHING;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION increment_scenario_downloads TO authenticated;
GRANT EXECUTE ON FUNCTION update_scenario_rating TO authenticated;
