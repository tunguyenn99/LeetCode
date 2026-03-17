# Write your MySQL query statement below
WITH prep AS 
(
    SELECT 
        *
        , DATEDIFF('2019-08-16', change_date) AS DIFF
    FROM Products
    WHERE DATEDIFF('2019-08-16', change_date) >= 0
)
, rn_imp AS 
(
    SELECT 
        *
        , ROW_NUMBER() OVER(PARTITION BY product_id ORDER BY DIFF ASC) AS RNN
    FROM prep
)
SELECT DISTINCT
    p.product_id 
    , COALESCE(r.new_price, 10) as price
FROM Products p 
LEFT JOIN rn_imp r ON r.product_id = p.product_id
WHERE RNN = 1 OR RNN IS NULL 