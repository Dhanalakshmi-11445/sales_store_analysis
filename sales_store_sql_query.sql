use project;
CREATE TABLE sales_store (
transaction_id VARCHAR(15),
customer_id VARCHAR(15),
customer_name VARCHAR(30),
customer_age INT,
gender VARCHAR(15),
product_id VARCHAR(15),
product_name VARCHAR(15),
product_category VARCHAR(15),
quantiy INT,
prce FLOAT,
payment_mode VARCHAR(15),
purchase_date DATE,
time_of_purchase TIME,
status VARCHAR(15)
);
select * from sales_store;
#create copy of db--
CREATE TABLE sales_copy AS
SELECT * FROM sales_store;


select * from sales_store;
select * from sales_copy;

#Data cleaning
#step1 duplicates
SELECT transaction_id, COUNT(*)
FROM sales_copy 
GROUP BY transaction_id
HAVING COUNT(*) > 1;

#deleting the duplicate

SET SQL_SAFE_UPDATES = 0;

with cte as(
select *,row_number() over(partition by transaction_id order by transaction_id) as rn from sales_copy
)
DELETE FROM sales_copy
WHERE transaction_id IN (
  SELECT transaction_id FROM cte WHERE rn > 1);
  
#Step 2 :- Correction of Headers

ALTER TABLE sales_copy CHANGE quantiy quantity INT;
ALTER TABLE sales_copy CHANGE prce price FLOAT;

#--Step 3 :- To check Datatype
SHOW COLUMNS FROM sales_copy;

#--Step 4 :- To Check Null Values --to check null count
SELECT 
  SUM(transaction_id IS NULL) AS transaction_id_null,
  SUM(customer_id IS NULL) AS customer_id_null,
  SUM(customer_name IS NULL) AS customer_name_null,
  SUM(customer_age IS NULL) AS customer_age_null,
  SUM(gender IS NULL) AS gender_null,
  SUM(product_id IS NULL) AS product_id_null,
  SUM(product_name IS NULL) AS product_name_null,
  SUM(product_category IS NULL) AS product_category_null,
  SUM(quantity IS NULL) AS quantity_null,
  SUM(price IS NULL) AS price_null,
  SUM(payment_mode IS NULL) AS payment_mode_null,
  SUM(purchase_date IS NULL) AS purchase_date_null,
  SUM(status IS NULL) AS status_null
FROM sales_copy;

DELETE FROM sales_copy WHERE transaction_id IS NULL;
#updating few columns
UPDATE sales_copy
SET customer_id='CUST9494'
WHERE transaction_id='TXN977900';

UPDATE sales_copy
SET customer_id='CUST1401'
WHERE transaction_id='TXN985663';

UPDATE sales_copy
SET customer_name='Mahika Saini', customer_age=35, gender='M'
WHERE transaction_id='TXN432798';

#--Step 5:- Data Cleaning

SELECT DISTINCT gender
FROM sales_copy;

	update sales_copy
	set gender='M'
	where gender='Male';
UPDATE sales_copy
SET gender='F'
WHERE gender='Female';

select distinct payment_mode
from sales_copy;

update sales_copy
set payment_mode='Credit Card'
where payment_mode='CC';

#1. What are the top 5 most selling products by quantity?
with cte as(
select product_name,sum(quantity) as tot_quantity,
 dense_rank() over(order by sum(quantity) desc) as rnk
from sales_copy
where status='delivered'
group by 1
order by tot_quantity desc
)
select * from cte 
where rnk<=5;

# 2. Which products are most frequently cancelled?
with cte as(
select product_name ,count(*) as frequent_cancell,
dense_rank() over(order by count(*) desc) as rnk
from sales_copy
where status='cancelled'
group by 1
order by frequent_cancell desc
)
select * from cte
where rnk<=5;

#--🕒 3. What time of the day has the highest number of purchases?
with cte as(
select time_of_purchase,
case
when hour(time_of_purchase) between 0 and 11 then 'Morning'
when hour(time_of_purchase) between 12 and 15 then 'Afternoon'
when hour(time_of_purchase) between 16 and 19 then 'Evening'
when hour(time_of_purchase) between 20 and 24 then 'Night'
end as time_of_day
from sales_copy
)
select time_of_day , count(*) as tot from cte
group by time_of_day
order by tot desc ;

#4. Who are the top 5 highest spending customers?
with cte as(
select customer_name, sum(quantity*price) as tot,
dense_rank() over(order by sum(quantity*price) desc) as rnk
from sales_copy
group by 1)
select customer_name,  tot from cte 
where rnk <=5;

#5 Which product categories generate the highest revenue?

with cte as(
select product_category, sum(quantity*price) as tot,
dense_rank() over(order by sum(quantity*price) desc) as rnk
from sales_copy
group by 1)
select product_category,  tot from cte 
where rnk <=10;

#6. What is the return/cancellation rate per product category?
with cte as(
select product_category ,
sum(status='cancelled') as cancelled_status,
sum(status='returned') as returned,
count(*) as tot_orders,
round(sum(status='cancelled')/count(*) * 100 ,2)as cancell_per,
round(sum(status='returned')/count(*) * 100,2) as return_per
from sales_copy
group by 1)
select product_category,cancell_per,return_per from cte;

#7. What is the most preferred payment mode?
select payment_mode ,count(*) as tot
from sales_copy
group by 1
order by tot desc;
#8. How does age group affect purchasing behavior?
select 
case 
when customer_age between 0 And 10 then 'Child'
 when customer_age between 11 And 19 then 'Teen'
 when customer_age between 20 And 35 then 'young'
 when customer_age between 35 And 100 then 'old'
  when customer_age between 0 And 10 then 'Child'
  end as age_category,
  sum(quantity * price ) as tot
  from sales_copy
group by  age_category
order by tot desc;

#9. What’s the monthly sales trend?
select date_format(purchase_date,'%Y-%m') as new_date,sum(quantity * price) as tot 
from sales_copy
group by new_date
order by new_date;

#10. Are certain genders buying more specific product categories?
select gender,product_category,count(product_category) as tot
from sales_copy
group by gender,2
order by gender;
