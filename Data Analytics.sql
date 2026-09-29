/*
=============================================================
--Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWarehouseAnalytics' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, this script creates a schema called gold
	
WARNING:
    Running this script will drop the entire 'DataWarehouseAnalytics' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

USE master;
GO

-- Drop and recreate the 'DataWarehouseAnalytics' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouseAnalytics')
BEGIN
    ALTER DATABASE DataWarehouseAnalytics SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouseAnalytics;
END;
GO

-- Create the 'DataWarehouseAnalytics' database
CREATE DATABASE DataWarehouseAnalytics;
GO

USE DataWarehouseAnalytics;
GO

-- Create Schemas

CREATE SCHEMA gold;
GO

CREATE TABLE gold.dim_customers(
	customer_key int,
	customer_id int,
	customer_number nvarchar(50),
	first_name nvarchar(50),
	last_name nvarchar(50),
	country nvarchar(50),
	marital_status nvarchar(50),
	gender nvarchar(50),
	birthdate date,
	create_date date
);
GO

CREATE TABLE gold.dim_products(
	product_key int ,
	product_id int ,
	product_number nvarchar(50) ,
	product_name nvarchar(50) ,
	category_id nvarchar(50) ,
	category nvarchar(50) ,
	subcategory nvarchar(50) ,
	maintenance nvarchar(50) ,
	cost int,
	product_line nvarchar(50),
	start_date date 
);
GO

CREATE TABLE gold.fact_sales(
	order_number nvarchar(50),
	product_key int,
	customer_key int,
	order_date date,
	shipping_date date,
	due_date date,
	sales_amount int,
	quantity tinyint,
	price int 
);
GO

TRUNCATE TABLE gold.dim_customers;
GO

BULK INSERT gold.dim_customers
FROM 'C:\Users\Ayush_PC\Documents\DATA ANALKYTICS PROJECT MATERIAL\dim_customers.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.dim_products;
GO

BULK INSERT gold.dim_products
FROM 'C:\Users\Ayush_PC\Documents\DATA ANALKYTICS PROJECT MATERIAL\dim_products.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.fact_sales;
GO

BULK INSERT gold.fact_sales
FROM 'C:\Users\Ayush_PC\Documents\DATA ANALKYTICS PROJECT MATERIAL\fact_sales.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

============================
-- Database Exploration
============================
-- Explore all  objects in database

SELECT * FROM INFORMATION_SCHEMA.TABLES;


-- Explore all columns in database

SELECT * FROM INFORMATION_SCHEMA.COLUMNS;

============================
-- Dimension Exploration
============================

-- Explore all country over customers come from?

SELECT DISTINCT country FROM gold.dim_customers;

-- Explore all products categories "The Major Division"

SELECT DISTINCT category,subcategory,product_name FROM gold.dim_products
ORDER BY 1,2,3;

==============================
-- Date exploration
==============================
-- Identify the earliest and latest dates 

SELECT 
MIN(order_date) as first_order_date,
MAX(order_date) as last_order_date
FROM gold.fact_sales ;

-- How many years of sales are avaialble
SELECT 
MIN(order_date) as first_order_date,
MAX(order_date) as last_order_date,
DATEDIFF(YEAR,MIN(order_date),MAX(order_date)) as order_range
FROM gold.fact_sales ;

-- Find youngest and oldest customers
select 
MIN(Birthdate) as oldest_customer,
MAX(Birthdate) as youngest_customer,
DATEDIFF(YEAR,MIN(Birthdate),getdate()) as oldest_customer_age,
DATEDIFF(YEAR,MAX(birthdate),getdate()) as youngest_customer_age
FROM gold.dim_customers ;

=============================
-- Measure Exploration
=============================

-- Find total sales
SELECT
SUM(sales_amount) as total_sales
FROM gold.fact_sales ;

-- Show how many items are sold
SELECT 
SUM(quantity) as total_quantity
FROM gold.fact_sales ;

-- Find average selling price
SELECT
AVG(price) as avg_price
FROM gold.fact_sales ;

-- Find total number of orders
SELECT
COUNT( DISTINCT  order_number) as total_orders
FROM gold.fact_sales ;

-- Find total number of products
SELECT
COUNT(product_key) as total_products
FROM gold.fact_sales ;

-- Find total number of customers
SELECT  
COUNT(Customer_key) as total_customers
FROM gold.fact_sales ;

-- Find total number of customers that has placed an order
SELECT  
COUNT( DISTINCT Customer_key) as total_customers
FROM gold.fact_sales ;

-- Genrate report that shows all metric key of business
SELECT
'Total_Sales' as measure_name,
SUM(sales_amount) as measure_value
FROM gold.fact_sales
UNION ALL
SELECT
'Total Quantity' as measure_name,
SUM(Quantity) as measure_value
FROM gold.fact_sales
UNION ALL
SELECT
'Average Price' as meausre_name,
SUM(sales_amount) as measure_value
FROM gold.fact_sales
UNION ALL
SELECT
'Total Orders' as meausre_name,
COUNT( DISTINCT  order_number) as measure_value
FROM gold.fact_sales 
UNION ALL
SELECT
'Total Products' as measure_name,
COUNT(product_key) as measure_name
FROM gold.fact_sales 
UNION ALL
SELECT
'Total Customers' as measure_name,
COUNT(Customer_key) as measure_value
FROM gold.fact_sales
UNION ALL
SELECT
'Active Customers' as meauare_value,
COUNT( DISTINCT Customer_key) as total_customers
FROM gold.fact_sales
;

=======================================
-- Magnitude Exploration
=======================================
-- Find total number of customers by countries
SELECT
Country,
Count(customer_key) as total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC ;

-- Find total customers by gender 
SELECT
gender,
count(customer_key) as total_customers
FROM gold.dim_customers
GROUP BY  gender
ORDER BY  total_customers DESC ;

--Find total number of product by category
SELECT
Category,
count(product_key) as total_products
FROM gold.dim_products
GROUP BY Category
ORDER BY  total_products DESC ;

-- What is average cost in each category
SELECT 
category,
AVG(Cost) avg_cost
FROM gold.dim_products
GROUP BY Category
order by avg_cost DESC ;

-- What is total revenue generated for each category
SELECT
p.category,
SUM(f.sales_amount) as total_revenue
from gold.fact_sales f
LEFT JOIN
gold.dim_products p
ON p.product_key = f.product_key
group by p.category
order by total_revenue DESC ;

-- What is distribution of itmes sold across countries

SELECT
c.country,
SUM(f.quantity) as total_items_sold
FROM gold.fact_sales f
LEFT JOIN
gold.dim_customers c
on c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY total_items_sold DESC ;

============================
--Ranking Analysis 
============================

-- Find top 5 products generate highest revenue 
SELECT  TOP 5 * FROM (
SELECT
ROW_NUMBER() OVER (order by SUM(f.sales_amount) desc) as top_products,
p.product_name,
SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f
LEFT JOIN
gold.dim_products p
on f.product_key = p.product_key
GROUP BY p.product_name
)t
ORDER BY total_revenue DESC ;

-- Find top 10 customers who have generate the highest revenue
SELECT TOP 10 * FROM (
SELECT 
ROW_NUMBER() OVER (ORDER BY SUM(f.sales_amount) desc) as top_10_customers,
c.customer_key,
c.first_name,
c.last_name,
SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f 
LEFT JOIN
gold.dim_customers c 
on c.customer_key = f.customer_key
GROUP BY  
c.customer_key,
c.first_name,
c.last_name
)t
ORDER BY total_revenue DESC
;

-- The 3 customers with fewest orders
SELECT TOP 3 * FROM(
SELECT
ROW_NUMBER() OVER (ORDER BY COUNT(f.order_number) asc) as bottom_3_customers,
c.customer_key,
c.first_name,
c.last_name,
COUNT(f.Order_number ) as total_orders
FROM gold.fact_sales f
LEFT JOIN
gold.dim_customers c
on c.customer_key = f.customer_key
GROUP BY 
c.customer_key,
c.first_name,
c.last_name
)t
ORDER BY total_orders ASC
;

==========================================
-- ADVANCED DATA ANALYSIS
==========================================

-----------------------------------
-- Changes Over Time Analysis
-----------------------------------

-- Analyze sales performance over time
-- YEAR WISE 
SELECT
YEAR(order_date) as order_year,
SUM(sales_amount) as total_Sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)

--MONTH WISE 
SELECT
DATENAME(month,order_date) as order_month,
SUM(sales_amount) as total_Sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
GROUP BY DATENAME(month,order_date)
ORDER BY  SUM(sales_amount) DESC

-------------------------------------
Cumulative Analysis
-------------------------------------

-- Calculate total sales for each month , year and running total of sales over time 

--Month wise

Select
month_order,
total_sales,
sum(total_sales) over (ORDER  BY month_order) as running_total
from(
select 
DATETRUNC(month,order_date) as month_order,
sum(SaleS_amount) as total_sales 
from gold.fact_Sales 
where order_date is not null
group by DATETRUNC(month,order_date))t

-- year wise
Select
year_order,
total_sales,
sum(total_sales) over (ORDER  BY year_order) as running_total
from(
select 
DATETRUNC(year,order_date) as year_order,
sum(Sales_amount) as total_sales 
from gold.fact_Sales 
where order_date is not null
group by DATETRUNC(year,order_date))t

-- Calcualte moving average per year 
SELECT
year_order,
avg_price,
avg(avg_price) over (order by year_order) as running_avg
from(
SELECT
Datetrunc(year,order_date) as year_order,
avg(price) as avg_price 
from gold.fact_sales
where order_date is not null
group by Datetrunc(year,order_date)
)t

-----------------------------------
Performance Analysis
-----------------------------------

-- Analyze the yearly performance of products by comparing each products sales to both its average sales performance and previous year sales 
with yearly_product_sales as (
select
year(f.order_date) as order_year,
p.product_name,
sum(f.sales_amount) as current_sales
from gold.fact_sales f
left join
gold.dim_products p
on f.product_key = p.product_key
where f.order_date is not null
group by
year(f.order_date),
p.product_name)

select 
order_year,
product_name,
current_sales,
avg(current_sales) over (partition by product_name) as avg_sales,
current_sales - avg(current_sales) over (partition by product_name) as diff_avg,
case
when current_sales - avg(current_sales) over (partition by product_name  ) > 0 then 'Above Avg'
when current_sales - avg(current_sales) over (partition by product_name ) < 0 then 'Below Avg'
else  'Avg'
end as avg_change,
lag(current_sales ) over (partition by product_name order by order_year) as previousyear_sales,
current_sales - lag(current_sales ) over (partition by product_name order by order_year) as previous_year_diff,
case
when current_sales - lag(current_sales ) over (partition by product_name order by order_year) > 0 then 'increase'
when current_sales - lag(current_sales ) over (partition by product_name order by order_year) < 0 then 'decrease'
else 'no change'
end as previous_year_change
from yearly_product_sales
order by product_name,order_year



----------------------------------------
-- Paet to whole analysis
----------------------------------------


-- Which category contribute the most overall sales
with category_sales as (
SELECT 
category,
sum(sales_amount) as total_sales 
from gold.fact_sales f
left join
gold.dim_products p
on f.product_key = p.product_key
group by category
)
 

select 
category,
total_sales,
sum(total_sales) over() overall_sales,
concat(round(cast(total_Sales as float)/ sum(total_sales) over () * 100,2),'%') as percent_total
from category_sales 
order by total_Sales desc

------------------------------------
-- Data segmentation
------------------------------------

-- Segment products into cost ranges and count how many products fall into each segement
with product_segmentation as(
select
product_key,
product_name,
cost,
case 
when cost < 100 then 'Below 100'
when cost between 100 and 500 then '100-500'
when cost between 500 and 1000 then '500-100'
else ' above 1000'
end as cost_range 
from gold.dim_products
)
select 
cost_range,
count(product_key) as total_products
from product_segmentation 
group by cost_range 
order by total_products desc


from product_segmentation


/*
=============================================================
Customer Report
=============================================================
Purpose
  - This report consolidates key customers metrics and behaviours

Highlights
  1. Gathers essential field such as names,ages and  transactions details,
  2.Segments customers into categories (Vip,Regular,New) and age groups.
  3.Aggregates customer-level metrics:
  - total orders
  - total sales
  - total quantity purchased
  - lifespan (in months)
  4.Calculates valuable KPIs:
  - recency (month sincs last orders)
  - average order value
  - avgerage monthly spend
================================================================
*/
CREATE view gold.report_customers AS 
with Base_Query as (
/*----------------------------------------------------------------
--1. Base Query : Retrieve core columns from tables
-----------------------------------------------------------------*/
SELECT
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
customer_number,
c.first_name + ' ' + c.last_name as customer_name,
datediff(year,c.birthdate,getdate()) as age
from gold.fact_sales f
LEFT JOIN
gold.dim_customers c
on c.customer_key = f.customer_key
where order_date is not null
)
,customer_Aggregation as (
/*
-----------------------------------------------------------------------------
2) Customer Arregation: Summarizes key metrics at customer level
-----------------------------------------------------------------------------
*/
SELECT
customer_key,
customer_number,
customer_name,
age,
COUNT( DISTINCT order_number) total_orders,
SUM(sales_amount) total_sales ,
SUM(quantity) total_quantity,
COUNT(DISTINCT product_key) total_products,
MAX(order_date) last_order,
DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) as lifespan
from base_query
GROUP BY 
customer_key,
customer_number,
customer_name,
age)
SELECT
customer_key,
customer_number,
customer_name,
age,
CASE
WHEN age < 20 then 'under  20'
when age between 20 and 29 then '20 - 29'
when age between 30 and 39 then '30-39'
when age between 40 and 50 then '40-50'
else 'above 50'
end as age_groups,
lifespan,
CASE
WHEN lifespan >= 12 and total_Sales > 5000 then 'VIP'
WHEN lifespan >= 12 and total_Sales < 5000 then 'Regular'
else 'NEW'
END as customer_segment,
total_orders,
total_sales,
total_quantity,
total_products,
-- Compuate average order value (AVD)
CASE 
  WHEN total_sales = 0 then 0
  else total_sales/total_orders
  end as avg_order_value,
