-- Coffee Counsumers Count
-- Number of people in each city estimated to consume coffee given that 25% of the population does

SELECT 
	city_name,
    ROUND(
    (population*0.25)/1000000,
    2) AS coffee_consumers_in_millions,
    city_rank
FROM city
ORDER BY 2 DESC;

-- Total Revenue From Coffee Sales
-- Total revenue generataed from coffee sales across all cities in the last quarter of 2023

SELECT 
	SUM(total) AS total_revenue
FROM sales
WHERE 
	YEAR(sale_date)=2023
    AND
    QUARTER(sale_date)=4;

-- Total Revenue From Coffee Sales
-- Total revenue generataed from coffee sales across different cities in the last quarter of 2023 

SELECT 
	ci.city_name,
	SUM(s.total) AS total_revenue
FROM sales AS s
JOIN customers AS c
ON s.customer_id = c.customer_id
JOIN city AS ci
ON ci.city_id = c.city_id
WHERE 
	YEAR(s.sale_date)  = 2023
	AND
	QUARTER(s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC;

-- Sales Count for Each Product
-- Units of each coffee product sold

SELECT 
	p.product_name,
	COUNT(s.sale_id) AS total_orders
FROM products AS p
LEFT JOIN
sales AS s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC;

-- Average Sales Amount per City
-- The average sales amount per customer in each city

SELECT 
	ci.city_name,
	SUM(s.total) AS total_revenue,
	COUNT(DISTINCT s.customer_id) AS total_cx,
	ROUND(
			SUM(s.total)/
				COUNT(DISTINCT s.customer_id)
			,2) AS avg_sale_pr_cx	
FROM sales AS s
JOIN customers AS c
ON s.customer_id = c.customer_id
JOIN city AS ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;

-- City Population and Coffee Consumers (25%)
-- List of cities along with their populations and estimated coffee consumers.

WITH city_table AS 
(
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) AS coffee_consumers
	FROM city
),
customers_table
AS
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) AS unique_cx
	FROM sales AS s
	JOIN customers AS c
	ON c.customer_id = s.customer_id
	JOIN city AS ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.coffee_consumers AS coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name;

-- Top Selling Products by City
-- The top 3 selling products in each city based on sales volume

SELECT * 
FROM -- table
(
	SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) AS total_orders,
		DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) AS rank_of_city
	FROM sales AS s
	JOIN products AS p
	ON s.product_id = p.product_id
	JOIN customers AS c
	ON c.customer_id = s.customer_id
	JOIN city AS ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2
) AS t1
WHERE rank_of_city <= 3;

-- Customer Segmentation by City
-- Unique customers in each city who have purchased coffee products

SELECT * FROM products;

SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) AS unique_cx
FROM city AS ci
LEFT JOIN
customers AS c
ON c.city_id = ci.city_id
JOIN sales AS s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1;

-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

WITH city_table 
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) AS total_revenue,
		COUNT(DISTINCT s.customer_id) AS total_cx,
		ROUND(
				SUM(s.total)/
					COUNT(DISTINCT s.customer_id)
				,2) AS avg_sale_pr_cx
		
	FROM sales AS s
	JOIN customers AS c
	ON s.customer_id = c.customer_id
	JOIN city AS ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(SELECT 
	city_name, 
	estimated_rent
FROM city
)
SELECT 
	cr.city_name,
	cr.estimated_rent,
	ct.total_cx,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent/
		ct.total_cx
		, 2) AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC;

-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		MONTH(sale_date) AS month,
		YEAR(sale_date) AS YEAR,
		SUM(s.total) AS total_sale
	FROM sales AS s
	JOIN customers AS c
	ON c.customer_id = s.customer_id
	JOIN city AS ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale AS cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) AS last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)/last_month_sale * 100
		, 2
		) AS growth_ratio

FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL	;
    
-- Market Potential Analysis
-- Top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer



WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) AS total_revenue,
		COUNT(DISTINCT s.customer_id) AS total_cx,
		ROUND(
				SUM(s.total)/
					COUNT(DISTINCT s.customer_id)
				,2) as avg_sale_pr_cx
		
	FROM sales AS s
	JOIN customers AS c
	ON s.customer_id = c.customer_id
	JOIN city AS ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) AS estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent AS total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent/ct.total_cx
		, 2) AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC;