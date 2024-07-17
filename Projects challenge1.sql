CREATE SCHEMA dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR (1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
select * from sales;
select * from members;
select * from menu;
show databases;
use dannys_diner;
show tables;
----------------------------------------------------------------------------------------------------------------------------------------
-- 1. What is the total amount each customer spent at the restaurant?
	select customer_id, sum(price) as total_amt
    from sales as s join menu as m on m.product_id = s.product_id 
    group by customer_id;
						--------------
-- 2. How many days has each customer visited the restaurant?
	select customer_id, count(distinct order_date)
    from sales 
    group by customer_id;
									------------------------
-- 3. What was the first item from the menu purchased by each customer?
	with cte as 
    (
    select customer_id, product_name, row_number() over(partition by customer_id order by order_date) as first_item
    from sales as s join menu as m 
    on m.product_id = s.product_id
    )
    select customer_id, product_name,first_item from cte
    where first_item = 1;
    
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
	select m.product_name, count(m.product_name) as order_count
    from menu as m join sales as s
    on m.product_id = s.product_id
    group by product_name 
    order by count(m.product_name) desc limit 1;
						---------------
    
-- 5. Which item was the most popular for each customer?
with item_count as
	(
	select s.customer_id, m.product_name, count(*) as order_count,
    dense_rank() over(partition by customer_id order by count(*)) as rn
    from menu as m join sales as s
    on m.product_id = s.product_id
    group by s.customer_id, product_name
    order by count(*)
	)
select customer_id, product_name from item_count
where rn =1;
						-----------------
-- 6. Which item was purchased first by the customer after they became a member?
	with orders as
    (
    select s.customer_id, m.product_name,s.order_date, mb.join_date,
    dense_rank() over (partition by customer_id order by order_date) as rn
    from sales as s join menu as m on s.product_id =m.product_id
    join members as mb on s.customer_id = mb.customer_id
    where s.order_date > mb.join_date
	)
	select customer_id , product_name from orders
    where rn = 1;
							------------------------------	
-- 7. Which item was purchased just before the customer became a member?

with orders as
    (
    select s.customer_id, m.product_name,s.order_date, mb.join_date,
    dense_rank() over (partition by customer_id order by order_date desc) as rn
    from sales as s join menu as m on s.product_id =m.product_id
    join members as mb on s.customer_id = mb.customer_id
    where s.order_date < mb.join_date
	)
	select customer_id , product_name from orders
    where rn = 1;
									------------------------------

-- 8. What is the total items and amount spent for each member before they became a member?

		SELECT s.customer_id, count(s.order_date) as total_items, sum(m.price) as amount_spent
		FROM sales as s
		JOIN menu as m 
		ON s.product_id = m.product_id
		JOIN members as mb
		ON s.customer_id = mb.customer_id
		WHERE s.order_date < mb.join_date
		GROUP BY customer_id;
										------------------
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
		WITH CTE as 
        (
        SELECT s.customer_id, m.product_name, sum(m.price) total_amt,
        CASE 
        WHEN m.product_name = 'sushi' THEN sum(m.price)*2*10
        ELSE sum(m.price)*10
        END as Points
        FROM sales s
        JOIN menu m 
        ON s.product_id =m.product_id
        GROUP BY s.customer_id, m.product_name 
        )
      SELECT customer_id, sum(points) from CTE
      GROUP BY customer_id;
							-----------------------------------------------------------
	

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
		WITH CTE as
        (
        SELECT s.customer_id, m.product_name, m.price, s.order_date, mb.join_date,
        CASE
        WHEN s.order_date  BETWEEN mb.join_date AND mb.join_date + INTERVAL 7 DAY THEN m.price*2*10
        WHEN m.product_name = 'sushi' THEN m.price*2*10
        ELSE m.price*10
        END as member_pts
        FROM 
        sales as s
        JOIN menu as m
        ON s.product_id = m.product_id
        JOIN members as mb
        ON s.customer_id = mb.customer_id
        WHERE order_date < '2021-02-01'
        )
        SELECT customer_id, sum(member_pts) FROM CTE
        GROUP BY customer_id;
        
-----------------------------------------------------------------------------------------------------------------------------------------------
	Q.11 Determine the name and price of the product ordered by each customer on all order dates and find out whether the customer was a member on the order date or not
    SELECT s.customer_id, m.product_name, m.price, s.order_date, mb.join_date,
    CASE 
    WHEN s.order_date >= mb.join_date THEN 'Yes'
    ELSE 'No'
    END as Member
    FROM sales as s 
    JOIN menu as m 
    ON s.product_id = m.product_id
    JOIN members as mb 
	ON 	s.customer_id = mb.customer_id
											---------------------------------------
    
    Q.12 Rank thr previous output from Q.11 based on the order_date for each customer. Display NULL if customer was not a member when dish was ordered.
    WITH CTE as
    (
    SELECT s.customer_id, m.product_name, m.price, s.order_date, mb.join_date,
    CASE 
    WHEN s.order_date >= mb.join_date THEN 'Yes'
    ELSE 'No'
    END as Member_status
    FROM sales as s 
    JOIN menu as m 
    ON s.product_id = m.product_id
    LEFT JOIN members as mb 
	ON 	s.customer_id = mb.customer_id
    )
    SELECT *,
    CASE 
    WHEN cte.Member_status = 'Yes' THEN RANK () OVER (PARTITION BY customer_id, member_status ORDER BY order_date) 
    ELSE NULL
    END as Ranking
    FROM CTE;
    
    