-- ================================================================
-- D326 – DVD Rental KPI Report
-- 04_procedure_refresh.sql
--
-- Purpose:
--   rebuilds both report tables by:
--     TRUNCATE detail & summary
--     INSERT detail from source schema
--     INSERT summary aggregated from detail
--
-- Usage:
--   CALL sp_refresh_dvd_report();
-- ================================================================

DROP PROCEDURE IF EXISTS sp_refresh_dvd_report;

CREATE OR REPLACE PROCEDURE sp_refresh_dvd_report()
LANGUAGE plpgsql
AS $$
BEGIN
  -- 1) Clear existing data (idempotent rebuild)
  TRUNCATE TABLE report_category_monthly RESTART IDENTITY;
  TRUNCATE TABLE report_rental_detail    RESTART IDENTITY;

  -- 2) Load detail from source schema
  INSERT INTO report_rental_detail (
      report_month, store_id, store_name,
      rental_id, payment_id, customer_id, customer_name,
      film_id, film_title, category_id, category_name,
      rental_date, return_date, due_date, days_rented, on_time_flag,
      payment_amount
  )
  SELECT
      date_trunc('month', p.payment_date)::date                                    AS report_month,
      s.store_id                                                                    AS store_id,
      ('Store ' || s.store_id)::varchar(100)                                        AS store_name,
      r.rental_id                                                                   AS rental_id,
      p.payment_id                                                                   AS payment_id,
      c.customer_id                                                                  AS customer_id,
      (c.first_name || ' ' || c.last_name)                                          AS customer_name,
      f.film_id                                                                      AS film_id,
      f.title                                                                        AS film_title,
      cat.category_id                                                                AS category_id,
      cat.name                                                                       AS category_name,
      r.rental_date                                                                  AS rental_date,
      r.return_date                                                                  AS return_date,
      r.rental_date + (f.rental_duration || ' days')::interval                       AS due_date,
      CASE WHEN r.return_date IS NOT NULL
           THEN (r.return_date::date - r.rental_date::date)
           ELSE NULL
      END                                                                            AS days_rented,
      udf_on_time_flag(r.rental_date, r.return_date, f.rental_duration)             AS on_time_flag,
      p.amount::numeric(10,2)                                                        AS payment_amount
  FROM payment p
  JOIN rental r          ON p.rental_id   = r.rental_id
  JOIN customer c        ON r.customer_id = c.customer_id
  JOIN inventory i       ON r.inventory_id = i.inventory_id
  JOIN store s           ON i.store_id    = s.store_id
  JOIN film f            ON i.film_id     = f.film_id
  JOIN film_category fc  ON f.film_id     = fc.film_id
  JOIN category cat      ON fc.category_id = cat.category_id;

  -- 3) Rebuild summary from detail (no trigger reliance)
  INSERT INTO report_category_monthly (
      report_month, store_id, category_id, store_name, category_name,
      rentals_count, total_revenue, total_days_rented, late_rentals
  )
  SELECT
      d.report_month,
      d.store_id,
      d.category_id,
      MAX(d.store_name)                               AS store_name,
      MAX(d.category_name)                            AS category_name,
      COUNT(*)                                        AS rentals_count,
      SUM(d.payment_amount)                           AS total_revenue,
      SUM(COALESCE(d.days_rented, 0))                 AS total_days_rented,
      SUM(CASE WHEN d.on_time_flag = 'N' THEN 1 ELSE 0 END) AS late_rentals
  FROM report_rental_detail d
  GROUP BY d.report_month, d.store_id, d.category_id;
END;
$$;

-- One-time build (run after creating this procedure):
-- CALL sp_refresh_dvd_report();

