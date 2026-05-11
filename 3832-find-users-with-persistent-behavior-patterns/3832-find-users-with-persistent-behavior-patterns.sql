# Write your MySQL query statement below
WITH rnk_tbl AS
(
    SELECT 
        *
        , ROW_NUMBER() OVER(PARTITION BY user_id, action ORDER BY action_date) AS rnk
    FROM activity
)
, rnk_key_tbl AS
(
    SELECT 
        *
        , DATE_SUB(action_date, interval rnk day) AS rnk_key
    FROM rnk_tbl
)
SELECT 
    user_id
    , action
    -- , rnk_key 
    , COUNT(1) AS streak_length
    , MIN(action_date) AS start_date
    , MAX(action_date) AS end_date 
FROM rnk_key_tbl
GROUP BY 
    user_id
    , action
    , rnk_key 
HAVING COUNT(1) >= 5
ORDER BY
    COUNT(1) DESC 
    , user_id ASC