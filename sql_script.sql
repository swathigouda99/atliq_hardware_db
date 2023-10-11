##Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
#query1
SELECT * FROM gdb023.dim_customer
where customer="Atliq Exclusive"and region="APAC";


##What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, 
#unique_products_2020 unique_products_2021 percentage_chg
#query2
with cte_2021 as (select   count(distinct product_code) as unique_products_2021 from gdb023.fact_sales_monthly
where fiscal_year=2021),
cte_2020 as (select count(distinct product_code) as unique_products_2020 from gdb023.fact_sales_monthly
where fiscal_year=2020)
select cte_2021.unique_products_2021,cte_2020.unique_products_2020,((cte_2021.unique_products_2021-cte_2020.unique_products_2020)/cte_2020.unique_products_2020 * 100) as percentage_change from cte_2021 cross join cte_2020;

## querry3
#Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
#The final output contains 2 fields, segment product_count
SELECT segment , count(DISTINCT product) AS product_count
    FROM dim_product 
    GROUP BY segment 
    ORDER BY product_count DESC;
    
#query4# 
With cte as(select count(distinct fs.product_code) as product_count_2020,segment
from fact_sales_monthly fs join dim_product dp
on fs.product_code = dp.product_code
where fiscal_year = 2020
group by segment),
cte2 as(select count(distinct fs.product_code) as product_count_2021,segment
from fact_sales_monthly fs join dim_product dp
on fs.product_code = dp.product_code
where fiscal_year = 2021
group by segment)
select cte.segment,product_count_2020,product_count_2021,(product_count_2021- product_count_2020) as differnce,segment
from cte join cte2 using(segment)
order by differnce desc;   
    
## querry5
#Get the products that have the highest and lowest manufacturing costs.
#The final output should contain these fields, product_code product manufacturing_cost

(SELECT a.product_code,b.product,a.manufacturing_cost FROM gdb023.fact_manufacturing_cost a
inner join dim_product b
on a.product_code=b.product_code
order by 3 desc limit 1)
UNION 
(SELECT a.product_code,b.product,a.manufacturing_cost FROM gdb023.fact_manufacturing_cost a
inner join dim_product b
on a.product_code=b.product_code
order by 3 asc limit 1);


##querry6
#Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
#The final output contains these fields, customer_code customer average_discount_percentage
SELECT t1.customer_code,t2.customer,avg(t1.pre_invoice_discount_pct) FROM gdb023.fact_pre_invoice_deductions t1
join dim_customer t2
on t1.customer_code=t2.customer_code
and t1.fiscal_year=2021 and t2.sub_zone="India"
group by t1.customer_code
order by 3 desc 
limit 5;


##querry7
#Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . This analysis helps to get an idea of low and high-performing months and take strategic decisions.
#The final report contains these columns: Month Year Gross sales Amount
with temp_table as (SELECT month(t2.date) as month,year(t2.date) as year,t3.gross_price as gross_price FROM  dim_customer t1 join 
gdb023.fact_sales_monthly t2
on t1.customer_code=t2.customer_code
join gdb023.fact_gross_price t3
on t2.product_code=t3.product_code 
and t1.customer="Atliq Exclusive")
SELECT month,Year,round((sum(gross_price)/1000000),2) AS Gross_sales_amount_in_millions
	FROM temp_table
    GROUP BY month,Year
    ORDER BY Year;
    
    
# 8) In which quarter of 2020, got the maximum total_sold_quantity?
#The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity

WITH temp_table AS
(
 SELECT date, month((date_add(date,interval 4 month))) AS period, 
 sold_quantity 
 FROM fact_sales_monthly where fiscal_year="2020"
 )
SELECT CASE
   when (period/3) <= 1 then "Q1"
   when (period/3) <= 2 and period/3 > 1 then "Q2"
   when (period/3) <=3 and period/3 > 2 then "Q3"
   when (period/3) <=4 and period/3 > 3 then "Q4" end as quarter,
round((SUM(sold_quantity)/1000000),2) as total_sold_quantity_in_millions  FROM temp_table 
 GROUP BY quarter 
 ORDER BY total_sold_quantity_in_millions DESC;
 
#9) Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
# The final output contains these fields, channel gross_sales_mln percentage
with temp_table as (SELECT sum(t2.sold_quantity*t1.gross_price) as total_sales,t3.channel as channel FROM fact_gross_price t1
join fact_sales_monthly t2
on t1.product_code=t2.product_code
join dim_customer t3
on t2.customer_code=t3.customer_code
and t2.fiscal_year=2021
group by t3.channel
order by 1 desc)
select channel,ROUND((total_sales/1000),2) as gross_sales_in_million,ROUND(total_sales/ (sum(total_sales) OVER()) *100,2) as percentage from temp_table;


##querry10
#Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
#The final output contains these fields, division product_code
With temp_table AS 
( 
  SELECT 
   division , s.product_code ,concat( p.product ,"(",p.variant,")") AS product, 
   SUM(s.sold_quantity) AS total_sold_quantity , rank() OVER (PARTITION BY division 
   ORDER BY SUM(sold_quantity)DESC)
   AS rank_order
   FROM 
   fact_sales_monthly s 
   JOIN dim_product p
   ON s.product_code = p.product_code
   WHERE fiscal_year=2021 
   GROUP BY product_code
 )
SELECT * 
  FROM temp_table
  WHERE rank_order 
  IN(1,2,3);

