DROP FUNCTION IF EXISTS udf_on_time_flag(timestamp, timestamp, integer);
CREATE OR REPLACE FUNCTION udf_on_time_flag(
    p_rental_ts timestamp,
    p_return_ts timestamp,
    p_rental_days integer
)
RETURNS char(1)
LANGUAGE plpgsql
AS
$$
DECLARE v_due timestamp;
BEGIN
    -- Null-safety: if any input is NULL, return NULL.
    IF p_rental_ts IS NULL OR p_return_ts IS NULL OR p_rental_days IS NULL THEN
        RETURN NULL;
    END IF;

    -- Finds due date/time by adding p_rental_days to the timestamp.
    v_due := p_rental_ts + (p_rental_days || ' days')::interval;

    IF p_return_ts <= v_due THEN
        RETURN 'Y';
    ELSE
        RETURN 'N';
    END IF;
END;
$$

-- Optional quick sanity checks (run ad-hoc; safe to remove):
-- SELECT udf_on_time_flag('2024-01-01 10:00', '2024-01-03 09:59', 2); -- Y
-- SELECT udf_on_time_flag('2024-01-01 10:00', '2024-01-03 10:01', 2); -- N
-- SELECT udf_on_time_flag(NULL, '2024-01-02', 1);                      -- NULL
