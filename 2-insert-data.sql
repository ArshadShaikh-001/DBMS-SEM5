INSERT INTO college_project.Customer
    (username, password, customer_name, phone_no, email, role) VALUES
('admin_ava',      'hash_admin_001', 'AVA Admin',      '9800000001', 'admin@ava.com',           'admin'),
('rahul_sharma',   'hash_cust_002',  'Rahul Sharma',   '9800000002', 'rahul.sharma@mail.com',   'customer'),
('priya_patil',    'hash_cust_003',  'Priya Patil',    '9800000003', 'priya.patil@mail.com',    'customer'),
('amit_desai',     'hash_cust_004',  'Amit Desai',     '9800000004', 'amit.desai@mail.com',     'customer'),
('sneha_kulkarni', 'hash_cust_005',  'Sneha Kulkarni', '9800000005', 'sneha.kulkarni@mail.com', 'customer'),
('vikram_joshi',   'hash_cust_006',  'Vikram Joshi',   '9800000006', 'vikram.joshi@mail.com',   'customer');

SELECT username, customer_name, phone_no, email, role FROM college_project.Customer;

SELECT COUNT(*) AS project_rows FROM college_project.Project;

INSERT INTO college_project.Project
    (username, project_name, project_type, budget, start_date, end_date, status) VALUES
('rahul_sharma',   '2BHK Flat Construction',    'Residential', 300000.00,  '2026-03-01', '2026-06-15', 'Completed'),
('priya_patil',    'Office Building Fit-out',   'Commercial',  1000000.00, '2026-05-10', '2026-12-20', 'In Progress'),
('amit_desai',     'Bathroom Renovation',       'Renovation',  180000.00,  '2026-08-15', '2026-11-30', 'In Progress'),
('sneha_kulkarni', 'Modern Living Room Design', 'Interior',    350000.00,  '2026-11-01', NULL,         'Planned'),
('vikram_joshi',   'Kitchen Extension',         'Residential', 220000.00,  '2026-08-01', '2026-08-30', 'Cancelled');


SELECT p.project_id, p.project_name, p.project_type, p.budget, p.status, c.customer_name
FROM college_project.Project p
JOIN college_project.Customer c ON c.username = p.username;

-- TABLE 3: Room (check before insert)
SELECT COUNT(*) AS room_rows FROM college_project.Room;
SELECT MIN(project_id) AS first_id, MAX(project_id) AS last_id FROM college_project.Project;

-- TABLE 3: Room
-- Do NOT insert 'area'. MySQL calculates it as length * breadth.
INSERT INTO college_project.Room
    (project_id, room_type, length, breadth, height) VALUES
(1, 'Bedroom',     12.00, 11.00, 10.00),
(1, 'Living Room', 18.00, 14.00, 10.00),
(1, 'Kitchen',     10.00,  9.00, 10.00),
(2, 'Office',      30.00, 20.00, 12.00),
(2, 'Hall',        40.00, 25.00, 14.00),
(3, 'Bathroom',     8.00,  6.00,  9.00),
(3, 'Bedroom',     14.00, 12.00, 10.00),
(4, 'Living Room', 16.00, 13.00, 10.00),
(4, 'Dining Room', 12.00, 10.00, 10.00),
(5, 'Kitchen',     11.00, 10.00, 10.00);

-- TABLE 3: Room (check after insert)
SELECT r.room_id, p.project_name, r.room_type, r.length, r.breadth, r.height, r.area
FROM college_project.Room r
JOIN college_project.Project p ON p.project_id = r.project_id
ORDER BY r.room_id;


-- TABLE 4: Material (check before insert)
SELECT COUNT(*) AS material_rows FROM college_project.Material;

-- TABLE 4: Material
-- quantity = stock available in the store
INSERT INTO college_project.Material
    (material_name, brand, unit, quantity, unit_cost) VALUES
('Cement',                'UltraTech',    'bag',    500,   380.00),
('Steel Rod 12mm',        'Tata Tiscon',  'kg',     2000,   68.00),
('Floor Tile 2x2',        'Kajaria',      'sqft',   5000,   55.00),
('Wall Paint',            'Asian Paints', 'litre',  300,   420.00),
('Plywood 19mm',          'Greenply',     'sheet',  150,  1800.00),
('Red Brick',             'Local Kiln',   'piece',  20000,   9.00),
('River Sand',            'Generic',      'tonne',  100,  1500.00),
('Electrical Wire 2.5mm', 'Havells',      'metre',  3000,   22.00),
('Sanitary Ware Set',     'Jaquar',       'set',    40,   9500.00),
('LED Panel Light',       'Philips',      'piece',  200,   650.00);
-- TABLE 4: Material (check after insert)
SELECT material_id, material_name, brand, unit, quantity, unit_cost
FROM college_project.Material
ORDER BY material_id;


