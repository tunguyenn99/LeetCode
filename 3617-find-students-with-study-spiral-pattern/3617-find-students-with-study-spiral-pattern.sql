WITH ordered_sessions AS (
    SELECT 
        student_id
        , subject
        , session_date
        , hours_studied
        , ROW_NUMBER() OVER(PARTITION BY student_id ORDER BY session_date) as row_num
        , LAG(session_date) OVER(PARTITION BY student_id ORDER BY session_date) as previous_date
    FROM study_sessions
)
, gap_filter AS (
    -- Kiểm tra điều kiện nghỉ không quá 2 ngày
    SELECT student_id
    FROM ordered_sessions
    GROUP BY student_id
    HAVING MAX(DATEDIFF(session_date, COALESCE(previous_date, session_date))) <= 2
)
, student_cycle_info AS (
    -- Tự động tìm k (số môn học duy nhất) của từng sinh viên
    SELECT 
        student_id
        , COUNT(DISTINCT subject) as k_length
        , COUNT(*) as total_count
        , SUM(hours_studied) as total_hours
    FROM ordered_sessions
    GROUP BY student_id
    HAVING COUNT(DISTINCT subject) >= 3
       AND COUNT(*) >= COUNT(DISTINCT subject) * 2
)
, pattern_validation AS (
    -- Kiểm tra tính xoay vòng: môn ở dòng i phải khớp với dòng i + k
    SELECT 
        curr.student_id
    FROM ordered_sessions curr
    JOIN student_cycle_info info ON curr.student_id = info.student_id
    LEFT JOIN ordered_sessions next_cycle 
        ON curr.student_id = next_cycle.student_id 
        AND next_cycle.row_num = curr.row_num + info.k_length
    WHERE curr.row_num <= info.total_count - info.k_length
    GROUP BY curr.student_id, info.k_length, info.total_count
    HAVING SUM(CASE WHEN curr.subject = next_cycle.subject THEN 1 ELSE 0 END) = (info.total_count - info.k_length)
)
-- Kết quả cuối cùng theo đúng yêu cầu sắp xếp
SELECT 
    s.student_id
    , s.student_name
    , s.major
    , sci.k_length as cycle_length
    , sci.total_hours as total_study_hours
FROM students s
JOIN student_cycle_info sci ON s.student_id = sci.student_id
JOIN pattern_validation pv ON s.student_id = pv.student_id
JOIN gap_filter gf ON s.student_id = gf.student_id
ORDER BY cycle_length DESC, total_study_hours DESC;