-- Compuate average monthly spend 
CASE 
  WHEN lifespan = 0 then total_sales
  else total_sales/ lifespan
  end as avg_monthly_spend,
last_order,
datediff(month,last_order,getdate()) as recency
from customer_aggregation


/*
=============================================================================================================
Product Report
=============================================================================================================
Purpose:
  - this report consolidates key product metrics and behaviours.

Highlights:
  1.Gathers essential field such as product_name,category,subcategory, and cost.
  2.Segments products by revenue to identify High-performance, Mid-Performance or Low performance
  3.Aggregates product-level metrics:
    - total orders
	- total sales
	- total quantity sold
	- total customers (unique)
	- lifespan (in months)
  4. Calculates valuable KPIs
    - recency (month sincs last date)
	- average order revenue
	- average monthly revenue
===============================================================================================================
*/


With base_query as (
SELECT
/*----------------------------------------------------------------
--1. Base Query : Retrieve core columns from tables
-----------------------------------------------------------------*/
f.order_number,
f.order_date,
f.customer_key,
f.sales_amount,
f.quantity,
p.product_key,
p.product_name,
p.category,
p.subcategory,
p.cost
from gold.fact_sales  f
left join
gold.dim_products p
on f.product_key = p.product_key
where order_date is not null   -- only consider valid sales dates 
),product_aggreagation as(
select
/*
-----------------------------------------------------------------------------
2) Products Arregation: Summarizes key metrics at products level
---------------------------------------------------------------------------*/
product_key,
product_name,
category,
subcategory,
cost,
DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) as lifespan,
MAX(order_date) as last_order_date,
COUNT(DISTINCT order_number) as total_orders,
SUM(sales_amount) as total_sales,
SUM(quantity) total_quantity,
COUNT( DISTINCT customer_key) total_customers,
ROUND(AVG(CAST(sales_amount as float)/ NULLIF(quantity,0)),1) as avg_selling_price
from 
base_query
group by 
product_key,
product_name,
category,
subcategory,
cost
)
select 
product_key,
product_name,
category,
subcategory,
cost,
last_order_date,
DATEDIFF(month,last_order_date,GETDATE()) AS recency_in_months,
CASE
WHEN total_sales > 50000 THEN 'High-Performance'
WHEN total_sales >+ 10000 THEN 'Mid-Performance'
ELSE 'Low-Performance'
end as product_segment,
lifespan,
total_orders,
total_sales,
total_quantity,
total_customers,
avg_selling_price,
-- Average Order Revenue
CASE
WHEN total_orders = 0 then 0
ELSE total_sales / total_orders
end as avg_order_revenue,
--Average Monthly Revnue
CASE
WHEN lifespan = 0 then total_sales
else total_sales/lifespan
end as avg_monthly_revenue
from product_aggreagation