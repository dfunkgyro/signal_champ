-- ============================================================
-- SAFE MIGRATION TO OPTIMIZED SCHEMA
-- This script safely migrates from the original schema to the optimized version
-- ============================================================

-- IMPORTANT: This script is designed to work with existing databases
-- It checks for existing tables and policies before making changes

-- ============================================================
-- STEP 1: DROP OLD POLICIES (to avoid conflicts)
-- ============================================================

-- Drop existing policies if they exist
DO $$
BEGIN
    -- User settings policies
    DROP POLICY IF EXISTS "Users can view their own settings" ON user_settings;
    DROP POLICY IF EXISTS "Users can insert their own settings" ON user_settings;
    DROP POLICY IF EXISTS "Users can update their own settings" ON user_settings;
    DROP POLICY IF EXISTS "user_settings_select" ON user_settings;
    DROP POLICY IF EXISTS "user_settings_insert" ON user_settings;
    DROP POLICY IF EXISTS "user_settings_update" ON user_settings;

    -- Analytics events policies
    DROP POLICY IF EXISTS "Enable insert access for analytics events" ON analytics_events;
    DROP POLICY IF EXISTS "Enable read access for analytics events" ON analytics_events;
    DROP POLICY IF EXISTS "analytics_events_insert" ON analytics_events;
    DROP POLICY IF EXISTS "analytics_events_select" ON analytics_events;

    -- Metrics policies
    DROP POLICY IF EXISTS "Enable insert access for metrics" ON metrics;
    DROP POLICY IF EXISTS "Enable read access for metrics" ON metrics;
    DROP POLICY IF EXISTS "metrics_insert" ON metrics;
    DROP POLICY IF EXISTS "metrics_select" ON metrics;

    -- User locations policies
    DROP POLICY IF EXISTS "Users can manage their own locations" ON user_locations;
    DROP POLICY IF EXISTS "user_locations_all" ON user_locations;

    -- User properties policies
    DROP POLICY IF EXISTS "Users can manage their own properties" ON user_properties;
    DROP POLICY IF EXISTS "user_properties_all" ON user_properties;

    -- Connection test policies
    DROP POLICY IF EXISTS "Enable full access for connection test" ON connection_test;
    DROP POLICY IF EXISTS "connection_test_all" ON connection_test;

    -- App version policies
    DROP POLICY IF EXISTS "Enable read access for app version" ON app_version;
    DROP POLICY IF EXISTS "app_version_select" ON app_version;

    -- SSM intents policies
    DROP POLICY IF EXISTS "Enable read access for ssm intents" ON ssm_intents;
    DROP POLICY IF EXISTS "ssm_intents_select" ON ssm_intents;

    RAISE NOTICE 'Old policies dropped successfully';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Error dropping policies (this is OK if tables dont exist): %', SQLERRM;
END $$;

-- ============================================================
-- STEP 2: MIGRATION STRATEGY DECISION
-- ============================================================

-- Check if analytics_events exists and if it's partitioned
DO $$
DECLARE
    table_exists BOOLEAN;
    is_partitioned BOOLEAN;
    row_count BIGINT;
BEGIN
    -- Check if table exists
    SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'analytics_events'
    ) INTO table_exists;

    IF NOT table_exists THEN
        RAISE NOTICE '=== NEW DATABASE: Will create fresh optimized schema ===';
        RAISE NOTICE 'Run: optimized_supabase_setup.sql';
    ELSE
        -- Check if already partitioned
        SELECT EXISTS (
            SELECT 1 FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE c.relname = 'analytics_events'
            AND c.relkind = 'p'
        ) INTO is_partitioned;

        IF is_partitioned THEN
            RAISE NOTICE '=== ALREADY OPTIMIZED: analytics_events is partitioned ===';
            RAISE NOTICE 'No migration needed. Just updating policies and indexes.';
        ELSE
            SELECT COUNT(*) FROM analytics_events INTO row_count;
            RAISE NOTICE '=== MIGRATION REQUIRED ===';
            RAISE NOTICE 'analytics_events has % rows and needs to be partitioned', row_count;
            RAISE NOTICE 'RECOMMENDATION: Use migration path below based on data volume';

            IF row_count < 100000 THEN
                RAISE NOTICE '✅ Small dataset (<%): Use IN-PLACE MIGRATION', row_count;
            ELSIF row_count < 1000000 THEN
                RAISE NOTICE '⚠️ Medium dataset (<%): Use CAREFUL MIGRATION or EXPORT/IMPORT', row_count;
            ELSE
                RAISE NOTICE '❌ Large dataset (<%): MUST use EXPORT/IMPORT migration', row_count;
            END IF;
        END IF;
    END IF;
END $$;

-- ============================================================
-- MIGRATION PATH A: IN-PLACE MIGRATION (Small datasets < 100K rows)
-- ============================================================
-- DANGER: This will lock tables during migration
-- Use only for small databases or during maintenance windows

