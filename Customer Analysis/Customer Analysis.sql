Select *
FROM
    HUSO.dbo.sales_data_cleaned;

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