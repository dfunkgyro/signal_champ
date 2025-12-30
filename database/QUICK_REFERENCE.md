# Supabase Performance Optimization - Quick Reference

## 🚀 Setup (One-time)

```bash
# Run optimized schema
psql $DATABASE_URL -f database/optimized_supabase_setup.sql

# Or via Supabase Dashboard:
# SQL Editor > New Query > Paste contents > Run
```

---

## 📅 Scheduled Maintenance (Set & Forget)

```sql
-- Setup Supabase cron jobs (run once)

-- 1. Refresh analytics views every 6 hours
SELECT cron.schedule(
    'refresh-analytics-views',
    '0 */6 * * *',
    $$ SELECT refresh_analytics_views(); $$
);

-- 2. Create new partitions monthly
SELECT cron.schedule(
    'create-partitions',
    '0 0 1 * *',
    $$
    SELECT create_monthly_partitions('analytics_events', 3);
    SELECT create_monthly_partitions('metrics', 3);
    $$
);

-- 3. Clean old data weekly (keeps 90 days)
SELECT cron.schedule(
    'clean-old-data',
    '0 2 * * 0',
    $$ SELECT clean_old_analytics_data(90); $$
);

-- View scheduled jobs
SELECT * FROM cron.job;

-- Remove a job (if needed)
SELECT cron.unschedule('refresh-analytics-views');
```

---

## 🔍 Common Queries

### Dashboard Analytics (Use Materialized Views)

```sql
-- Daily event summary (fast!)
SELECT * FROM daily_analytics_summary
WHERE date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY date DESC, event_count DESC;

-- User activity summary (fast!)
SELECT * FROM user_activity_summary
WHERE last_activity >= NOW() - INTERVAL '30 days'
ORDER BY total_events DESC
LIMIT 100;

-- Admin dashboard (instant)
SELECT * FROM admin_dashboard;
```

### Event Analytics

```sql
-- Events by user (last 7 days)
SELECT event_name, COUNT(*), MIN(timestamp), MAX(timestamp)
FROM analytics_events
WHERE user_id = 'user123'
  AND timestamp >= NOW() - INTERVAL '7 days'
GROUP BY event_name
ORDER BY COUNT(*) DESC;

-- Search by JSON parameter (fast with GIN index)
SELECT * FROM analytics_events
WHERE parameters @> '{"screen": "home"}'
  AND timestamp >= NOW() - INTERVAL '7 days'
ORDER BY timestamp DESC
LIMIT 100;

-- Events by session
SELECT session_id, event_name, timestamp, parameters
FROM analytics_events
WHERE session_id = 'session-abc-123'
ORDER BY timestamp;
```

### Metric Analysis

```sql
-- Metric statistics (with percentiles)
SELECT * FROM calculate_metric_stats(
    'app_load_time',
    NOW() - INTERVAL '7 days',
    NOW()
);

-- Metric trends over time
SELECT
    DATE(timestamp) as date,
    AVG(value) as avg_value,
    MIN(value) as min_value,
    MAX(value) as max_value,
    COUNT(*) as sample_count
FROM metrics
WHERE metric_name = 'app_load_time'
  AND timestamp >= NOW() - INTERVAL '30 days'
GROUP BY DATE(timestamp)
ORDER BY date DESC;

-- Top users by metric
SELECT
    user_id,
    COUNT(*) as measurement_count,
    AVG(value) as avg_value,
    MAX(value) as max_value
FROM metrics
WHERE metric_name = 'session_duration'
  AND timestamp >= NOW() - INTERVAL '7 days'
GROUP BY user_id
ORDER BY avg_value DESC
LIMIT 20;
```

### User Analytics

```sql
-- User summary (comprehensive)
SELECT get_user_analytics_summary('user123');

-- User locations (recent)
SELECT *
FROM user_locations
WHERE user_id = 'uuid-here'
  AND timestamp >= NOW() - INTERVAL '24 hours'
ORDER BY timestamp DESC;

-- User properties
SELECT property_name, property_value, updated_at
FROM user_properties
WHERE user_id = 'uuid-here';
```

