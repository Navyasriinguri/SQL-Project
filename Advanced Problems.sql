## 1. Calculate the moving average of order values for each customer over their order history.
  WITH order_values AS (
    SELECT
        t1.order_id,
        t1.order_purchase_timestamp,
        t2.customer_unique_id,
        SUM(t3.price) AS total_order_value
    FROM
        orders AS t1
    JOIN
        Customers AS t2 ON t1.customer_id = t2.customer_id
    JOIN
        order_items AS t3 ON t1.order_id = t3.order_id
    GROUP BY
        t1.order_id,
        t1.order_purchase_timestamp,
        t2.customer_unique_id
)
SELECT
    order_id,
    customer_unique_id,
    order_purchase_timestamp,
    total_order_value,
    -- Calculate the 2-order moving average of total_order_value for each customer
    AVG(total_order_value) OVER (
        PARTITION BY customer_unique_id
        ORDER BY order_purchase_timestamp
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS moving_average_order_value
FROM
    order_values
ORDER BY
    customer_unique_id,
    order_purchase_timestamp;
  
  
 ##2. Calculate the cumulative sales per month for each year.
WITH MonthlySales AS (
  SELECT
    DATE_FORMAT(T1.order_purchase_timestamp, '%Y') AS order_year,
    DATE_FORMAT(T1.order_purchase_timestamp, '%Y-%m') AS order_month,
    SUM(T2.price) AS monthly_sales
  FROM orders AS T1
  JOIN order_items AS T2
    ON T1.order_id = T2.order_id
  GROUP BY
    order_year,
    order_month
)
SELECT
  order_year,
  order_month,
  monthly_sales,
  SUM(monthly_sales) OVER (
    PARTITION BY
      order_year
    ORDER BY
      order_month
  ) AS cumulative_sales
FROM MonthlySales
ORDER BY
  order_year,
  order_month;
  
  ## 3. Calculate the year-over-year growth rate of total sales.
  WITH AnnualSales AS (
  SELECT
    YEAR(T1.order_purchase_timestamp) AS order_year,
    SUM(T2.price) AS yearly_sales
  FROM orders AS T1
  JOIN order_items AS T2
    ON T1.order_id = T2.order_id
  GROUP BY
    order_year
)
SELECT
  order_year,
  yearly_sales,
  (
    (yearly_sales - LAG(yearly_sales) OVER (
      ORDER BY
        order_year
    )) / LAG(yearly_sales) OVER (
      ORDER BY
        order_year
    )
  ) * 100 AS yoy_growth_rate_percentage
FROM AnnualSales
ORDER BY
  order_year;
  
  ##4. Calculate the retention rate of customers, defined as the percentage of customers who make another purchase within 6 months of their first purchase.
WITH customer_purchases AS (
    SELECT
        t2.customer_unique_id,
        t1.order_purchase_timestamp,
        -- Use ROW_NUMBER() to rank each purchase for a customer
        ROW_NUMBER() OVER(PARTITION BY t2.customer_unique_id ORDER BY t1.order_purchase_timestamp) AS purchase_rank
    FROM
        orders AS t1
    JOIN
        Customers AS t2 ON t1.customer_id = t2.customer_id
),
customer_first_second_purchase AS (
    SELECT
        customer_unique_id,
        MIN(CASE WHEN purchase_rank = 1 THEN order_purchase_timestamp ELSE NULL END) AS first_purchase_date,
        MIN(CASE WHEN purchase_rank = 2 THEN order_purchase_timestamp ELSE NULL END) AS second_purchase_date
    FROM
        customer_purchases
    GROUP BY
        customer_unique_id
    HAVING
        COUNT(order_purchase_timestamp) >= 2
)
SELECT
    -- Calculate the number of customers retained (second purchase within 6 months)
    CAST(SUM(CASE WHEN DATEDIFF(second_purchase_date, first_purchase_date) <= 180 THEN 1 ELSE 0 END) AS REAL) * 100
    / COUNT(*) AS retention_rate_6_months
FROM
    customer_first_second_purchase;
  
  
  ##5. Identify the top 3 customers who spent the most money in each year.
  WITH CustomerOrderSpending AS (
  SELECT
    T1.order_id,
    SUM(T1.payment_value) AS order_value
  FROM payments AS T1
  GROUP BY
    T1.order_id
), CustomerAnnualSpending AS (
  SELECT
    YEAR(T2.order_purchase_timestamp) AS order_year,
    T3.customer_unique_id,
    SUM(T1.order_value) AS total_spent
  FROM CustomerOrderSpending AS T1
  JOIN orders AS T2
    ON T1.order_id = T2.order_id
  JOIN Customers AS T3
    ON T2.customer_id = T3.customer_id
  GROUP BY
    order_year,
    T3.customer_unique_id
), RankedCustomers AS (
  SELECT
    order_year,
    customer_unique_id,
    total_spent,
    RANK() OVER (
      PARTITION BY
        order_year
      ORDER BY
        total_spent DESC
    ) AS customer_rank
  FROM CustomerAnnualSpending
)
SELECT
  order_year,
  customer_unique_id,
  total_spent,
  customer_rank
FROM RankedCustomers
WHERE
  customer_rank <= 3
ORDER BY
  order_year,
  customer_rank;