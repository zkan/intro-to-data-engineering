-- Denormalization: Create fact and dimension tables

CREATE TABLE IF NOT EXISTS `analytics.fact_payment` (
    payment_id INTEGER,
    order_id INTEGER,
    user_id INTEGER,
    payment_method STRING,
    payment_status STRING,
    amount FLOAT64
);

CREATE TABLE IF NOT EXISTS `analytics.dim_customer` (
    user_id INTEGER,
    name STRING
);

CREATE TABLE IF NOT EXISTS `analytics.dim_order` (
    order_id INTEGER,
    order_date STRING,
    order_status STRING
);

-- Data Transformation (using INSERT) => This causes duplicate date!

INSERT INTO
  `analytics.dim_customer`
SELECT
  CAST(id AS INT64) AS user_id,
  CONCAT(first_name, ' ', last_name) AS name
FROM
  `public.jaffle_shop_customer`

-- Data Transformation (using MERGE)

MERGE
  `analytics.fact_payment` f
USING
  (
    SELECT
      sp.int AS payment_id,
      sp.orderid AS order_id,
      jso.user_id AS user_id,
      sp.paymentmethod AS payment_method,
      sp.status AS payment_status,
      sp.amount
    FROM
      `public.stripe_payment` sp
    JOIN
      `public.jaffle_shop_order` jso
    ON
      sp.orderid = jso.id
  ) n
ON
  f.payment_id = n.payment_id
WHEN NOT MATCHED
THEN
  INSERT (
    payment_id,
    order_id,
    user_id,
    payment_method,
    payment_status,
    amount
  ) VALUES (
    CAST(n.payment_id AS INTEGER),
    CAST(n.order_id AS INTEGER),
    CAST(n.user_id AS INTEGER),
    n.payment_method,
    n.payment_status,
    n.amount
  );

MERGE
  `analytics.dim_customer` c
USING
  (
    SELECT
      jsc.id AS user_id,
      jsc.first_name AS first_name,
      jsc.last_name AS last_name
    FROM
      `public.jaffle_shop_customer` jsc
  ) n
ON
  c.user_id = n.user_id
WHEN NOT MATCHED
THEN
  INSERT (
    user_id,
    name
  ) VALUES (
    CAST(n.user_id AS INTEGER),
    CONCAT(n.first_name, ' ', n.last_name)
  );

MERGE
  `analytics.dim_order` o
USING
  (
    SELECT
      jso.id AS order_id,
      jso.order_date,
      jso.status AS order_status
    FROM
      `public.jaffle_shop_order` jso
  ) n
ON
  o.order_id = n.order_id
WHEN NOT MATCHED
THEN
  INSERT (
    order_id,
    order_date,
    order_status
  ) VALUES (
    CAST(n.order_id AS INTEGER),
    n.order_date,
    n.order_status
  );

-- Answer the question

SELECT
  u.name,
  f.amount,
  f.payment_method,
  f.payment_status,
  f.order_id,
  o.order_status,
  o.order_date
FROM
  `analytics.fact_payment` f
JOIN
  `analytics.dim_customer` u
ON
  f.user_id = u.user_id
JOIN
  `analytics.dim_order` o
ON
  f.order_id = o.order_id
WHERE
  u.name = 'Kathleen P.'
  AND f.payment_method = 'credit_card'
ORDER BY
  o.order_date
DESC