-- TABLE 5: Room_Material (check before insert)
SELECT COUNT(*) AS room_material_rows FROM college_project.Room_Material;
SELECT MIN(room_id) AS first_room, MAX(room_id) AS last_room FROM college_project.Room;
SELECT MIN(material_id) AS first_material, MAX(material_id) AS last_material FROM college_project.Material;

-- TABLE 5: Room_Material  (room_id, material_id, quantity_used)
INSERT INTO college_project.Room_Material
    (room_id, material_id, quantity_used) VALUES
-- Room 1 (Bedroom, Project 1)
(1, 3, 132), (1, 4, 6),   (1, 8, 40),
-- Room 2 (Living Room, Project 1)
(2, 3, 252), (2, 4, 10),  (2, 10, 6),
-- Room 3 (Kitchen, Project 1)
(3, 3, 90),  (3, 4, 3),   (3, 8, 25),
-- Room 4 (Office, Project 2)
(4, 3, 600), (4, 10, 20),
-- Room 5 (Hall, Project 2)
(5, 3, 1000),(5, 10, 30), (5, 1, 60),
-- Room 6 (Bathroom, Project 3)
(6, 9, 1),   (6, 3, 48),
-- Room 7 (Bedroom, Project 3)
(7, 4, 5),   (7, 5, 4),
-- Room 8 (Living Room, Project 4)
(8, 5, 10),  (8, 10, 8),
-- Room 9 (Dining Room, Project 4)
(9, 5, 6),   (9, 4, 4),
-- Room 10 (Kitchen, Project 5)
(10, 3, 110),(10, 1, 10);

-- TABLE 5: Room_Material (check after insert)
SELECT rm.room_id, r.room_type, p.project_name,
       m.material_name, rm.quantity_used, m.unit,
       rm.quantity_used * m.unit_cost AS cost
FROM college_project.Room_Material rm
JOIN college_project.Room     r ON r.room_id     = rm.room_id
JOIN college_project.Project  p ON p.project_id  = r.project_id
JOIN college_project.Material m ON m.material_id = rm.material_id
ORDER BY rm.room_id, m.material_id;


-- TABLE 6: Estimate (check before insert)
SELECT COUNT(*) AS estimate_rows FROM college_project.Estimate;
SELECT MIN(project_id) AS first_project, MAX(project_id) AS last_project FROM college_project.Project;

-- TABLE 6: Estimate
-- Do NOT insert 'total_cost'. MySQL calculates it as material + labor + other.
INSERT INTO college_project.Estimate
    (project_id, material_cost, labor_cost, other_cost) VALUES
(1, 150000.00,  80000.00, 20000.00),
(2, 600000.00, 300000.00, 50000.00),
(3,  90000.00,  60000.00, 10000.00),
(4, 200000.00,  90000.00, 15000.00),
(5, 120000.00,  70000.00, 10000.00);

-- TABLE 6: Estimate (check after insert)
SELECT e.estimate_id, p.project_name, p.budget,
       e.material_cost, e.labor_cost, e.other_cost, e.total_cost
FROM college_project.Estimate e
JOIN college_project.Project p ON p.project_id = e.project_id
ORDER BY e.estimate_id;


-- TABLE 7: Payment (check before insert)
SELECT COUNT(*) AS payment_rows FROM college_project.Payment;
SELECT MIN(estimate_id) AS first_estimate, MAX(estimate_id) AS last_estimate FROM college_project.Estimate;

-- TABLE 7: Payment
-- Rule: every non-Cash payment needs a transaction_id. Cash uses NULL.
INSERT INTO college_project.Payment
    (estimate_id, amount, payment_mode, transaction_id, payment_date) VALUES
