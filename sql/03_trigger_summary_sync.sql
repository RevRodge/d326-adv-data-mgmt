DROP TRIGGER IF EXISTS trg_detail_after_insert ON report_rental_detail;
DROP FUNCTION IF EXISTS trg_detail_after_insert();

CREATE OR REPLACE FUNCTION trg_detail_after_insert()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO report_category_monthly (
      report_month, store_id, category_id, store_name, category_name,
      rentals_count, total_revenue, total_days_rented, late_rentals
  )
  VALUES (
      NEW.report_month,
      NEW.store_id,
      NEW.category_id,
      NEW.store_name,
      NEW.category_name,
      1,
      NEW.payment_amount,
      COALESCE(NEW.days_rented, 0),
      CASE WHEN NEW.on_time_flag = 'N' THEN 1 ELSE 0 END
  )
  ON CONFLICT (report_month, store_id, category_id) DO UPDATE
  SET rentals_count = report_category_monthly.rentals_count + 1, 
      total_revenue = report_category_monthly.total_revenue + EXCLUDED.total_revenue,
      total_days_rented = report_category_monthly.total_days_rented + EXCLUDED.total_days_rented,
      late_rentals = report_category_monthly.late_rentals + EXCLUDED.late_rentals;

  RETURN NULL;
END;
$$;

CREATE TRIGGER trg_detail_after_insert
AFTER INSERT ON report_rental_detail
FOR EACH ROW
EXECUTE FUNCTION trg_detail_after_insert();