DROP PROCEDURE IF EXISTS sp_refresh_dvd_report;
CREATE OR REPLACE PROCEDURE sp_refresh_dvd_report()
LANGUAGE plpgsql
AS $$
BEGIN
  TRUNCATE TABLE report_category_monthly RESTART IDENTITY;
  TRUNCATE TABLE report_rental_detail RESTART IDENTITY;
  INSERT INTO report_rental_detail (
      report_month, store_id, store_name,
      rental_id, payment_id, customer_id, customer_name,
      film_id, film_title, category_id, category_name,
      rental_date, return_date, due_date, days_rented, on_time_flag,
      payment_amount
  )
  SELECT
      date_trunc('month', p.payment_date)::date,
      s.store_id,
      ('Store ' || s.store_id)::varchar(100),
      r.rental_id,
      p.payment_id,
      c.customer_id,
      (c.first_name || ' ' || c.last_name),
      f.film_id,
      f.title,
      cat.category_id,
      cat.name,
      r.rental_date,
      r.return_date,
      r.rental_date + (f.rental_duration || ' days')::interval,
      CASE WHEN r.return_date IS NOT NULL THEN (r.return_date::date - r.rental_date::date) ELSE NULL END,
      udf_on_time_flag(r.rental_date, r.return_date, f.rental_duration),
      p.amount::numeric(10,2)
  FROM payment p
  JOIN rental r ON p.rental_id = r.rental_id
  JOIN customer c ON r.customer_id = c.customer_id
  JOIN inventory i ON r.inventory_id = i.inventory_id
  JOIN store s ON i.store_id = s.store_id
  JOIN film f ON i.film_id = f.film_id
  JOIN film_category fc ON f.film_id = fc.film_id
  JOIN category cat ON fc.category_id = cat.category_id;
END;
$$;
-- One-time build (run after creating):
-- CALL sp_refresh_dvd_report();