---

## 🛠️ Manual Maintenance

### Refresh Materialized Views (if data looks stale)

```sql
-- Refresh without blocking reads
REFRESH MATERIALIZED VIEW CONCURRENTLY daily_analytics_summary;
REFRESH MATERIALIZED VIEW CONCURRENTLY user_activity_summary;

-- Or use helper function
SELECT refresh_analytics_views();
```

### Create Missing Partitions

```sql
-- Create partitions for next 3 months
SELECT create_monthly_partitions('analytics_events', 3);
SELECT create_monthly_partitions('metrics', 3);

-- Verify partitions
SELECT
    parent.relname as parent_table,
    child.relname as partition_name
FROM pg_inherits
JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
JOIN pg_class child ON pg_inherits.inhrelid = child.oid
WHERE parent.relname IN ('analytics_events', 'metrics')
ORDER BY parent.relname, child.relname;
```

### Clean Old Data

```sql
-- Clean data older than 90 days (default)
SELECT clean_old_analytics_data(90);

-- Custom retention (60 days)
SELECT clean_old_analytics_data(60);

-- Returns JSON with deletion counts
-- Example result:
-- {
--   "deleted_events": 150000,
--   "deleted_metrics": 75000,
--   "deleted_locations": 50000,
--   "retention_days": 90,
--   "cleaned_at": "2025-01-15T10:30:00Z"
-- }
```

### Drop Old Partitions (Manual Archive)

```sql
-- List all partitions
SELECT tablename FROM pg_tables
WHERE tablename LIKE 'analytics_events_%'
   OR tablename LIKE 'metrics_%'
ORDER BY tablename;

-- Drop old partition (data deleted!)
DROP TABLE IF EXISTS analytics_events_2024_06;
DROP TABLE IF EXISTS metrics_2024_06;

-- Or export first, then drop
-- 1. Export: pg_dump -t analytics_events_2024_06 > archive_2024_06.sql
-- 2. Drop: DROP TABLE analytics_events_2024_06;
```

### Update Statistics (if queries slow after big changes)

```sql
-- Analyze specific tables
ANALYZE analytics_events;
ANALYZE metrics;
ANALYZE user_locations;

-- Or all tables
ANALYZE;
```

---

## 📊 Performance Monitoring

### Check Database Size

```sql
-- Total database size
SELECT pg_size_pretty(pg_database_size(current_database()));

-- Size by table
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS index_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Check Index Usage

```sql
-- Find unused indexes (candidates for removal)
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    pg_size_pretty(pg_relation_size(schemaname||'.'||indexname)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
  AND idx_scan < 100  -- Used less than 100 times
ORDER BY pg_relation_size(schemaname||'.'||indexname) DESC;

-- Index hit ratio (should be >95%)
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    CASE
        WHEN idx_tup_read = 0 THEN 0
        ELSE round((idx_tup_fetch::numeric / idx_tup_read * 100), 2)
    END AS hit_ratio
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
  AND idx_scan > 0
ORDER BY idx_scan DESC;
```

### Check Cache Hit Ratio

```sql
-- Table cache hit ratio (should be >99%)
SELECT
    schemaname,
    tablename,
    heap_blks_hit,
    heap_blks_read,
    CASE
        WHEN (heap_blks_hit + heap_blks_read) = 0 THEN 0
        ELSE round((heap_blks_hit::numeric / (heap_blks_hit + heap_blks_read) * 100), 2)
    END AS cache_hit_ratio
FROM pg_statio_user_tables
WHERE schemaname = 'public'
  AND (heap_blks_hit + heap_blks_read) > 0
ORDER BY cache_hit_ratio ASC;

-- Overall cache hit ratio
SELECT
    sum(heap_blks_read) as heap_read,
    sum(heap_blks_hit) as heap_hit,
    sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) * 100 as cache_hit_ratio
