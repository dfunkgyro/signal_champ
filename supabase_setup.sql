-- ============================================================
-- Supabase Database Setup for Rail Champ
-- Run these SQL commands in your Supabase SQL Editor
-- ============================================================

-- ============================================================
-- 1. USER SETTINGS TABLE
-- Stores user preferences and settings
-- ============================================================
CREATE TABLE IF NOT EXISTS user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    settings JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Enable Row Level Security
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_settings
CREATE POLICY "Users can view their own settings"
    ON user_settings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own settings"
    ON user_settings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings"
    ON user_settings FOR UPDATE
    USING (auth.uid() = user_id);

-- Index for faster lookups
CREATE INDEX idx_user_settings_user_id ON user_settings(user_id);

-- ============================================================
-- 2. METRICS TABLE
-- Stores application metrics and analytics
-- ============================================================
CREATE TABLE IF NOT EXISTS metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    value DOUBLE PRECISION NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE metrics ENABLE ROW LEVEL SECURITY;

-- RLS Policies for metrics (allow authenticated users to insert and read their own)
CREATE POLICY "Users can view their own metrics"
    ON metrics FOR SELECT
    USING (true);

CREATE POLICY "Users can insert metrics"
    ON metrics FOR INSERT
    WITH CHECK (true);

-- Indexes for faster queries
CREATE INDEX idx_metrics_user_id ON metrics(user_id);
CREATE INDEX idx_metrics_name ON metrics(metric_name);
CREATE INDEX idx_metrics_timestamp ON metrics(timestamp);

-- ============================================================
-- 3. ANALYTICS EVENTS TABLE
-- Stores detailed analytics events
-- ============================================================
CREATE TABLE IF NOT EXISTS analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_name TEXT NOT NULL,
    parameters JSONB DEFAULT '{}'::jsonb,
    device_info JSONB DEFAULT '{}'::jsonb,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

-- RLS Policies for analytics_events
CREATE POLICY "Anyone can insert analytics events"
    ON analytics_events FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Anyone can view analytics events"
    ON analytics_events FOR SELECT
    USING (true);

-- Indexes for faster queries
CREATE INDEX idx_analytics_event_name ON analytics_events(event_name);
CREATE INDEX idx_analytics_timestamp ON analytics_events(timestamp);

-- ============================================================
-- 4. USER LOCATIONS TABLE
-- Stores user location tracking data
-- ============================================================
CREATE TABLE IF NOT EXISTS user_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    altitude DOUBLE PRECISION,
    heading DOUBLE PRECISION,
    speed DOUBLE PRECISION,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE user_locations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_locations
CREATE POLICY "Users can view their own locations"
    ON user_locations FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own locations"
    ON user_locations FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Indexes for faster queries
CREATE INDEX idx_user_locations_user_id ON user_locations(user_id);
CREATE INDEX idx_user_locations_timestamp ON user_locations(timestamp);

-- Create a spatial index for location-based queries (optional)
-- Requires PostGIS extension
-- CREATE INDEX idx_user_locations_geom ON user_locations USING GIST (
--     ST_MakePoint(longitude, latitude)
-- );

-- ============================================================
-- 5. CONNECTION TEST TABLE
-- Simple table for testing database connectivity
-- ============================================================
CREATE TABLE IF NOT EXISTS connection_test (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE connection_test ENABLE ROW LEVEL SECURITY;

-- RLS Policy - anyone can read
CREATE POLICY "Anyone can read connection test"
    ON connection_test FOR SELECT
    USING (true);

-- Insert a test row
INSERT INTO connection_test (id) VALUES (uuid_generate_v4());

-- ============================================================
-- 6. APP VERSION TABLE
-- Stores app version information for force update mechanism
-- ============================================================
CREATE TABLE IF NOT EXISTS app_version (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    platform TEXT NOT NULL CHECK (platform IN ('android', 'ios')),
    minimum_version TEXT NOT NULL,
    latest_version TEXT NOT NULL,
    force_update BOOLEAN DEFAULT false,
    update_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(platform)
);

-- Enable Row Level Security
ALTER TABLE app_version ENABLE ROW LEVEL SECURITY;

-- RLS Policy - anyone can read
CREATE POLICY "Anyone can read app version"
    ON app_version FOR SELECT
    USING (true);

-- Insert default version info
INSERT INTO app_version (platform, minimum_version, latest_version, force_update, update_message)
VALUES
    ('android', '2.1.0', '2.1.0', false, 'Please update to the latest version for new features'),
    ('ios', '2.1.0', '2.1.0', false, 'Please update to the latest version for new features')
ON CONFLICT (platform) DO NOTHING;

-- ============================================================
-- 7. FUNCTIONS
-- Utility functions for analytics and metrics
-- ============================================================

-- Function to calculate metric statistics
CREATE OR REPLACE FUNCTION calculate_metric_stats(
    metric_name TEXT,
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (
    avg_value DOUBLE PRECISION,
    min_value DOUBLE PRECISION,
    max_value DOUBLE PRECISION,
    count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        AVG(value)::DOUBLE PRECISION,
        MIN(value)::DOUBLE PRECISION,
        MAX(value)::DOUBLE PRECISION,
        COUNT(*)::BIGINT
    FROM metrics
    WHERE
        metrics.metric_name = calculate_metric_stats.metric_name
        AND timestamp >= start_time
        AND timestamp <= end_time;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to clean old analytics data (run periodically)
CREATE OR REPLACE FUNCTION clean_old_analytics(days_to_keep INTEGER DEFAULT 90)
RETURNS VOID AS $$
BEGIN
    DELETE FROM analytics_events
    WHERE timestamp < NOW() - INTERVAL '1 day' * days_to_keep;

    DELETE FROM metrics
    WHERE timestamp < NOW() - INTERVAL '1 day' * days_to_keep;

    DELETE FROM user_locations
    WHERE timestamp < NOW() - INTERVAL '1 day' * days_to_keep;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 8. TRIGGERS
-- Automatic timestamp updates
-- ============================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for user_settings
CREATE TRIGGER update_user_settings_updated_at
    BEFORE UPDATE ON user_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for app_version
CREATE TRIGGER update_app_version_updated_at
    BEFORE UPDATE ON app_version
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 9. REALTIME
-- Enable realtime for specific tables
-- ============================================================

-- Enable realtime for metrics (optional)
-- ALTER PUBLICATION supabase_realtime ADD TABLE metrics;

-- Enable realtime for analytics_events (optional)
-- ALTER PUBLICATION supabase_realtime ADD TABLE analytics_events;

-- ============================================================
-- 10. STORAGE (optional)
-- Create storage buckets for user files
-- ============================================================

-- Create a bucket for user avatars
-- INSERT INTO storage.buckets (id, name, public)
-- VALUES ('avatars', 'avatars', true);

-- Create storage policies
-- CREATE POLICY "Avatar images are publicly accessible"
--     ON storage.objects FOR SELECT
--     USING (bucket_id = 'avatars');

-- CREATE POLICY "Users can upload their own avatar"
--     ON storage.objects FOR INSERT
--     WITH CHECK (
--         bucket_id = 'avatars' AND
--         auth.uid()::text = (storage.foldername(name))[1]
--     );

-- ============================================================
-- SETUP COMPLETE!
-- ============================================================

-- To verify the setup, run these queries:
-- SELECT * FROM connection_test;
-- SELECT * FROM app_version;
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
