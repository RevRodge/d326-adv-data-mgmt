-- ================================================================
-- D326 – DVD Rental KPI Report
-- 05_sample_kpi_queries.sql
--
-- Purpose:
--   Sample queries for exploring KPIs from the summary table:
--     - Monthly revenue by store and category
--     - Average rental duration
--     - Late return rate
--     - Category revenue share
--
-- All queries pull from: report_category_monthly
-- ================================================================

-- A) Top categories by revenue per store/month
SELECT
  report_month,
  store_id,
  store_name,
  category_name,
  rentals_count,
  total_revenue,
  ROUND(total_days_rented::numeric / NULLIF(rentals_count, 0), 2) AS avg_days_rented,
  ROUND(late_rentals::numeric / NULLIF(rentals_count, 0), 4)      AS late_rate
FROM report_category_monthly
ORDER BY report_month DESC, total_revenue DESC
LIMIT 50;

-- B) Late return rate trend by store (month over month)
SELECT
  report_month,
  store_id,
  store_name,
  ROUND(100.0 * late_rentals::numeric / NULLIF(rentals_count, 0), 2) AS late_rate_pct
FROM report_category_monthly
ORDER BY store_id, report_month;

-- C) Category revenue share per store/month
SELECT
  report_month,
  store_id,
  store_name,
  category_name,
  ROUND(
    100.0 * total_revenue::numeric
    / NULLIF(SUM(total_revenue) OVER (PARTITION BY report_month, store_id), 0),
    2
  ) AS revenue_share_pct
FROM report_category_monthly
ORDER BY report_month DESC, store_id, revenue_share_pct DESC;

