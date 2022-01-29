SELECT
  CONCAT(first_name, ' ', last_name) AS name,
  amount,
  paymentmethod AS payment_method,
  sp.status AS payment_status,
  orderid AS order_id,
  jso.status AS order_status,
  order_date
FROM
  `public.stripe_payment` sp
JOIN
  `public.jaffle_shop_order` jso
ON
  sp.orderid = jso.id
JOIN
  `public.jaffle_shop_customer` jsc
ON
  jso.user_id = jsc.id
WHERE
  sp.paymentmethod = 'credit_card'
  AND jsc.first_name = 'Kathleen'
  AND jsc.last_name = 'P.'
ORDER BY
  order_date
DESC