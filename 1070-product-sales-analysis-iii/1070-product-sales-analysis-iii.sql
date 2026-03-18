# Write your MySQL query statement below
WITH min_year_by_product AS
(
    SELECT 
        product_id 
        , min(year) as min_year
    FROM Sales
    GROUP BY product_id
)
SELECT 
    s.product_id
    , s.year as first_year 
    , s.quantity
    , s.price
FROM Sales s
INNER JOIN min_year_by_product p ON p.product_id = s.product_id
    AND p.min_year = s.year