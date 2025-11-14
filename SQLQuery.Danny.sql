select * 
from members

/*1- What is the total amount each customer spent at the restaurant?*/
SELECT 
    s.customer_id,
    SUM(m.price) AS total_spent
FROM sales AS s
JOIN menu AS m
    ON s.product_id = m.product_id
GROUP BY s.customer_id;


-------------------------------------
/*2-How many days has each customer visited the restaurant?*/
SELECT customer_id,
       COUNT(DISTINCT order_date) AS visit_days
FROM sales 
GROUP BY customer_id;
-------------------------------------
/*3-What was the first item from the menu purchased by each customer?*/
WITH FirstPurchase AS (
                        SELECT s.customer_id,
                        s.order_date,
                        m.product_name,
 RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk
 FROM sales s JOIN menu m ON s.product_id = m.product_id)
SELECT customer_id, product_name FROM FirstPurchase WHERE rnk = 1;
-------------------------------------
/*4- What is the most purchased item on the menu and how many times was it been 
purchased by all customers?*/

SELECT 
    m.product_name,
    COUNT(*) AS total_orders
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_orders DESC
-------------------------------------
/*5-Which item was the most popular for each customer?*/

WITH ItemCounts AS (
    SELECT 
        s.customer_id,
        m.product_name,
        COUNT(*) AS cnt,
        RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS rnk
    FROM sales AS s
    JOIN menu AS m
        ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT customer_id, product_name, cnt
FROM ItemCounts
WHERE rnk = 1;

---------------------------------------
/*6-Which item was purchased first by the customer after they became a member? */

SELECT customer_id, product_name
FROM (
    SELECT 
        s.customer_id,
        s.order_date,
        m.product_name,
        RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id
    JOIN members mem ON s.customer_id = mem.customer_id
    WHERE s.order_date >= mem.join_date
) first_after_join
WHERE rnk = 1;
--------------------------------------
/*7-Which item was purchased just before the customer became a member?*/

WITH BeforeJoin AS (
    SELECT 
        s.customer_id,
        s.order_date,
        m.product_name,
        RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rnk
    FROM sales AS s
    JOIN menu AS m
        ON s.product_id = m.product_id
    JOIN members AS mem
        ON s.customer_id = mem.customer_id
    WHERE s.order_date < mem.join_date
)
SELECT customer_id, product_name
FROM BeforeJoin
WHERE rnk = 1;
-----------------------------------------
/*8 What is the total items and amount spent on each member before they became a 
member?*/

SELECT 
    s.customer_id,
    COUNT(*) AS total_items,
    SUM(m.price) AS total_spent
FROM sales AS s
JOIN menu AS m
    ON s.product_id = m.product_id
JOIN members AS mem
    ON s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id;
------------------------------------------
/*9-If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how 
many points would each customer have?*/

SELECT 
    s.customer_id,
    SUM(
        CASE 
            WHEN m.product_name = 'sushi' THEN m.price * 20
            ELSE m.price * 10
        END
    ) AS total_points
FROM sales AS s
JOIN menu AS m
    ON s.product_id = m.product_id
GROUP BY s.customer_id;
-------------------------------------------
/*10- In the first week after a customer joins the program (including their join date) they 
earn 2x points on all items, not just sushi - how many points do customer A and B 
have at the end of January?*/

SELECT 
    s.customer_id,
    SUM(
        CASE 
            WHEN s.order_date BETWEEN mem.join_date AND DATEADD(DAY, 6, mem.join_date) 
                THEN m.price * 20
            WHEN m.product_name = 'sushi'
                THEN m.price * 20
            ELSE m.price * 10
        END
    ) AS total_points
FROM sales AS s
JOIN menu AS m
    ON s.product_id = m.product_id
JOIN members AS mem
    ON s.customer_id = mem.customer_id
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id;
----------------------------------------------------
/*Join All the Things */

SELECT 
    s.customer_id,s.order_date,m.product_name, m.price,
    CASE WHEN s.order_date >= mem.join_date THEN 'Y' ELSE 'N' END AS member
FROM sales AS s
JOIN menu AS m
    ON s.product_id = m.product_id
LEFT JOIN members AS mem
    ON s.customer_id = mem.customer_id;
---------------------------------------------------
/*Rank All the Things*/
WITH Joined AS (
    SELECT 
        s.customer_id,s.order_date,m.product_name,m.price,
        CASE WHEN s.order_date >= mem.join_date THEN 'Y' ELSE 'N' END AS member,
        CASE 
            WHEN s.order_date >= mem.join_date 
            THEN RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date)
        END AS ranking
    FROM sales AS s
    JOIN menu AS m
        ON s.product_id = m.product_id
    LEFT JOIN members AS mem
        ON s.customer_id = mem.customer_id)
SELECT *
FROM Joined
ORDER BY customer_id, order_date;




