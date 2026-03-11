# Write your MySQL query statement below
WITH prep AS 
(
    SELECT 
        pp.user_id
        , pp.product_id
        , p.category
    FROM ProductPurchases pp
    INNER JOIN ProductInfo p
        ON p.product_id = pp.product_id
)
SELECT 
    pr1.category AS category1
    , pr2.category AS category2
    , COUNT(DISTINCT pr1.user_id) AS customer_count
FROM prep pr1 
INNER JOIN prep pr2 
    ON pr1.user_id = pr2.user_id
        AND pr1.category < pr2.category
GROUP BY 
    pr1.category
    , pr2.category
HAVING COUNT(DISTINCT pr1.user_id) >= 3 
ORDER BY 
    COUNT(DISTINCT pr1.user_id) DESC
    , pr1.category ASC
    , pr2.category ASC