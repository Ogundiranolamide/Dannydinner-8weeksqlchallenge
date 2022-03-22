/****** Script for SelectTopNRows command from SSMS  ******/
--Q1- What is the total amount each customer spent at the restaurant?
--Q2- How many days has each customer visited the restaurant?
--Q3- What was the first item from the menu purchased by each customer?
--Q4- What is the most purchased item on the menu and how many times was it purchased by all customers?
--Q5- Which item was the most popular for each customer?
--Q6- Which item was purchased first by the customer after they became a member?
--Q7- Which item was purchased just before the customer became a member?
--Q8- What is the total items and amount spent for each member before they became a member?
--Q9- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
--Q10- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?

--select 
--	* From menu

--SELECT
--	* FROM sales

--select
--	* from members

--Data inview 1
select
	*
from sales sl
left join members mb
on mb.customer_id = sl.customer_id
join menu m
on m.product_id = sl.product_id

-- Question 1 --What is the total amount each customer spent at the restaurant?
select
	sl.customer_id,
	concat('$ ',Sum(price)) as "Total price ($)"
from sales sl
left join members mb
on mb.customer_id = sl.customer_id
join menu m
on m.product_id = sl.product_id
group by sl.customer_id

-- Question 2 --How many days has each customer visited the restaurant?
select
	sl.customer_id,
	concat(count(distinct order_date), ' Day(s)') as "Days visited"
from sales sl
left join members mb
on mb.customer_id = sl.customer_id
join menu m
on m.product_id = sl.product_id
group by sl.customer_id

-- Question 3 --What was the first item from the menu purchased by each customer?
select
	sl.customer_id,
	product_name,
	order_date
from sales sl
left join members mb
on mb.customer_id = sl.customer_id
join menu m
on m.product_id = sl.product_id
where order_date = 
				(select 
					min(order_date)
				from sales sl
				left join members mb
				on mb.customer_id = sl.customer_id
				join menu m
				on m.product_id = sl.product_id
				)
-- Question 3 --USING CTE AND WINDOWS FUNCTION
WITH order_rank_cte as ( 
SELECT
	sl.customer_id,
    DENSE_RANK() OVER (PARTITION BY sl.customer_id ORDER BY order_date) as order_rank,
    mn.product_name
FROM sales sl
LEFT JOIN menu mn
ON sl.product_id = mn.product_id
)
SELECT 
	customer_id,
    product_name
FROM order_rank_cte
WHERE order_rank = 1 ;

-- Question 4 -- What is the most purchased item on the menu and how many times was it purchased by all customers?
select top (1)
	product_name,
	count(product_name) as "Count of purchase"
from sales sl
left join members mb
on mb.customer_id = sl.customer_id
join menu m
on m.product_id = sl.product_id
group by product_name
order by "Count of purchase" desc

-- Question 4 -- (PER CUSTOMER -- BONUS)
select
	sl.customer_id,
	product_name,
	count(product_name) as "Count of purchase"
from sales sl
left join members mb
on mb.customer_id = sl.customer_id
join menu m
on m.product_id = sl.product_id
group by sl.customer_id, product_name

-- Question 5 -- Which item was the most popular for each customer?
select
	sl.customer_id,
	product_name,
	count(product_name) as "Count of purchase"
from sales sl
left join members mb
on mb.customer_id = sl.customer_id
join menu m
on m.product_id = sl.product_id
group by sl.customer_id, product_name
order by sl.customer_id, "Count of purchase" desc

-- Question 5 -- USING CTE AND WINDOWS FUNCTION
WITH member_q_cte AS (
SELECT
	customer_id,
    menu.product_name,
    COUNT(sl.product_id) as "Count of purchase",
    RANK() OVER (PARTITION BY sl.customer_id ORDER BY COUNT(sl.product_id) DESC ) as _rank 
FROM sales sl
LEFT JOIN menu
ON sl.product_id = menu.product_id
GROUP BY 
	customer_id,
    menu.product_name
)
SELECT 
	customer_id,
    product_name,
    "Count of purchase"
FROM member_q_cte
WHERE _rank = 1;

-- Question 6 -- Which item was purchased first by the customer after they became a member?
select
	sl.customer_id,
	product_name,
	order_date,
	join_date