FROM pg_statio_user_tables;
```

### Find Slow Queries

```sql
-- Requires pg_stat_statements extension
-- Enable in Supabase: Database > Extensions > pg_stat_statements

SELECT
    LEFT(query, 100) as query_snippet,
    calls,
    ROUND(total_exec_time::numeric, 2) as total_time_ms,
    ROUND(mean_exec_time::numeric, 2) as avg_time_ms,
    ROUND(max_exec_time::numeric, 2) as max_time_ms
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY mean_exec_time DESC
LIMIT 20;

-- Reset statistics
SELECT pg_stat_statements_reset();
```

### Check Table Bloat

```sql
-- Estimate table bloat
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    n_tup_ins AS inserts,
    n_tup_upd AS updates,
    n_tup_del AS deletes,
    n_live_tup AS live_rows,
    n_dead_tup AS dead_rows,
    CASE
        WHEN n_live_tup = 0 THEN 0
        ELSE round((n_dead_tup::numeric / n_live_tup * 100), 2)
    END AS bloat_ratio
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_dead_tup DESC;

-- If bloat_ratio > 20%, run VACUUM
VACUUM ANALYZE analytics_events;
```

---

## 🔧 Troubleshooting

### "No partition found" Error

```sql
-- Create missing partitions
SELECT create_monthly_partitions('analytics_events', 6);
SELECT create_monthly_partitions('metrics', 6);
```

### Materialized Views Show Old Data

```sql
-- Force refresh
REFRESH MATERIALIZED VIEW CONCURRENTLY daily_analytics_summary;
REFRESH MATERIALIZED VIEW CONCURRENTLY user_activity_summary;

-- Check last refresh time
SELECT
    schemaname,
    matviewname,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||matviewname)) AS size
FROM pg_matviews
WHERE schemaname = 'public';
```

### Queries Suddenly Slow

```sql
-- 1. Update statistics
ANALYZE analytics_events;
ANALYZE metrics;

-- 2. Check for bloat (see above)

-- 3. Verify indexes are being used
EXPLAIN ANALYZE
SELECT * FROM analytics_events
WHERE event_name = 'page_view'
  AND timestamp >= NOW() - INTERVAL '7 days';
-- Look for "Index Scan" or "Index Only Scan"
-- Avoid "Seq Scan" on large tables
```

### High Storage Usage

```sql
-- 1. Check table sizes (see above)

-- 2. Clean old data
SELECT clean_old_analytics_data(60); -- Keep 60 days instead of 90

-- 3. Drop old partitions
DROP TABLE IF EXISTS analytics_events_2024_01;

-- 4. Vacuum to reclaim space
VACUUM FULL analytics_events; -- Locks table!
-- Or better:
VACUUM analytics_events; -- No lock, less space reclaimed
```

---

## 📝 Best Practices

### Inserting Data

```sql
-- ✅ Good: Batch inserts
INSERT INTO analytics_events (event_name, user_id, timestamp, parameters)
VALUES
    ('page_view', 'user1', NOW(), '{"page": "home"}'),
    ('page_view', 'user2', NOW(), '{"page": "about"}'),
    ('click', 'user1', NOW(), '{"button": "signup"}');

-- ❌ Bad: Individual inserts in loop
-- INSERT INTO analytics_events ... (1000 times)
```

### Querying Data

```sql
-- ✅ Good: Always filter by timestamp (partition key)
SELECT * FROM analytics_events
WHERE timestamp >= NOW() - INTERVAL '7 days'
  AND event_name = 'page_view';

-- ❌ Bad: No timestamp filter (scans all partitions)
SELECT * FROM analytics_events
WHERE event_name = 'page_view';

-- ✅ Good: Use materialized views for aggregations
SELECT * FROM daily_analytics_summary
WHERE date >= CURRENT_DATE - 7;

-- ❌ Bad: Aggregate on raw table every time
SELECT DATE(timestamp), COUNT(*)
FROM analytics_events
GROUP BY DATE(timestamp);

