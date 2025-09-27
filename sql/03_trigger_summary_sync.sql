-- ================================================================
-- D326 – DVD Rental KPI Report
-- 03_trigger_summary_sync.sql
--
-- Purpose:
--   Keep report_category_monthly in sync whenever new detail rows
--   are inserted into report_rental_detail
-- ================================================================

-- trigger function: roll up the inserted detail row
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
  -- handles existing pk combinations by udating data in those rows
  ON CONFLICT (report_month, store_id, category_id) DO UPDATE
  --this is the row we're adding
  SET rentals_count     = report_category_monthly.rentals_count + 1, 
      --captures data not inserted to use for update
      total_revenue     = report_category_monthly.total_revenue + EXCLUDED.total_revenue,
      total_days_rented = report_category_monthly.total_days_rented + EXCLUDED.total_days_rented,
      late_rentals      = report_category_monthly.late_rentals + EXCLUDED.late_rentals;

  RETURN NULL; -- AFTER trigger; no row modification needed
END;
$$;

-- binds AFTER INSERT trigger to the detail table
CREATE TRIGGER trg_detail_after_insert
AFTER INSERT ON report_rental_detail
FOR EACH ROW
EXECUTE FUNCTION trg_detail_after_insert();