Create or Replace Package hr_analytics
IS

--Functions
Function months_with_comp(p_employee_id hr.job_history.employee_id%TYPE) 
Return Number;

Function salary_growth(p_employee_id hr.job_history.employee_id%TYPE) 
Return Number;

Function turnover_risk(p_employee_id hr.job_history.employee_id%TYPE) 
Return Number;

Function job_history(p_employee_id hr.job_history.employee_id%TYPE) 
Return Number;

--Procedures
Procedure calculate_all_turnover_risk;
Procedure department_analytics_report;

END hr_analytics;
/

Create or Replace PACKAGE BODY hr_analytics
IS

---Function(1): Months_with_comp

Function months_with_comp(
p_employee_id hr.job_history.employee_Id%type
)
RETURN NUMBER
IS
p_month NUMBER;

BEGIN
Select SUM(months_between (end_DATE,start_date))
Into p_month
From hr.job_history
where employee_id = p_employee_Id;

Return p_month;
END months_with_comp;

---Function(2): job_history
Function job_history(
p_employee_id hr.job_history.employee_Id%type
)
RETURN NUMBER
IS

p_num NUMBER;

BEGIN
SELECT count(employee_id)
Into p_num
from hr.job_history
where employee_id = p_employee_id;

RETURN p_num;
END job_history;

-- Function (3) : salary_growth

FUNCTION salary_growth(
p_employee_id hr.job_history.employee_Id%type
)
RETURN NUMBER
IS
p_dept_avg Number;
p_salary Number;


BEGIN
Select avg(salary) 
Into p_dept_avg
From hr.employees
Where department_id = (
Select department_id
from hr.employees
where employee_id = p_employee_id
);


Select salary
Into p_salary
From hr.employees
Where employee_id = p_employee_Id;

IF p_salary > p_dept_avg THEN
RETURN 1; -- Higher than department average
ELSE
RETURN 0; -- lower than department average
END IF;

END salary_growth;

-- Function (4) : turnover_risk
Function Turnover_risk(
p_employee_id hr.job_history.employee_Id%type
)
RETURN Number
IS
p_salary NUMBER;
p_months NUMBER;
p_promotion NUMBER;
p_risk Number;

BEGIN

p_risk:= 0;
--Promotions
Select job_history(p_employee_id)
into p_promotion
from dual;

--Salary
Select salary_growth(p_employee_id)
into p_salary
from dual;

--Years
Select months_with_comp(p_employee_id)
into p_months
from dual;

IF p_months> 60 and  p_promotion = 1 THEN
p_risk:= p_risk + 30;
END IF;

IF p_salary = 0 THEN
p_risk:= p_risk + 30;
END IF;

IF p_months > 74 THEN
p_risk:= p_risk + 20;
END IF;

IF p_promotion = 1 THEN
p_risk:= p_risk + 20;
END IF;

RETURN p_risk;
END;

-- Procedure (1): calculate_all_turnover_risk
PROCEDURE calculate_all_turnover_risk
IS
v_risk_score Number;
v_risk_level VARCHAR2(20);

BEGIN
FOR emp in (
Select *
From Hr.employees
)Loop

--- Risk Score
Select Turnover_risk(emp.employee_id)
into v_risk_score
From dual;
 
-- Risk level
IF  v_risk_score >= 70 THEN
v_risk_level := 'High';
ELSIF v_risk_score >= 40 THEN
v_risk_level := 'Medium';
else
v_risk_level := 'Low';
end if;

--Insert into table
INSERT INTO hr.turnover_predictions (
employee_id,
risk_score,
risk_level,
calculated_on
        )
        VALUES (
emp.employee_id,
v_risk_score,
v_risk_level,
SYSDATE
        );
        
        End Loop;
        
        commit;
END;

--Procedure (2): department_analytics_report
Procedure department_analytics_report
IS
BEGIN
For dept IN (
Select department_id, department_name 
from hr.departments) LOOP


DECLARE
v_headcount   NUMBER;
v_avg_salary  NUMBER;
v_high_salary NUMBER;
v_low_salary  NUMBER;
v_avg_tenure  NUMBER;
v_high_risk   NUMBER;
BEGIN
-- total no of employees
Select Count(*)
into v_headcount
From hr.employees
Where department_id = dept.department_id;

-- Salary metrics
Select AVG(salary), MAX(salary), MIN(salary)
into v_avg_salary, v_high_salary, v_low_salary
From hr.employees
Where department_id = dept.department_id;

 -- Average tenure
SELECT Round(AVG(months_with_comp(employee_id)))
into v_avg_tenure
From hr.employees
Where department_id = dept.department_id;

 -- High-risk employees 
SELECT Count(*)
Into v_high_risk
from hr.employees e
Join hr.turnover_predictions t
ON e.employee_id = t.employee_id
Where e.department_id = dept.department_id
and t.risk_score >= 70;

            
DBMS_OUTPUT.PUT_LINE('Department: ' || dept.department_name);
DBMS_OUTPUT.PUT_LINE('Total Number of employees: ' || v_headcount);
DBMS_OUTPUT.PUT_LINE('Average Salary: ' || v_avg_salary);
DBMS_OUTPUT.PUT_LINE('Highest Salary: ' || v_high_salary);
DBMS_OUTPUT.PUT_LINE('Lowest Salary: ' || v_low_salary);
DBMS_OUTPUT.PUT_LINE('Average Tenure in months: ' || v_avg_tenure);
DBMS_OUTPUT.PUT_LINE('High risk Employees: ' || v_high_risk);
DBMS_OUTPUT.PUT_LINE('-----------------------------');
        END;
    END LOOP;