/*
DO $$
DECLARE
    table_exists BOOLEAN;
BEGIN
    -- Check if analytics_events exists
    SELECT EXISTS (
        SELECT FROM pg_tables WHERE tablename = 'analytics_events'
    ) INTO table_exists;

    IF table_exists THEN
        -- Rename existing table
        ALTER TABLE analytics_events RENAME TO analytics_events_old;
        ALTER TABLE metrics RENAME TO metrics_old;

        RAISE NOTICE 'Old tables renamed. Now run optimized_supabase_setup.sql';
        RAISE NOTICE 'Then run the data migration below';
    END IF;
END $$;

-- After running optimized_supabase_setup.sql, migrate data:
INSERT INTO analytics_events (id, event_name, parameters, device_info, user_id, session_id, timestamp)
SELECT id, event_name, parameters, device_info, user_id, session_id, timestamp
FROM analytics_events_old;

INSERT INTO metrics (id, user_id, metric_name, value, timestamp, additional_data)
SELECT id, user_id, metric_name, value, timestamp,
       COALESCE(additional_data, '{}'::jsonb)
FROM metrics_old;

-- Verify counts match
SELECT 'analytics_events' as table_name,
       (SELECT COUNT(*) FROM analytics_events) as new_count,
       (SELECT COUNT(*) FROM analytics_events_old) as old_count;

SELECT 'metrics' as table_name,
       (SELECT COUNT(*) FROM metrics) as new_count,
       (SELECT COUNT(*) FROM metrics_old) as old_count;

-- If counts match, drop old tables:
-- DROP TABLE analytics_events_old CASCADE;
-- DROP TABLE metrics_old CASCADE;
*/

-- ============================================================
-- MIGRATION PATH B: EXPORT/IMPORT (Recommended for production)
-- ============================================================
-- This is the safest approach for any size database

/*
STEP-BY-STEP GUIDE:

1. EXPORT EXISTING DATA (from Supabase Dashboard or pg_dump):
   - Go to Supabase Dashboard > Database > Backups
   - Or use pg_dump:
     pg_dump -h host -U user -d database -t analytics_events -t metrics > backup.sql

2. VERIFY BACKUP:
   - Check file size
   - Verify row counts

3. RUN optimized_supabase_setup.sql:
   - This creates the new optimized schema
   - Tables will be empty initially

4. IMPORT DATA:
   Option A - Via SQL Editor (small datasets):
   - Copy data from backup

   Option B - Via pg_restore (large datasets):
   - pg_restore backup.sql

5. VERIFY:
   - Check row counts match
   - Test critical queries
*/

-- ============================================================
-- MIGRATION PATH C: BLUE-GREEN DEPLOYMENT (Zero downtime)
-- ============================================================
/*
1. Create new Supabase project with optimized schema
2. Set up real-time replication from old to new
3. Update app to write to both databases (dual-write)
4. Verify data consistency
5. Switch app to read from new database
6. Stop dual-write
7. Decommission old database

This is complex but provides zero downtime.
*/

-- ============================================================
-- STEP 3: UPDATE INDEXES AND POLICIES (Safe for existing DBs)
-- ============================================================

-- Only add missing indexes (won't fail if they exist)
DO $$
BEGIN
    -- User settings
    CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON user_settings(user_id)
        WHERE user_id IS NOT NULL;
    CREATE INDEX IF NOT EXISTS idx_user_settings_jsonb ON user_settings USING GIN(settings);

    -- User properties
    CREATE INDEX IF NOT EXISTS idx_user_properties_user ON user_properties(user_id, property_name);
    CREATE INDEX IF NOT EXISTS idx_user_properties_name ON user_properties(property_name)
        WHERE property_name IN ('subscription_tier', 'user_role', 'account_status');

    -- SSM intents
    CREATE INDEX IF NOT EXISTS idx_ssm_intents_intent_id ON ssm_intents(intent_id);
    CREATE INDEX IF NOT EXISTS idx_ssm_intents_category_severity ON ssm_intents(category, severity);
    CREATE INDEX IF NOT EXISTS idx_ssm_intents_terminal ON ssm_intents(is_terminal)
        WHERE is_terminal = false;
    CREATE INDEX IF NOT EXISTS idx_ssm_intents_steps_gin ON ssm_intents USING GIN(troubleshooting_steps);

    RAISE NOTICE 'Indexes created/verified successfully';
EXCEPTION
    WHEN others THEN
        RAISE WARNING 'Error creating indexes: %', SQLERRM;
END $$;

-- ============================================================
-- STEP 4: RECREATE POLICIES (Clean slate)
-- ============================================================

-- User settings
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_settings_select" ON user_settings
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "user_settings_insert" ON user_settings
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_settings_update" ON user_settings
    FOR UPDATE USING (auth.uid() = user_id);

-- Analytics events (if exists and not partitioned)
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'analytics_events') THEN
        ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

        CREATE POLICY "analytics_events_insert" ON analytics_events
            FOR INSERT WITH CHECK (true);

        CREATE POLICY "analytics_events_select" ON analytics_events
            FOR SELECT USING (
                auth.uid()::text = user_id OR
                user_id IS NULL OR
                NOT (user_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
            );
    END IF;
END $$;

-- Metrics (if exists and not partitioned)
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'metrics') THEN
        ALTER TABLE metrics ENABLE ROW LEVEL SECURITY;

        CREATE POLICY "metrics_insert" ON metrics
            FOR INSERT WITH CHECK (true);

        CREATE POLICY "metrics_select" ON metrics
            FOR SELECT USING (true);
    END IF;
