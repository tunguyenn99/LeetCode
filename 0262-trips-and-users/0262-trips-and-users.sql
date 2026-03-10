# Write your MySQL query statement below
WITH prep AS 
(
    SELECT 
        t.id
        , t.status 
        , t.request_at
    FROM Trips t
    INNER JOIN Users u1 
        ON t.client_id = u1.users_id 
            AND u1.role = 'client'
            AND u1.banned = 'No'
    INNER JOIN Users u2 
        ON t.driver_id = u2.users_id 
            AND u2.role = 'driver'
            AND u2.banned = 'No'
    WHERE t.request_at BETWEEN '2013-10-01' AND '2013-10-03'            
)
SELECT 
    request_at AS "Day"
    , ROUND( 1.00 * COUNT(CASE WHEN status != 'completed' THEN id END) / COUNT(id) , 2) AS "Cancellation Rate"
FROM prep
GROUP BY request_at
ORDER BY request_at