## 1. List all unique cities where customers are located.
SELECT DISTINCT customer_city FROM Customers;

## 2.Count the number of orders placed in 2017.
SELECT count(order_id) as OrderCountin2017 FROM orders WHERE order_purchase_timestamp LIKE '2017%';

## 3. Find the total sales per category.
ALTER TABLE products CHANGE `product category` product_category VARCHAR(255);
SELECT
  t1.product_category,
  SUM(t2.price) AS total_sales
FROM products AS t1
JOIN order_items AS t2
  ON t1.product_id = t2.product_id
GROUP BY
  t1.product_category;
  
## 4. Calculate the percentage of orders that were paid in installments.
SELECT
  (
    COUNT(DISTINCT CASE
      WHEN payment_installments > 1
      THEN T1.order_id
    END)
  ) * 100.0 / COUNT(DISTINCT T2.order_id) as InstallemtOrder
FROM payments AS T1
JOIN orders AS T2
  ON T1.order_id = T2.order_id;

## 5. Count the number of customers from each state.
SELECT
  customer_state,
  COUNT(customer_id) AS customer_count
FROM Customers
GROUP BY
  customer_state
ORDER BY
  customer_count DESC;
