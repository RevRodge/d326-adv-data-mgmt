# d326-adv-data-mgmt
SQL scripts and report artifacts for WGU D326 Assessment

# D326 – Advanced Data Management (PostgreSQL DVD Report)

**Business Question:**  
What are the key performance indicators (KPIs) for film categories by store and month, including revenue, rental behavior, and on-time return rates?

This project is my WGU D326 performance assessment using the PostgreSQL DVD Rental database.

## Structure

- `sql/01_function_udf_on_time_flag.sql`: Creates UDF to determine on-time returns
- `sql/02_report_tables.sql`: Creates detailed and summary report tables
- `sql/03_trigger_summary_sync.sql`: Trigger to keep summary in sync
- `sql/04_procedure_refresh.sql`: Procedure to rebuild everything
- `sql/05_sample_kpi_queries.sql`: Useful queries to explore KPI trends

## How to Use

1. Run the SQL scripts in order (use pgAdmin or `psql`)
2. Call the stored procedure:
   ```sql
   CALL sp_refresh_dvd_report();