END $$;

-- User locations
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'user_locations') THEN
        ALTER TABLE user_locations ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "user_locations_all" ON user_locations
            FOR ALL USING (auth.uid() = user_id);
    END IF;
END $$;

-- User properties
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'user_properties') THEN
        ALTER TABLE user_properties ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "user_properties_all" ON user_properties
            FOR ALL USING (auth.uid() = user_id);
    END IF;
END $$;

-- Connection test
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'connection_test') THEN
        ALTER TABLE connection_test ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "connection_test_all" ON connection_test
            FOR ALL USING (true);
    END IF;
END $$;

-- App version
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'app_version') THEN
        ALTER TABLE app_version ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "app_version_select" ON app_version
            FOR SELECT USING (true);
    END IF;
END $$;

-- SSM intents
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'ssm_intents') THEN
        ALTER TABLE ssm_intents ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "ssm_intents_select" ON ssm_intents
            FOR SELECT USING (true);
    END IF;
END $$;

-- ============================================================
-- STEP 5: UPDATE STATISTICS
-- ============================================================
DO $$
BEGIN
    -- Update statistics for better query planning
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'analytics_events') THEN
        ALTER TABLE analytics_events ALTER COLUMN event_name SET STATISTICS 500;
        ALTER TABLE analytics_events ALTER COLUMN user_id SET STATISTICS 500;
    END IF;

    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'metrics') THEN
        ALTER TABLE metrics ALTER COLUMN metric_name SET STATISTICS 500;
        ALTER TABLE metrics ALTER COLUMN user_id SET STATISTICS 500;
    END IF;

    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'user_locations') THEN
        ALTER TABLE user_locations ALTER COLUMN user_id SET STATISTICS 1000;
    END IF;

    RAISE NOTICE 'Statistics targets updated';
END $$;

-- ============================================================
-- STEP 6: CREATE/UPDATE FUNCTIONS
-- ============================================================

-- Timestamp update function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update triggers
DROP TRIGGER IF EXISTS update_user_settings_updated_at ON user_settings;
CREATE TRIGGER update_user_settings_updated_at
    BEFORE UPDATE ON user_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_app_version_updated_at ON app_version;
CREATE TRIGGER update_app_version_updated_at
    BEFORE UPDATE ON app_version
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_properties_updated_at ON user_properties;
CREATE TRIGGER update_user_properties_updated_at
    BEFORE UPDATE ON user_properties
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_ssm_intents_updated_at ON ssm_intents;
CREATE TRIGGER update_ssm_intents_updated_at
    BEFORE UPDATE ON ssm_intents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- VERIFICATION
-- ============================================================
DO $$
DECLARE
    table_count INTEGER;
    policy_count INTEGER;
    index_count INTEGER;
BEGIN
    -- Count tables
    SELECT COUNT(*) INTO table_count
    FROM pg_tables
    WHERE schemaname = 'public'
    AND tablename IN ('user_settings', 'analytics_events', 'metrics', 'user_locations',
                      'user_properties', 'connection_test', 'app_version', 'ssm_intents');

    -- Count policies
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public';

    -- Count indexes
    SELECT COUNT(*) INTO index_count
    FROM pg_indexes
    WHERE schemaname = 'public';

    RAISE NOTICE '=== MIGRATION VERIFICATION ===';
    RAISE NOTICE 'Tables: %', table_count;
    RAISE NOTICE 'Policies: %', policy_count;
    RAISE NOTICE 'Indexes: %', index_count;

    IF table_count = 8 THEN
        RAISE NOTICE '✅ All tables present';
    ELSE
        RAISE WARNING '⚠️ Some tables missing (expected 8, found %)', table_count;
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE '=== NEXT STEPS ===';
    RAISE NOTICE '1. Run ANALYZE to update query statistics';
    RAISE NOTICE '2. Test critical application queries';
    RAISE NOTICE '3. For full optimization, see OPTIMIZATION_SUMMARY.md';
    RAISE NOTICE '4. To migrate to partitioned tables, see migration paths above';
END $$;

-- Final statistics update
ANALYZE;

RAISE NOTICE '=== SAFE MIGRATION COMPLETE ===';
RAISE NOTICE 'Your database is now compatible with the optimized schema.';
RAISE NOTICE 'For FULL optimization with partitioning, follow the migration guide above.';
