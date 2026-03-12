CREATE FUNCTION getNthHighestSalary(N INT) RETURNS INT
BEGIN
  RETURN (
      # Write your MySQL query statement below.
    WITH res AS (
        SELECT DISTINCT
            salary
            , DENSE_RANK() OVER(ORDER BY salary DESC) AS rnn
        FROM Employee
    )
    SELECT 
        salary AS getNthHighestSalary
    FROM res
    WHERE rnn = N
  );
END