
# Codebasics sql project challange--
-- Ad-hoc Requests Script

-- Request 1: List of markets for "Atliq Exclusive" in the APAC region

SELECT DISTINCT market
FROM dim_customer
WHERE customer = 'Atliq Exclusive' AND region = 'APAC';

-- Request 2: Percentage increase in unique products in 2021 vs. 2020

WITH unique_products AS (
    SELECT 
        fiscal_year, 
        COUNT(DISTINCT Product_code) as unique_products 
    FROM 
        fact_gross_price 
    GROUP BY 
        fiscal_year
)
SELECT 
    up_2020.unique_products as unique_products_2020,
    up_2021.unique_products as unique_products_2021,
    round((up_2021.unique_products - up_2020.unique_products)/up_2020.unique_products * 100,2) as percentage_change
FROM 
    unique_products up_2020
CROSS JOIN 
    unique_products up_2021
WHERE 
    up_2020.fiscal_year = 2020 
    AND up_2021.fiscal_year = 2021;


-- Request 3: Report with unique product counts for each segment


SELECT
  segment,
  COUNT(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- Request 4: Segment with the most increase in unique products in 2021 vs. 2020

WITH temp_table AS (
    SELECT 
        p.segment,
        s.fiscal_year,
        COUNT(DISTINCT s.Product_code) as product_count
    FROM 
        fact_sales_monthly s
        JOIN dim_product p ON s.product_code = p.product_code
    GROUP BY 
        p.segment,
        s.fiscal_year
)
SELECT 
    up_2020.segment,
    up_2020.product_count as product_count_2020,
    up_2021.product_count as product_count_2021,
    up_2021.product_count - up_2020.product_count as difference
FROM 
    temp_table as up_2020
JOIN 
    temp_table as up_2021
ON 
    up_2020.segment = up_2021.segment
    AND up_2020.fiscal_year = 2020 
    AND up_2021.fiscal_year = 2021
ORDER BY 
    difference DESC;

-- Request 5: Products with the highest and lowest manufacturing costs

SELECT m.product_code, concat(product," (",variant,")") AS product, cost_year,manufacturing_cost
FROM fact_manufacturing_cost m
JOIN dim_product p ON m.product_code = p.product_code
WHERE manufacturing_cost= 
(SELECT min(manufacturing_cost) FROM fact_manufacturing_cost)
or 
manufacturing_cost = 
(SELECT max(manufacturing_cost) FROM fact_manufacturing_cost) 
ORDER BY manufacturing_cost DESC;

-- Request 6: Top 5 customers with the highest average pre_invoice_discount_pct in 2021 in the Indian market


SELECT c.customer_code, c.customer, ROUND(AVG(pre_invoice_discount_pct), 4) AS average_discount_percentage
FROM fact_pre_invoice_deductions d
JOIN dim_customer c ON d.customer_code = c.customer_code
WHERE c.market = 'India' AND fiscal_year = 2021
GROUP BY customer_code, customer
ORDER BY average_discount_percentage DESC
LIMIT 5;





-- Request 7: Complete report of gross sales amount for "Atliq Exclusive" for each month

WITH temp_table AS (
    SELECT
        c.customer,
        MONTHNAME(s.date) AS months,
        MONTH(s.date) AS month_number,
        YEAR(s.date) AS year,
        (s.sold_quantity * g.gross_price) AS gross_sales
    FROM
        fact_sales_monthly s
        JOIN fact_gross_price g ON s.product_code = g.product_code
        JOIN dim_customer c ON s.customer_code = c.customer_code
    WHERE
        c.customer = 'Atliq Exclusive'
)
SELECT
    months,
    year,
    CONCAT(ROUND(SUM(gross_sales) / 1000000, 2), 'M') AS gross_sales
FROM
    temp_table
GROUP BY
    year, months, month_number
ORDER BY
    year, month_number;






-- Request 8: Quarter with the maximum total_sold_quantity in 2020
WITH temp_table AS (
  SELECT date,month(date_add(date,interval 4 month)) AS period, fiscal_year,sold_quantity 
FROM fact_sales_monthly
)
SELECT CASE 
   when period/3 <= 1 then "Q1"
   when period/3 <= 2 and period/3 > 1 then "Q2"
   when period/3 <=3 and period/3 > 2 then "Q3"
   when period/3 <=4 and period/3 > 3 then "Q4" END quarter,
 round(sum(sold_quantity)/1000000,2) as total_sold_quanity_in_millions FROM temp_table
WHERE fiscal_year = 2020
GROUP BY quarter
ORDER BY total_sold_quanity_in_millions DESC ;
-- Request 9: Channel contributing the most to gross sales in fiscal year 2021 and its percentage
WITH temp_table AS (
      SELECT c.channel,sum(s.sold_quantity * g.gross_price) AS total_sales
  FROM
  fact_sales_monthly s 
  JOIN fact_gross_price g ON s.product_code = g.product_code
  JOIN dim_customer c ON s.customer_code = c.customer_code
  WHERE s.fiscal_year= 2021
  GROUP BY c.channel
  ORDER BY total_sales DESC
)
SELECT 
  channel,
  round(total_sales/1000000,2) AS gross_sales_in_millions,
  round(total_sales/(sum(total_sales) OVER())*100,2) AS percentage 
FROM temp_table ;

-- Request 10: Top 3 products in each division with the highest total_sold_quantity in fiscal year 2021

WITH temp_table AS (
    SELECT
        division,
        s.product_code,
        p.product AS product,
        sum(sold_quantity) AS total_sold_quantity,
        RANK() OVER (PARTITION BY division ORDER BY sum(sold_quantity) DESC) AS rank_order
    FROM
        fact_sales_monthly s
        JOIN dim_product p ON s.product_code = p.product_code
    WHERE
        fiscal_year = 2021
    GROUP BY
        division, product_code, product
)
SELECT
    division,
    product_code,
    product,
    total_sold_quantity,
    rank_order
FROM
    temp_table
WHERE
    rank_order <= 3;


