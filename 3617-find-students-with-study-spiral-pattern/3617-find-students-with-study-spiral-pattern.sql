WITH OrderedSessions AS (
    -- Bước 1: Sắp xếp theo ngày, check khoảng cách ngày (gap)
    SELECT 
        student_id,
        subject,
        session_date,
        hours_studied,
        ROW_NUMBER() OVER(PARTITION BY student_id ORDER BY session_date) as rn,
        LAG(session_date) OVER(PARTITION BY student_id ORDER BY session_date) as prev_date
    FROM study_sessions
),
StudentStats AS (
    -- Bước 2: Tính độ dài chu kỳ (k) và tổng số buổi học của mỗi sinh viên
    -- k = tổng số môn học khác nhau mà sinh viên đó có
    SELECT 
        student_id,
        COUNT(DISTINCT subject) as k,
        COUNT(*) as total_sessions,
        SUM(hours_studied) as total_study_hours,
        MAX(DATEDIFF(session_date, COALESCE(prev_date, session_date))) as max_gap
    FROM OrderedSessions
    GROUP BY student_id
    HAVING k >= 3                     -- Điều kiện 1: Ít nhất 3 môn
       AND total_sessions >= k * 2    -- Điều kiện 2: Ít nhất 2 chu kỳ đầy đủ
       AND max_gap <= 2               -- Điều kiện 3: Không nghỉ quá 2 ngày
),
PatternValidation AS (
    -- Bước 4: Kiểm tra xem môn ở dòng i có khớp với dòng i+k không
    -- Đây là bước quan trọng nhất để xác nhận "thứ tự xoay vòng"
    SELECT 
        curr.student_id
    FROM OrderedSessions curr
    JOIN StudentStats stats ON curr.student_id = stats.student_id
    LEFT JOIN OrderedSessions next_cycle 
        ON curr.student_id = next_cycle.student_id 
        AND next_cycle.rn = curr.rn + stats.k
    WHERE curr.rn <= stats.total_sessions - stats.k -- Chỉ xét các dòng có dòng đối ứng ở chu kỳ sau
    GROUP BY curr.student_id, stats.k, stats.total_sessions
    -- Nếu số lượng dòng khớp (subject giống nhau) bằng đúng số lượng dòng cần kiểm tra
    HAVING SUM(CASE WHEN curr.subject = next_cycle.subject THEN 1 ELSE 0 END) = (stats.total_sessions - stats.k)
)
-- Kết quả cuối cùng
SELECT 
    s.student_id, 
    s.student_name, 
    s.major, 
    st.k as cycle_length, 
    st.total_study_hours
FROM students s
JOIN StudentStats st ON s.student_id = st.student_id
JOIN PatternValidation pv ON s.student_id = pv.student_id
ORDER BY cycle_length DESC, total_study_hours DESC;