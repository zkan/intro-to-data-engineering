WITH stg_order_with_payment AS (
  SELECT
    jso.user_id,
    sp.amount,
    sp.status AS payment_status,
    sp.orderid AS order_id,
    jso.status AS order_status,
    sp.paymentmethod AS payment_method,
    jso.order_date
  FROM
    `public.stripe_payment` sp
  JOIN
    `public.jaffle_shop_order` jso
  ON
    sp.orderid = jso.id
),

stg_customer_with_order AS (
  SELECT
    CONCAT(jsc.first_name, ' ', jsc.last_name) AS name,
    stg_order_with_payment.amount,
    stg_order_with_payment.payment_status,
    stg_order_with_payment.order_id,
    stg_order_with_payment.order_status,
    stg_order_with_payment.payment_method,
    stg_order_with_payment.order_date
  FROM
    stg_order_with_payment
  JOIN
    `public.jaffle_shop_customer` jsc
  ON
    stg_order_with_payment.user_id = jsc.id
)

SELECT
  name,
  amount,
  payment_method,
  payment_status,
  order_id,
  order_status,
  order_date
FROM
  stg_customer_with_order
WHERE
  payment_method = 'credit_card'
  AND name = 'Kathleen P.'
ORDER BY
  order_date
DESC
