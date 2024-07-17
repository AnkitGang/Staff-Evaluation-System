drop table if exists Employees;
CREATE TABLE Employees(
	employee_id INT PRIMARY KEY,
	first_name VARCHAR(50),
	last_name VARCHAR(50),
	department_id INT,
	POSITION VARCHAR(50),
	hire_date DATE,
	salary DECIMAL(10, 2)
);


drop table if exists Departments;
CREATE TABLE Departments(
	department_id INT PRIMARY KEY,
	department_name VARCHAR(100)
);

drop table if exists Projects;
CREATE TABLE Projects(
	project_id INT PRIMARY KEY,
	project_name VARCHAR(100),
	start_date DATE,
	end_date DATE,
	STATUS VARCHAR(50)
);


drop table if exists Assignments;
CREATE TABLE Assignments(
	assignment_id INT PRIMARY KEY,
	employee_id INT REFERENCES Employees(employee_id),
	project_id INT REFERENCES Projects(project_id),
	ROLE VARCHAR(50),
	hours_worked INT
);


drop table if exists Attendance;
CREATE TABLE Attendance(
	attendance_id INT PRIMARY KEY,
	employee_id INT REFERENCES Employees(employee_id),
	DATE DATE,
	STATUS VARCHAR(50)
);


drop table if exists Performance_Reviews;
CREATE TABLE Performance_Reviews(
	review_id INT PRIMARY KEY,
	employee_id INT REFERENCES Employees(employee_id),
	review_date DATE,
	reviewer VARCHAR(50),
	score INT,
	comments TEXT
);


truncate Employees cascade;
copy Employees
from 'E:\My-Projects\EmployeePerformanceManagementSystem\Project Data\emp_details.csv'
delimiter ','
csv header;

select * from Employees;


truncate Departments;
copy Departments
from 'E:\My-Projects\EmployeePerformanceManagementSystem\Project Data\departments.csv'
delimiter ','
csv header;

select * from Departments;


truncate Projects cascade;
copy Projects
from 'E:\My-Projects\EmployeePerformanceManagementSystem\Project Data\projects_table.csv'
delimiter ','
csv header;

select * from Projects;


truncate table Assignments;
copy Assignments
from 'E:\My-Projects\EmployeePerformanceManagementSystem\Project Data\assignments_data.csv'
delimiter ','
csv header;

select * from Assignments;


truncate table Attendance;
copy Attendance
from 'E:\My-Projects\EmployeePerformanceManagementSystem\Project Data\attendance_report.csv'
delimiter ','
csv header;

select * from Attendance;


truncate table Performance_Reviews;
copy Performance_Reviews
from 'E:\My-Projects\EmployeePerformanceManagementSystem\Project Data\performance_review.csv'
delimiter ','
csv header;

select * from Performance_Reviews;



CREATE OR REPLACE FUNCTION CalculateBonus(salary NUMERIC(10,2), score INT)
RETURNS NUMERIC(10,2) AS $$ 
DECLARE 
	bonus NUMERIC(10,2);
BEGIN
	bonus = salary * (score / 100.0);
	RETURN bonus;
END;
$$ LANGUAGE plpgsql;

-- SELECT CalculateBonus(30033, 3);


DROP FUNCTION IF EXISTS SummarizeAttendance(INT,INT);
CREATE OR REPLACE FUNCTION SummarizeAttendance(a_month INT, a_year INT)
RETURNS TABLE (
	employee_id INT,
	first_name VARCHAR(50),
	last_name VARCHAR(50),
	days_present INT,
	days_absent INT,
	days_leave INT
) AS $$
BEGIN
	RETURN QUERY
	SELECT 
		e.employee_id,
		e.first_name,
		e.last_name,
		SUM(CASE WHEN a.status='Present' THEN 1 ELSE 0 END)::INT AS days_present,
		SUM(CASE WHEN a.status='Absent' THEN 1 ELSE 0 END)::INT AS days_absent,
		SUM(CASE WHEN a.status='Leave' THEN 1 ELSE 0 END)::INT AS days_leave
	FROM Employees e
	JOIN Attendance a 
	ON e.employee_id = a.employee_id
	WHERE EXTRACT(MONTH FROM a.date) = a_month AND EXTRACT(YEAR FROM a.date) = a_year
	GROUP BY e.employee_id, e.first_name, e.last_name;
END;
$$ LANGUAGE plpgsql;

CREATE INDEX idx_attendance_date ON Attendance(date);
CREATE INDEX idx_attendance_employee_id ON Attendance(employee_id);
CREATE INDEX idx_employees_employee_id ON Employees(employee_id);


DROP FUNCTION IF EXISTS AnnualPerformanceSummary(INT);
CREATE OR REPLACE FUNCTION AnnualPerformanceSummary(a_year INT)
RETURNS TABLE (
	employee_id INT,
	first_name VARCHAR(50),
	last_name VARCHAR(50),
	average_score NUMERIC(10,2),
	annual_bonus NUMERIC(10,2)
) AS $$
BEGIN
	RETURN QUERY
	SELECT
		e.employee_id,
		e.first_name,
		e.last_name,
		AVG(r.score)::NUMERIC(10,2) AS average_score,
		CalculateBonus(e.salary, AVG(r.score)::INT) AS annual_bonus
	FROM Employees e
	JOIN Performance_Reviews r
	ON e.employee_id = r.employee_id
	WHERE EXTRACT(YEAR FROM r.review_date) = a_year
	GROUP BY e.employee_id, e.first_name, e.last_name;
END;
$$ LANGUAGE plpgsql;

CREATE INDEX idx_performance_reviews_review_date ON Performance_Reviews(review_date);
CREATE INDEX idx_performance_reviews_employee_id ON Performance_Reviews(employee_id);


DROP FUNCTION IF EXISTS DepartmentPerformanceReport(INT);
CREATE OR REPLACE FUNCTION DepartmentPerformanceReport(a_year INT)
RETURNS TABLE (
	department_id INT,
	average_performance_score NUMERIC(10,2),
	total_bonus NUMERIC(10,2)
) AS $$
BEGIN
	RETURN QUERY
	SELECT 
		d.department_id,
		AVG(r.score)::NUMERIC(10,2) AS average_performance_score,
		SUM(CalculateBonus(e.salary, r.score)) AS total_bonus
	FROM Employees e
	JOIN Performance_Reviews r ON e.employee_id = r.employee_id
	JOIN Departments d ON d.department_id = e.department_id
	WHERE EXTRACT(YEAR FROM r.review_date) = a_year 
	GROUP BY d.department_id;
END;
$$ LANGUAGE plpgsql;

CREATE INDEX idx_employees_department_id ON Employees(department_id);
CREATE INDEX idx_departments_department_id ON Departments(department_id);


DROP VIEW IF EXISTS EmployeeProjectInvolvement;
CREATE OR REPLACE VIEW EmployeeProjectInvolvement AS
SELECT 
	e.employee_id,
	e.first_name,
	e.last_name,
	p.project_name,
	a.role,
	a.hours_worked
FROM Employees e
JOIN Assignments a ON e.employee_id = a.employee_id
JOIN Projects p ON a.project_id = p.project_id;

CREATE INDEX idx_assignments_employee_id ON Assignments(employee_id);
CREATE INDEX idx_assignments_project_id ON Assignments(project_id);
CREATE INDEX idx_projects_project_id ON Projects(project_id);


-- Queries
select * from SummarizeAttendance(5, 2023);
select * from AnnualPerformanceSummary(2024);
select * from DepartmentPerformanceReport(2024);
select * from EmployeeProjectInvolvement order by project_name,role,employee_id;


