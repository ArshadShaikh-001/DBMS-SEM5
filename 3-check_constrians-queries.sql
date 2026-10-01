-- queries 


-- STEP 4, QUERY 0: View - cost of each material in each room
CREATE OR REPLACE VIEW college_project.v_room_material_cost AS
SELECT  r.project_id,
        rm.room_id,
        r.room_type,
        m.material_id,
        m.material_name,
        m.unit,
        rm.quantity_used,
        m.unit_cost,
        rm.quantity_used * m.unit_cost AS total_cost
FROM    college_project.Room_Material rm
JOIN    college_project.Room     r ON r.room_id     = rm.room_id
JOIN    college_project.Material m ON m.material_id = rm.material_id;

-- STEP 4, QUERY 0: check the view
SELECT * FROM college_project.v_room_material_cost
ORDER BY project_id, room_id;


-- STEP 4, QUERY 1: Projects with customer name (JOIN Project + Customer)
SELECT  p.project_id, p.project_name, p.project_type, p.status,
        c.customer_name, c.phone_no, p.budget
FROM    college_project.Project p
JOIN    college_project.Customer c ON c.username = p.username
ORDER BY p.project_id;


-- STEP 4, QUERY 2: Rooms of each project with area (JOIN Room + Project)
SELECT  p.project_name, r.room_id, r.room_type,
        r.length, r.breadth, r.height, r.area
FROM    college_project.Room r
JOIN    college_project.Project p ON p.project_id = r.project_id
ORDER BY p.project_id, r.room_id;

-- STEP 4, QUERY 3: Estimate vs budget (JOIN Project + Estimate)
SELECT  p.project_name, p.budget, e.total_cost AS estimated_cost,
        p.budget - e.total_cost AS budget_left,
        CASE WHEN e.total_cost <= p.budget THEN 'Within budget'
             ELSE 'Over budget' END AS budget_status
FROM    college_project.Project p
JOIN    college_project.Estimate e ON e.project_id = p.project_id
ORDER BY p.project_id;

-- STEP 4, QUERY 4: Paid so far and balance due (JOIN Estimate + Project + Customer + Payment)
SELECT  p.project_name, c.customer_name,
        e.total_cost                                AS estimate_total,
        COALESCE(SUM(pay.amount), 0)                AS total_paid,
        e.total_cost - COALESCE(SUM(pay.amount), 0) AS balance_due
FROM    college_project.Estimate e
JOIN    college_project.Project  p ON p.project_id = e.project_id
JOIN    college_project.Customer c ON c.username   = p.username
LEFT JOIN college_project.Payment pay ON pay.estimate_id = e.estimate_id
GROUP BY e.estimate_id, p.project_name, c.customer_name, e.total_cost
ORDER BY p.project_name;

-- STEP 4, QUERY 5: Payment history (JOIN Payment + Estimate + Project + Customer)
SELECT  pay.payment_id, c.customer_name, p.project_name,
        pay.amount, pay.payment_mode, pay.transaction_id, pay.payment_date
FROM    college_project.Payment pay
JOIN    college_project.Estimate e ON e.estimate_id = pay.estimate_id
JOIN    college_project.Project  p ON p.project_id  = e.project_id
JOIN    college_project.Customer c ON c.username    = p.username
ORDER BY pay.payment_date;


-- STEP 4, QUERY 6: Employees on each project (JOIN Project_Employee + Project + Employee)
SELECT  p.project_name, emp.emp_name, emp.designation,
        pe.role_in_project, pe.assigned_date
FROM    college_project.Project_Employee pe
JOIN    college_project.Project  p   ON p.project_id = pe.project_id
JOIN    college_project.Employee emp ON emp.emp_id   = pe.emp_id
ORDER BY p.project_id, emp.emp_name;

-- STEP 4, QUERY 7: Material cost per project (uses view v_room_material_cost)
SELECT  p.project_id, p.project_name,
        SUM(v.total_cost) AS material_cost_from_rooms,
        e.material_cost   AS material_cost_in_estimate
FROM    college_project.Project p
JOIN    college_project.v_room_material_cost v ON v.project_id = p.project_id
JOIN    college_project.Estimate e             ON e.project_id = p.project_id
GROUP BY p.project_id, p.project_name, e.material_cost
ORDER BY p.project_id;

-- STEP 4, QUERY 8: Projects and total budget per customer (LEFT JOIN Customer + Project)
SELECT  c.customer_name, c.role,
        COUNT(p.project_id)        AS projects,
        COALESCE(SUM(p.budget), 0) AS total_budget
FROM    college_project.Customer c
LEFT JOIN college_project.Project p ON p.username = c.username
GROUP BY c.username, c.customer_name, c.role
ORDER BY projects DESC, c.customer_name;

-- STEP 4, QUERY 9: Low-stock materials (150 or fewer left)
SELECT material_id, material_name, brand, unit, quantity
FROM   college_project.Material
WHERE  quantity <= 150
ORDER BY quantity;