END;

END hr_analytics;
/




Create or Replace PACKAGE BODY hr_analytics
IS

---Function(1): Months_with_comp

Function months_with_comp(
p_employee_id hr.job_history.employee_Id%type
)
RETURN NUMBER
IS
p_month NUMBER;

BEGIN
Select SUM(months_between (end_DATE,start_date))
Into p_month
From hr.job_history
where employee_id = p_employee_Id;

Return p_month;
END months_with_comp;

---Function(2): job_history
Function job_history(
p_employee_id hr.job_history.employee_Id%type
)
RETURN NUMBER
IS

p_num NUMBER;

BEGIN
SELECT count(employee_id)
Into p_num
from hr.job_history
where employee_id = p_employee_id;

RETURN p_num;
END job_history;

-- Function (3) : salary_growth

FUNCTION salary_growth(
p_employee_id hr.job_history.employee_Id%type
)
RETURN NUMBER
IS
p_dept_avg Number;
p_salary Number;


BEGIN
Select avg(salary) 
Into p_dept_avg
From hr.employees
Where department_id = (
Select department_id
from hr.employees
where employee_id = p_employee_id
);


Select salary
Into p_salary
From hr.employees
Where employee_id = p_employee_Id;

IF p_salary > p_dept_avg THEN
RETURN 1; -- Higher than department average
ELSE
RETURN 0; -- lower than department average
END IF;

END salary_growth;

-- Function (4) : turnover_risk
Function Turnover_risk(
p_employee_id hr.job_history.employee_Id%type
)
RETURN Number
IS
p_salary NUMBER;
p_months NUMBER;
p_promotion NUMBER;
p_risk Number;

BEGIN

p_risk:= 0;
--Promotions
Select job_history(p_employee_id)
into p_promotion
from dual;

--Salary
Select salary_growth(p_employee_id)
into p_salary
from dual;

--Years
Select months_with_comp(p_employee_id)
into p_months
from dual;

IF p_months> 60 and  p_promotion = 1 THEN
p_risk:= p_risk + 30;
END IF;

IF p_salary = 0 THEN
p_risk:= p_risk + 30;
END IF;

IF p_months > 74 THEN
p_risk:= p_risk + 20;
END IF;

IF p_promotion = 1 THEN
p_risk:= p_risk + 20;
END IF;

RETURN p_risk;
END;

-- Procedure (1): calculate_all_turnover_risk
PROCEDURE calculate_all_turnover_risk
IS
v_risk_score Number;
v_risk_level VARCHAR2(20);

BEGIN
FOR emp in (
Select *
From Hr.employees
)Loop

--- Risk Score
Select Turnover_risk(emp.employee_id)
into v_risk_score
From dual;
 
-- Risk level
IF  v_risk_score >= 70 THEN
v_risk_level := 'High';
ELSIF v_risk_score >= 40 THEN
v_risk_level := 'Medium';
else
v_risk_level := 'Low';
end if;

--Insert into table
INSERT INTO hr.turnover_predictions (
employee_id,
risk_score,
risk_level,
calculated_on
        )
        VALUES (
emp.employee_id,
v_risk_score,
v_risk_level,
SYSDATE
        );
        
        End Loop;
        
        commit;
END;

--Procedure (2): department_analytics_report
Procedure department_analytics_report
IS
BEGIN
For dept IN (
Select department_id, department_name 
from hr.departments) LOOP


DECLARE
v_headcount   NUMBER;
v_avg_salary  NUMBER;
v_high_salary NUMBER;
v_low_salary  NUMBER;
v_avg_tenure  NUMBER;
v_high_risk   NUMBER;
BEGIN
-- total no of employees
Select Count(*)
into v_headcount
From hr.employees
Where department_id = dept.department_id;

-- Salary metrics
Select AVG(salary), MAX(salary), MIN(salary)
into v_avg_salary, v_high_salary, v_low_salary
From hr.employees
Where department_id = dept.department_id;

 -- Average tenure
SELECT Round(AVG(months_with_comp(employee_id)))
into v_avg_tenure
From hr.employees
Where department_id = dept.department_id;

 -- High-risk employees 
SELECT Count(*)
Into v_high_risk
from hr.employees e
Join hr.turnover_predictions t
ON e.employee_id = t.employee_id
Where e.department_id = dept.department_id
and t.risk_score >= 70;

            
DBMS_OUTPUT.PUT_LINE('Department: ' || dept.department_name);
DBMS_OUTPUT.PUT_LINE('Total Number of employees: ' || v_headcount);
DBMS_OUTPUT.PUT_LINE('Average Salary: ' || v_avg_salary);
DBMS_OUTPUT.PUT_LINE('Highest Salary: ' || v_high_salary);
DBMS_OUTPUT.PUT_LINE('Lowest Salary: ' || v_low_salary);
DBMS_OUTPUT.PUT_LINE('Average Tenure in months: ' || v_avg_tenure);
DBMS_OUTPUT.PUT_LINE('High risk Employees: ' || v_high_risk);
DBMS_OUTPUT.PUT_LINE('-----------------------------');
        END;
    END LOOP;
END;

END hr_analytics;
/


