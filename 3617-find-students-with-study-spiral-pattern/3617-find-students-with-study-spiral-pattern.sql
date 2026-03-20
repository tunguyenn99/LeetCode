WITH OrderedSessions AS (
    SELECT 
        student_id
        , subject
        , session_date
        , hours_studied
        , ROW_NUMBER() OVER(PARTITION BY student_id ORDER BY session_date) as rn
        , LAG(session_date) OVER(PARTITION BY student_id ORDER BY session_date) as prev_date
    FROM study_sessions
)
, GapFilter AS (
    -- Loại ngay sinh viên sủi học = nghỉ quá 2 ngày
    SELECT student_id
    FROM OrderedSessions
    GROUP BY student_id
    HAVING MAX(DATEDIFF(session_date, COALESCE(prev_date, session_date))) <= 2
)
, PossibleCycles AS (
    -- Tìm khoảng cách k giữa 2 lần xuất hiện cùng 1 môn
    -- k = rn của lần xuất hiện thứ 2 TRỪ rn của lần xuất hiện thứ 1
    SELECT 
        s1.student_id
        , (s2.rn - s1.rn) as k
        , s1.rn as start_rn
    FROM OrderedSessions s1
    JOIN OrderedSessions s2 ON s1.student_id = s2.student_id 
        AND s1.subject = s2.subject 
        AND s2.rn > s1.rn
    WHERE s1.rn = 1 -- Giả định chu kỳ bắt đầu từ buổi đầu tiên
)
, ValidatedPatterns AS (
    -- Kiểm tra xem k này có đúng cho toàn bộ chuỗi không
    SELECT 
        p.student_id
        , p.k as cycle_length
    FROM PossibleCycles p
    JOIN OrderedSessions o ON p.student_id = o.student_id
    JOIN OrderedSessions o2 ON o.student_id = o2.student_id 
        AND o2.rn = o.rn + p.k
    WHERE p.k >= 3
    GROUP BY p.student_id, p.k
    HAVING COUNT(*) >= p.k -- Ít nhất lặp lại đủ 1 vòng nữa (tổng 2 vòng)
       AND SUM(CASE WHEN o.subject = o2.subject THEN 1 ELSE 0 END) = COUNT(*)
)
-- Kết quả cuối cùng
SELECT 
    s.student_id
    , s.student_name
    , s.major
    , v.cycle_length
    , SUM(os.hours_studied) as total_study_hours
FROM students s
JOIN ValidatedPatterns v ON s.student_id = v.student_id
JOIN OrderedSessions os ON s.student_id = os.student_id
JOIN GapFilter gf ON s.student_id = gf.student_id
GROUP BY s.student_id, s.student_name, s.major, v.cycle_length
ORDER BY v.cycle_length DESC, total_study_hours DESC;