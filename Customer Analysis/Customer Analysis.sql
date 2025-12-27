Select *
FROM
    sales_data_cleaned;

SELECT *
FROM product_info;

SELECT *
FROM customer_info_cleaned;


ALTER TABLE HUSO.dbo.sales_data_cleaned
ADD total_sales_amount DECIMAL(10,2);

UPDATE HUSO.dbo.sales_data_cleaned
SET total_sales_amount = (quantity * unit_price) * (1 - COALESCE(discount_applied, 0));
Select order_id, SUM(total_sales_amount) AS total_sales_amount
FROM
    sales_data_cleaned
GROUP BY order_id;

-- Calculate total spending per customer -- 
SELECT
    sales_data_cleaned.customer_id,
    ROUND(AVG(COALESCE(discount_applied, 0)), 5) AS avg_discount,
    SUM(total_sales_amount) AS total_spent
FROM
    sales_data_cleaned
    JOIN customer_info_cleaned ON sales_data_cleaned.customer_id = customer_info_cleaned.customer_id
GROUP BY sales_data_cleaned.customer_id
ORDER BY avg_discount DESC;


-- Calculate total spending per loyalty tier -- 
SELECT
    customer_info_cleaned.loyalty_tier,
    ROUND(AVG(COALESCE(discount_applied, 0)), 5) AS avg_discount,
    SUM(total_sales_amount) AS total_spent
FROM
    sales_data_cleaned
    JOIN customer_info_cleaned ON sales_data_cleaned.customer_id = customer_info_cleaned.customer_id
GROUP BY customer_info_cleaned.loyalty_tier
ORDER BY total_spent DESC;

--Calculate total spending per region --
SELECT
    customer_info_cleaned.region,
    SUM(total_sales_amount) AS total_spent
FROM
    sales_data_cleaned
    JOIN customer_info_cleaned ON sales_data_cleaned.customer_id = customer_info_cleaned.customer_id
GROUP BY customer_info_cleaned.region
ORDER BY total_spent DESC;

-- Calculate total spending per product category --
SELECT
    product_info.category,
    SUM(total_sales_amount) AS total_spent
FROM
    sales_data_cleaned
    JOIN product_info ON sales_data_cleaned.product_id = product_info.product_id
GROUP BY product_info.category
ORDER BY total_spent DESC;

-- Calculate total spending per month --
SELECT
    DATEPART(MONTH, sales_data_cleaned.order_date) AS order_month,
    SUM(total_sales_amount) AS total_spent
FROM
    sales_data_cleaned
GROUP BY DATEPART(MONTH, sales_data_cleaned.order_date)
ORDER BY order_month;

-- Calculate total spending per year --
SELECT
    DATEPART(YEAR, sales_data_cleaned.order_date) AS order_year,
    SUM(total_sales_amount) AS total_spent
FROM
    sales_data_cleaned
GROUP BY DATEPART(YEAR, sales_data_cleaned.order_date)
ORDER BY order_year;

-- Calculate total spending per payment method --
SELECT
    sales_data_cleaned.payment_method,
    SUM(total_sales_amount) AS total_spent
FROM
    sales_data_cleaned
GROUP BY sales_data_cleaned.payment_method
ORDER BY total_spent DESC;

-- Calculating the amount of sales which are delayed deliveries --
SELECT
    delivery_status,
    SUM(total_sales_amount) as total_sales,
    ROUND(SUM(total_sales_amount) * 100.0 / (SELECT SUM(total_sales_amount)
    FROM sales_data_cleaned), 2) as percentage
FROM sales_data_cleaned
GROUP BY delivery_status
ORDER BY percentage DESC;

-- Calculating the actual total sales which either delivered or in the process of delivery --
SELECT
    SUM(total_sales_amount) as total_sales
FROM sales_data_cleaned
WHERE delivery_status IN ('DELIVERED', 'DELAYED');

---Calculating the the total sales amount lost due to cancelled orders --
SELECT
    SUM(total_sales_amount) as total_lost_sales
FROM sales_data_cleaned
WHERE delivery_status = 'CANCELLED';

--Calculating the percentage of sales lost due to cancelled orders --
--- Either the folowing or use the total sales distribution by delivery status ---
SELECT
    ROUND(SUM(CASE WHEN delivery_status = 'CANCELLED' THEN total_sales_amount ELSE 0 END) * 100.0 /
    SUM(total_sales_amount), 2) as percentage_lost
FROM sales_data_cleaned;

---> Calculating the delivery status distribution by region ---
SELECT
    delivery_status,
    region,
    ROUND(SUM(total_sales_amount) * 100.0 / 
        (SELECT SUM(total_sales_amount)
    FROM sales_data_cleaned sd2
    WHERE sd2.delivery_status = sales_data_cleaned.delivery_status), 2) AS percentage
FROM sales_data_cleaned
GROUP BY delivery_status, region
ORDER BY delivery_status, percentage DESC;

--> Fixing the nrth value in the region column of sales data cleaned table <--

--> Identifig the incorrect entries and to check the update 
SELECT *
FROM sales_data_cleaned
WHERE region = 'nrth';

--> Correcting the incorrect entries
UPDATE sales_data_cleaned
SET region = 'North'
WHERE region = 'nrth';

--> Customer Base per Region Analysis <--

SELECT
    region,
    COUNT(customer_id) AS customer_count
FROM
    customer_info_cleaned
GROUP BY region

--> Average Order Value (AOV) per Region Analysis <--

--> Gives average order value per region for the customer in the region where the customer belongs 
SELECT
    ci.region,
    ROUND(AVG(sd.total_sales_amount), 2) AS average_order_value
FROM
    sales_data_cleaned sd
    JOIN customer_info_cleaned ci ON sd.customer_id = ci.customer_id
GROUP BY ci.region
ORDER BY average_order_value DESC;

--> Gives AOV for the sale made in the region where the sale was made
SELECT
    region,
    ROUND(AVG(total_sales_amount), 2) AS average_order_value
FROM sales_data_cleaned
GROUP BY region
ORDER BY average_order_value DESC;
