-- ============================================================
-- Supabase Database Setup for Rail Champ
-- Clean setup with verified column names
-- ============================================================

-- ============================================================
-- 1. CLEANUP EXISTING TABLES (if they exist)
-- ============================================================
DROP VIEW IF EXISTS daily_analytics_summary CASCADE;
DROP VIEW IF EXISTS user_activity_summary CASCADE;
DROP FUNCTION IF EXISTS get_user_analytics_summary CASCADE;
DROP FUNCTION IF EXISTS clean_old_analytics_data CASCADE;
DROP FUNCTION IF EXISTS calculate_metric_stats CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column CASCADE;

DROP TABLE IF EXISTS ssm_intents CASCADE;
DROP TABLE IF EXISTS user_properties CASCADE;
DROP TABLE IF EXISTS user_locations CASCADE;
DROP TABLE IF EXISTS analytics_events CASCADE;
DROP TABLE IF EXISTS metrics CASCADE;
DROP TABLE IF EXISTS connection_test CASCADE;
DROP TABLE IF EXISTS app_version CASCADE;
DROP TABLE IF EXISTS user_settings CASCADE;

-- ============================================================
-- 2. USER SETTINGS TABLE
-- ============================================================
CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    settings JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own settings" ON user_settings
FOR ALL USING (auth.uid() = user_id);

CREATE INDEX idx_user_settings_user_id ON user_settings(user_id);

-- ============================================================
-- 3. ANALYTICS EVENTS TABLE (WITH CORRECT COLUMN NAMES)
-- ============================================================
CREATE TABLE analytics_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_name TEXT NOT NULL,
    parameters JSONB DEFAULT '{}',
    device_info JSONB DEFAULT '{}',
    user_id TEXT,
    session_id TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable full access for analytics events" ON analytics_events
FOR ALL USING (true);

CREATE INDEX idx_analytics_event_name ON analytics_events(event_name);
CREATE INDEX idx_analytics_timestamp ON analytics_events(timestamp);
CREATE INDEX idx_analytics_user_id ON analytics_events(user_id);

-- ============================================================
-- 4. METRICS TABLE
-- ============================================================
CREATE TABLE metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    value DOUBLE PRECISION NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    additional_data JSONB DEFAULT '{}'
);

ALTER TABLE metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable full access for metrics" ON metrics
FOR ALL USING (true);

CREATE INDEX idx_metrics_user_id ON metrics(user_id);
CREATE INDEX idx_metrics_name ON metrics(metric_name);
CREATE INDEX idx_metrics_timestamp ON metrics(timestamp);

-- ============================================================
-- 5. USER LOCATIONS TABLE
-- ============================================================
CREATE TABLE user_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    altitude DOUBLE PRECISION,
    heading DOUBLE PRECISION,
    speed DOUBLE PRECISION,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own locations" ON user_locations
FOR ALL USING (auth.uid() = user_id);

CREATE INDEX idx_user_locations_user_id ON user_locations(user_id);
CREATE INDEX idx_user_locations_timestamp ON user_locations(timestamp);

-- ============================================================
-- 6. USER PROPERTIES TABLE
-- ============================================================
CREATE TABLE user_properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    property_name TEXT NOT NULL,
    property_value TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, property_name)
);

ALTER TABLE user_properties ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own properties" ON user_properties
FOR ALL USING (auth.uid() = user_id);

CREATE INDEX idx_user_properties_user_id ON user_properties(user_id);

