DROP TABLE IF EXISTS report_rental_detail;
CREATE TABLE report_rental_detail (
    detail_id bigserial PRIMARY KEY,
    report_month date NOT NULL,
    store_id integer NOT NULL,
    store_name varchar(100) NOT NULL,
    rental_id integer NOT NULL,
    payment_id integer NOT NULL,
    customer_id integer NOT NULL,
    customer_name varchar(150) NOT NULL,
    film_id integer NOT NULL,
    film_title varchar(255) NOT NULL,
    category_id integer NOT NULL,
    category_name varchar(50) NOT NULL,
    rental_date timestamp NOT NULL,
    return_date timestamp NULL,
    due_date timestamp NOT NULL,
    days_rented integer NULL,
    on_time_flag char(1) NULL,
    payment_amount numeric(10,2) NOT NULL
);
CREATE INDEX idx_detail_month_store_cat
  ON report_rental_detail (report_month, store_id, category_id);
CREATE INDEX idx_detail_payment ON report_rental_detail (payment_id);
CREATE INDEX idx_detail_rental ON report_rental_detail (rental_id);

DROP TABLE IF EXISTS report_category_monthly;
CREATE TABLE report_category_monthly (
    report_month date    NOT NULL,
    store_id integer NOT NULL,
    category_id integer NOT NULL,
    store_name varchar(100) NOT NULL,
    category_name varchar(50)  NOT NULL,
    rentals_count integer NOT NULL DEFAULT 0,
    total_revenue numeric(12,2) NOT NULL DEFAULT 0.00,
    total_days_rented integer NOT NULL DEFAULT 0,
    late_rentals integer NOT NULL DEFAULT 0,

    CONSTRAINT pk_report_category_monthly PRIMARY KEY (report_month, store_id, category_id)
);