from sales sl
left join members mb
on mb.customer_id = sl.customer_id
join menu m
on m.product_id = sl.product_id
where order_date >=
			(select
				min(join_date)
			from sales sl
			left join members mb
			on mb.customer_id = sl.customer_id
			join menu m
			on m.product_id = sl.product_id
			where join_date is not null
			--group by sl.customer_id
			)
and join_date is not null
order by sl.customer_id asc

-- Question 6 -- USING CTEAND WINDOWS FUNCTION
WITH member_rank_cte AS ( 
SELECT 
	sl.customer_id,
    order_date, 
    product_name,
    DENSE_RANK() OVER (PARTITION BY sl.customer_id ORDER BY order_date) AS  _rank
from sales sl
left join members mb
on mb.customer_id = sl.customer_id
join menu m
on m.product_id = sl.product_id
WHERE order_date >= join_date
)

SELECT
	customer_id,
    order_date,
    product_name
FROM member_rank_cte
WHERE _rank = 1; 

-- Question 7 -- Which item was purchased just before the customer became a member?
select
	sl.customer_id,
	product_name,
	order_date,
	join_date,
	price
from sales sl
left join members mb
on mb.customer_id = sl.customer_id
join menu m
on m.product_id = sl.product_id
where order_date <
			(select
				min(join_date)
			from sales sl
			left join members mb
			on mb.customer_id = sl.customer_id
			join menu m
			on m.product_id = sl.product_id
			where join_date is not null
			)
and join_date is not null
order by sl.customer_id asc

-- Question 7 -- USING CTEAND WINDOWS FUNCTION
WITH first_purchase_cte AS
(SELECT 
	sl.customer_id,
    order_date, 
    product_name,
    DENSE_RANK() OVER (PARTITION BY sl.customer_id ORDER BY order_date DESC) AS  _rank
FROM members
INNER JOIN sales sl
ON members.customer_id = sl.customer_id
INNER JOIN menu
ON menu.product_id = sl.product_id
WHERE order_date < join_date
)

SELECT
	customer_id,
    order_date,
    product_name
FROM first_purchase_cte
WHERE _rank = 1; 

-- Question 8 -- What is the total items and amount spent for each member before they became a member?
select
	sl.customer_id,
	count(product_name) as "Count of product purchased",
	concat ('$', ' ' ,sum(price)) as "total purchases before membership",
	max(join_date) as "Join Date"
from sales sl
left join members mb
on mb.customer_id = sl.customer_id
join menu m
on m.product_id = sl.product_id
where order_date <
			( select
				min(join_date)
			from sales sl
			left join members mb
			on mb.customer_id = sl.customer_id
			join menu m
			on m.product_id = sl.product_id
			)
and join_date is not null
group by sl.customer_id

-- Question 8 -- (WITHOUT SUBQUERIES)
SELECT 
	sl.customer_id,
    COUNT(DISTINCT sl.product_id) AS unique_items ,
    concat ('$', ' ', SUM(menu.price)) AS "total purchases before membership",
	max(join_date) as "Join Date"
FROM members
INNER JOIN sales sl
ON members.customer_id = sl.customer_id
INNER JOIN menu
ON menu.product_id = sl.product_id
WHERE order_date < join_date
GROUP BY sl.customer_id;

-- Question 9 -- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select
	sl.customer_id, 
	product_name,
	price,
	CASE
		when product_name = 'sushi' THEN (price * 10)* 2
		ELSE price * 10
	END as Points
from sales sl
left join members mb
on mb.customer_id = sl.customer_id
join menu m
on m.product_id = sl.product_id
---------------------------------------
select
	sl.customer_id, 
	sum(CASE
			when product_name = 'sushi' THEN (price * 10)* 2
			ELSE price * 10
		END) as Points
from sales sl
left join members mb
on mb.customer_id = sl.customer_id
join menu m
on m.product_id = sl.product_id
Group by sl.customer_id

-- Question 10 -- In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?

-- A SIMPLER QUERY FOR QUESTION 10 (THIS IS MY FAV. WAY TO SOLVE)
select
	sl.customer_id,
	sum (CASE
		when order_date between join_date and dateadd(day,6,join_date) THEN (price * 10)* 2
		when product_name = 'sushi' THEN (price * 10)* 2
		ELSE price * 10
		END )as Points
from sales sl
left join members mb
on mb.customer_id = sl.customer_id
join menu m
on m.product_id = sl.product_id
where order_date between '2021-01-01' and '2021-01-31'
and join_date is not null
group by sl.customer_id