-- ============================================================
-- 7. CONNECTION TEST TABLE
-- ============================================================
CREATE TABLE connection_test (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_data TEXT DEFAULT 'Connection test successful',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE connection_test ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable full access for connection test" ON connection_test
FOR ALL USING (true);

INSERT INTO connection_test (id) VALUES (gen_random_uuid());

-- ============================================================
-- 8. APP VERSION TABLE
-- ============================================================
CREATE TABLE app_version (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
    minimum_version TEXT NOT NULL,
    latest_version TEXT NOT NULL,
    force_update BOOLEAN DEFAULT false,
    update_message TEXT,
    download_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(platform)
);

ALTER TABLE app_version ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for app version" ON app_version
FOR SELECT USING (true);

INSERT INTO app_version (platform, minimum_version, latest_version, force_update, update_message, download_url) VALUES
('android', '2.1.0', '2.1.0', false, 'Please update to the latest version', 'https://play.google.com/store/apps/details?id=com.example.rail_champ'),
('ios', '2.1.0', '2.1.0', false, 'Please update to the latest version', 'https://apps.apple.com/app/rail-champ/id123456789'),
('web', '2.1.0', '2.1.0', false, 'You are using the latest version', 'https://railchamp.example.com')
ON CONFLICT (platform) DO UPDATE SET
    minimum_version = EXCLUDED.minimum_version,
    latest_version = EXCLUDED.latest_version;

-- ============================================================
-- 9. SSM INTENTS TABLE
-- ============================================================
CREATE TABLE ssm_intents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    intent_id TEXT NOT NULL UNIQUE,
    question TEXT NOT NULL,
    clean_question TEXT NOT NULL,
    is_terminal BOOLEAN DEFAULT false,
    yes_intent_id TEXT,
    no_intent_id TEXT,
    troubleshooting_steps JSONB DEFAULT '[]',
    severity TEXT CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    category TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE ssm_intents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for ssm intents" ON ssm_intents
FOR SELECT USING (true);

CREATE INDEX idx_ssm_intents_intent_id ON ssm_intents(intent_id);

INSERT INTO ssm_intents (intent_id, question, clean_question, is_terminal, yes_intent_id, no_intent_id, severity, category) VALUES
('start', 'Are you experiencing issues with signal failure?', 'Are you experiencing issues with signal failure?', false, 'signal_power', 'track_circuit', 'medium', 'signaling'),
('signal_power', 'Is the signal displaying no lights or incorrect aspects?', 'Is the signal displaying no lights or incorrect aspects?', false, 'signal_power_check', 'signal_communication', 'high', 'signaling'),
('signal_power_check', 'Check power supply to signal head. Is voltage within 10.5-12.5V range?', 'Check power supply to signal head. Is voltage within 10.5-12.5V range?', false, 'signal_lamp_check', 'replace_power_supply', 'high', 'signaling'),
('resolution_signal_lamp', 'Signal issue resolved by lamp replacement. Document in maintenance log.', 'Signal issue resolved by lamp replacement.', true, null, null, 'low', 'resolution');

-- ============================================================
-- 10. FUNCTIONS
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calculate_metric_stats(
    p_metric_name TEXT,
    p_start_time TIMESTAMPTZ DEFAULT NOW() - INTERVAL '7 days',
    p_end_time TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
    avg_value DOUBLE PRECISION,
    min_value DOUBLE PRECISION,
    max_value DOUBLE PRECISION,
    count_records BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        AVG(value),
        MIN(value),
        MAX(value),
        COUNT(*)
    FROM metrics
    WHERE metric_name = p_metric_name
        AND timestamp BETWEEN p_start_time AND p_end_time;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION clean_old_analytics_data(days_to_keep INTEGER DEFAULT 90)
RETURNS JSONB AS $$
DECLARE
    deleted_events BIGINT;
    deleted_metrics BIGINT;
    deleted_locations BIGINT;
BEGIN
    DELETE FROM analytics_events WHERE timestamp < NOW() - (days_to_keep || ' days')::INTERVAL;
    GET DIAGNOSTICS deleted_events = ROW_COUNT;

    DELETE FROM metrics WHERE timestamp < NOW() - (days_to_keep || ' days')::INTERVAL;
    GET DIAGNOSTICS deleted_metrics = ROW_COUNT;

    DELETE FROM user_locations WHERE timestamp < NOW() - (days_to_keep || ' days')::INTERVAL;
    GET DIAGNOSTICS deleted_locations = ROW_COUNT;

    RETURN jsonb_build_object(
        'deleted_events', deleted_events,
        'deleted_metrics', deleted_metrics,
        'deleted_locations', deleted_locations
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 11. TRIGGERS
-- ============================================================
CREATE TRIGGER update_user_settings_updated_at
    BEFORE UPDATE ON user_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_app_version_updated_at
    BEFORE UPDATE ON app_version
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_properties_updated_at
    BEFORE UPDATE ON user_properties
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ssm_intents_updated_at
    BEFORE UPDATE ON ssm_intents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 12. VIEWS
-- ============================================================
CREATE OR REPLACE VIEW daily_analytics_summary AS
SELECT 
    DATE(timestamp) as date,
    event_name,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users
FROM analytics_events
WHERE timestamp >= NOW() - INTERVAL '30 days'
GROUP BY DATE(timestamp), event_name
ORDER BY date DESC, event_count DESC;

CREATE OR REPLACE VIEW user_activity_summary AS
SELECT 
    user_id,
    COUNT(*) as total_events,
    MIN(timestamp) as first_activity,
    MAX(timestamp) as last_activity
FROM analytics_events
WHERE user_id IS NOT NULL
GROUP BY user_id;

-- ============================================================
-- VERIFICATION
-- ============================================================
DO $$ 
BEGIN
    RAISE NOTICE '=== Rail Champ Database Setup Complete ===';
    RAISE NOTICE 'Tables created: user_settings, analytics_events, metrics, user_locations, user_properties, connection_test, app_version, ssm_intents';
    RAISE NOTICE 'Functions created: update_updated_at_column, calculate_metric_stats, clean_old_analytics_data';
    RAISE NOTICE 'Views created: daily_analytics_summary, user_activity_summary';
    RAISE NOTICE 'Sample data inserted for connection_test, app_version, and ssm_intents';
END $$;

-- Test queries
SELECT 'Connection test:' as test, COUNT(*) as count FROM connection_test;
SELECT 'App versions:' as test, COUNT(*) as count FROM app_version;
SELECT 'SSM intents:' as test, COUNT(*) as count FROM ssm_intents;
SELECT 'Analytics events columns:' as test, 
    string_agg(column_name, ', ') as columns
FROM information_schema.columns 
WHERE table_name = 'analytics_events';