(1, 100000.00, 'UPI',         'UPI2026030112345',  '2026-03-02 10:15:00'),
(1, 100000.00, 'Net Banking', 'NB2026041500987',   '2026-04-15 14:30:00'),
(1,  50000.00, 'Cheque',      'CHQ000451',         '2026-06-10 11:00:00'),
(2, 300000.00, 'Net Banking', 'NB2026051100321',   '2026-05-11 09:45:00'),
(2, 200000.00, 'Card',        'CARD2026072200456', '2026-07-22 16:20:00'),
(3,  50000.00, 'Cash',         NULL,               '2026-08-16 12:00:00'),
(3,  30000.00, 'UPI',         'UPI2026091000789',  '2026-09-10 18:05:00'),
(4,  75000.00, 'UPI',         'UPI2026092800654',  '2026-09-28 10:30:00');

-- TABLE 7: Payment (check after insert)
SELECT pay.payment_id, c.customer_name, p.project_name,
       pay.amount, pay.payment_mode, pay.transaction_id, pay.payment_date
FROM college_project.Payment pay
JOIN college_project.Estimate e ON e.estimate_id = pay.estimate_id
JOIN college_project.Project  p ON p.project_id  = e.project_id
JOIN college_project.Customer c ON c.username    = p.username
ORDER BY pay.payment_id;



-- TABLE 8: Employee
-- is_active: TRUE = working, FALSE = no longer working
INSERT INTO college_project.Employee
    (emp_name, phone_no, email, designation, is_active) VALUES
('Suresh Kale',   '9700000001', 'suresh.kale@ava.com',   'Site Engineer',     TRUE),
('Ganesh More',   '9700000002', 'ganesh.more@ava.com',   'Carpenter',         TRUE),
('Ramesh Pawar',  '9700000003', 'ramesh.pawar@ava.com',  'Electrician',       TRUE),
('Mahesh Jadhav', '9700000004', 'mahesh.jadhav@ava.com', 'Plumber',           TRUE),
('Anita Shinde',  '9700000005', 'anita.shinde@ava.com',  'Interior Designer', TRUE),
('Deepak Nikam',  '9700000006', 'deepak.nikam@ava.com',  'Mason',             FALSE);

-- TABLE 8: Employee (check after insert)
SELECT emp_id, emp_name, phone_no, email, designation, is_active
FROM college_project.Employee
ORDER BY emp_id;

-- TABLE 9: Project_Employee  (project_id, emp_id, role_in_project, assigned_date)
INSERT INTO college_project.Project_Employee
    (project_id, emp_id, role_in_project, assigned_date) VALUES
-- Project 1: 2BHK Flat Construction
(1, 1, 'Site Engineer',      '2026-03-01'),
(1, 6, 'Mason',              '2026-03-01'),
(1, 3, 'Electrician',        '2026-04-10'),
-- Project 2: Office Building Fit-out
(2, 1, 'Site Engineer',      '2026-05-10'),
(2, 3, 'Electrician',        '2026-06-01'),
(2, 2, 'Carpenter',          '2026-06-15'),
-- Project 3: Bathroom Renovation
(3, 4, 'Plumber',            '2026-08-15'),
(3, 6, 'Mason',              '2026-08-16'),
-- Project 4: Modern Living Room Design
(4, 5, 'Interior Designer',  '2026-10-20'),
(4, 2, 'Carpenter',          '2026-10-25');

-- TABLE 9: Project_Employee (check after insert)
SELECT p.project_name, e.emp_name, e.designation,
       pe.role_in_project, pe.assigned_date
FROM college_project.Project_Employee pe
JOIN college_project.Project  p ON p.project_id = pe.project_id
JOIN college_project.Employee e ON e.emp_id     = pe.emp_id
ORDER BY p.project_id, e.emp_name;




-- FINAL CHECK: row count of every table
SELECT 'Customer' AS table_name, COUNT(*) AS rows_inserted FROM college_project.Customer
UNION ALL SELECT 'Project',          COUNT(*) FROM college_project.Project
UNION ALL SELECT 'Room',             COUNT(*) FROM college_project.Room
UNION ALL SELECT 'Material',         COUNT(*) FROM college_project.Material
UNION ALL SELECT 'Room_Material',    COUNT(*) FROM college_project.Room_Material
UNION ALL SELECT 'Estimate',         COUNT(*) FROM college_project.Estimate
UNION ALL SELECT 'Payment',          COUNT(*) FROM college_project.Payment
UNION ALL SELECT 'Employee',         COUNT(*) FROM college_project.Employee
UNION ALL SELECT 'Project_Employee', COUNT(*) FROM college_project.Project_Employee;