-- ✅ Good: Limit results
SELECT * FROM analytics_events
WHERE user_id = 'user123'
ORDER BY timestamp DESC
LIMIT 100;

-- ❌ Bad: Fetch all (potentially millions)
SELECT * FROM analytics_events
WHERE user_id = 'user123';
```

### JSON Queries

```sql
-- ✅ Good: Use @> operator (uses GIN index)
SELECT * FROM analytics_events
WHERE parameters @> '{"screen": "home"}';

-- ❌ Bad: Use ->/->> (can't use GIN index efficiently)
SELECT * FROM analytics_events
WHERE parameters->>'screen' = 'home';

-- ✅ Good: Existence check (uses GIN index)
SELECT * FROM analytics_events
WHERE parameters ? 'user_action';

-- Multiple keys (uses GIN index)
SELECT * FROM analytics_events
WHERE parameters ?& array['screen', 'action'];
```

---

## 📱 Application Integration

### Connection String

```bash
# Use transaction pooler for serverless/API
DATABASE_URL="postgres://user:pass@host:6543/postgres?pgbouncer=true"

# Use session pooler for background jobs
DATABASE_URL="postgres://user:pass@host:5432/postgres"
```

### Batch Insert Example (JavaScript)

```javascript
// ✅ Good: Batch insert
const events = [
  { event_name: 'page_view', user_id: 'user1', parameters: { page: 'home' } },
  { event_name: 'click', user_id: 'user1', parameters: { button: 'signup' } },
  // ... more events
];

const { error } = await supabase
  .from('analytics_events')
  .insert(events);

// ❌ Bad: Loop with individual inserts
for (const event of events) {
  await supabase.from('analytics_events').insert(event);
}
```

### Query with Filters (JavaScript)

```javascript
// ✅ Good: Filter by partition key
const { data, error } = await supabase
  .from('analytics_events')
  .select('*')
  .eq('event_name', 'page_view')
  .gte('timestamp', new Date(Date.now() - 7*24*60*60*1000).toISOString())
  .limit(100);

// Use materialized views for dashboards
const { data: summary } = await supabase
  .from('daily_analytics_summary')
  .select('*')
  .gte('date', '2025-01-01')
  .order('date', { ascending: false });
```

---

## 🎯 Quick Wins Checklist

- ✅ Run optimized_supabase_setup.sql
- ✅ Set up 3 cron jobs (refresh views, create partitions, clean data)
- ✅ Use materialized views for dashboards
- ✅ Always filter by timestamp in queries
- ✅ Use batch inserts, not loops
- ✅ Enable pg_stat_statements for monitoring
- ✅ Check cache hit ratio monthly (should be >99%)
- ✅ Review and drop unused indexes quarterly
- ✅ Monitor table sizes and bloat

---

## 📚 Resources

- **Full Documentation**: `database/PERFORMANCE_OPTIMIZATIONS.md`
- **Comparison**: `database/OPTIMIZATION_SUMMARY.md`
- **SQL File**: `database/optimized_supabase_setup.sql`

---

## ⚡ Emergency Performance Fix

If your database is slow right now:

```sql
-- 1. Update statistics (30 seconds)
ANALYZE;

-- 2. Refresh materialized views (1-2 minutes)
SELECT refresh_analytics_views();

-- 3. Check for bloat (see above)
-- If dead_rows > 20%, run:
VACUUM ANALYZE analytics_events;
VACUUM ANALYZE metrics;

-- 4. Create missing partitions (if inserting fails)
SELECT create_monthly_partitions('analytics_events', 3);
SELECT create_monthly_partitions('metrics', 3);

-- 5. Check cache hit ratio
-- If < 95%, you may need to upgrade Supabase plan
```

**Still slow?** Check `PERFORMANCE_OPTIMIZATIONS.md` or contact support with:
- Slow query from pg_stat_statements
- Table sizes
- Cache hit ratio
- Supabase plan tier
