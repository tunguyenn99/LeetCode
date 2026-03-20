WITH exclude_non_secutive AS 
(
    SELECT 
        *
        , DATEDIFF(LAG(session_date) OVER(PARTITION BY student_id ORDER BY session_date), session_date) AS date_gap
        , ROW_NUMBER()
    FROM study_sessions 
)
, violate_date_gap AS
(
    SELECT 
        *
        , CASE 
            WHEN date_gap > 2 THEN 1
            ELSE 0 
        END AS date_gap_check
    FROM exclude_non_secutive
)
, validate AS
(
SELECT 
    *
    , SUM(date_gap_check) OVER(PARTITION BY student_id ORDER BY session_date) AS group_violate_date_gap  
FROM violate_date_gap 
GROUP BY student_id
HAVING SUM(date_gap_check) = 0
)
SELECT 
    *
FROM 