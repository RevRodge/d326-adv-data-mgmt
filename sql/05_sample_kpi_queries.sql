-- ================================================================
-- D326 – DVD Rental KPI Report
-- 05_sample_kpi_queries.sql
--
-- All queries pull from: report_category_monthly
-- ================================================================

-- Top categories by revenue per store/month
SELECT
    report_month,
    store_id,
    store_name,
    category_name,
    rentals_count,
    total_revenue,
    ROUND(total_days_rented::numeric / NULLIF(rentals_count, 0), 2) AS avg_days_rented,
    ROUND(late_rentals::numeric / NULLIF(rentals_count, 0), 4) AS late_rate
FROM report_category_monthly
ORDER BY report_month DESC, total_revenue DESC
LIMIT 50;

-- Late return rate trend by store (month over month)
SELECT
    report_month,
    store_id,
    store_name,
    ROUND(100.0 * late_rentals::numeric / NULLIF(rentals_count, 0), 2) AS late_rate_pct
FROM report_category_monthly
ORDER BY store_id, report_month;
-- Category revenue share per store/month
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

/* Raw data extraction for the detailed report section */
SELECT
    date_trunc('month', p.payment_date)::date AS report_month,
    s.store_id AS store_id,
    ('Store ' || s.store_id)::varchar(100) AS store_name,
    r.rental_id AS rental_id,
    p.payment_id AS payment_id,
    c.customer_id AS customer_id,
    (c.first_name || ' ' || c.last_name) AS customer_name,
    f.film_id AS film_id,
    f.title AS film_title,
    cat.category_id AS category_id,
    cat.name AS category_name,
    r.rental_date AS rental_date,
    r.return_date AS return_date,
    r.rental_date + (f.rental_duration || ' days')::interval AS due_date,
    CASE
      WHEN r.return_date IS NOT NULL
        THEN (r.return_date::date - r.rental_date::date)
      ELSE f.rental_duration
    END AS days_rented
    udf_on_time_flag(r.rental_date, r.return_date, f.rental_duration) AS on_time_flag,
    p.amount::numeric(10,2) AS payment_amount
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN customer c ON r.customer_id = c.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN store s ON i.store_id = s.store_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category cat ON fc.category_id = cat.category_id;
