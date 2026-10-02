CREATE DATABASE IF NOT EXISTS college_project
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
    
    CREATE TABLE college_project.Customer (
    username       VARCHAR(50)   NOT NULL,
    password       VARCHAR(255)  NOT NULL,
    customer_name  VARCHAR(100)  NOT NULL,
    phone_no       VARCHAR(15)   NOT NULL,
    email          VARCHAR(100)  NOT NULL,
    role           ENUM('customer','admin') NOT NULL DEFAULT 'customer',
    created_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_customer PRIMARY KEY (username),
    CONSTRAINT uq_customer_email UNIQUE (email),
    CONSTRAINT chk_customer_username CHECK (CHAR_LENGTH(username) >= 3 AND username NOT LIKE '% %'),
    CONSTRAINT chk_customer_name     CHECK (CHAR_LENGTH(TRIM(customer_name)) > 0),
    CONSTRAINT chk_customer_phone    CHECK (phone_no REGEXP '^[0-9+]{10,15}$'),
    CONSTRAINT chk_customer_email    CHECK (email LIKE '_%@_%._%')
) ENGINE=InnoDB;

show tables ;


CREATE TABLE Project (
    project_id    INT            NOT NULL AUTO_INCREMENT,
    username      VARCHAR(50)    NOT NULL,
    project_name  VARCHAR(100)   NOT NULL,
    project_type  ENUM('Residential','Commercial','Renovation','Interior','Other')
                                 NOT NULL DEFAULT 'Residential',
    budget        DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    start_date    DATE           NOT NULL,
    end_date      DATE               NULL,
    status        ENUM('Planned','In Progress','Completed','Cancelled')
                                 NOT NULL DEFAULT 'Planned',
    created_at    TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_project PRIMARY KEY (project_id),
    CONSTRAINT fk_project_customer FOREIGN KEY (username)
        REFERENCES Customer (username)
        ON UPDATE CASCADE     -- username changed -> projects follow
        ON DELETE RESTRICT,   -- cannot delete a customer who has projects
    CONSTRAINT chk_project_name   CHECK (CHAR_LENGTH(TRIM(project_name)) > 0),
    CONSTRAINT chk_project_budget CHECK (budget >= 0),
    CONSTRAINT chk_project_dates  CHECK (end_date IS NULL OR end_date >= start_date)
) ENGINE=InnoDB;

CREATE INDEX idx_project_status     ON Project (status);
CREATE INDEX idx_project_start_date ON Project (start_date);

-- =====================================================================
-- 3. ROOM             (Project 1 ---- N Room : "has")  - weak entity
--    area is calculated by MySQL itself, so it can never be wrong.
-- =====================================================================
CREATE TABLE Room (
    room_id     INT           NOT NULL AUTO_INCREMENT,
    project_id  INT           NOT NULL,
    room_type   ENUM('Bedroom','Living Room','Kitchen','Bathroom','Dining Room',
                     'Balcony','Office','Hall','Other') NOT NULL DEFAULT 'Other',
    length      DECIMAL(10,2) NOT NULL,
    breadth     DECIMAL(10,2) NOT NULL,
    height      DECIMAL(10,2) NOT NULL,
    area        DECIMAL(12,2) GENERATED ALWAYS AS (length * breadth) STORED,

    CONSTRAINT pk_room PRIMARY KEY (room_id),
    CONSTRAINT fk_room_project FOREIGN KEY (project_id)
        REFERENCES Project (project_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,    -- deleting a project removes its rooms
    CONSTRAINT chk_room_length  CHECK (length  > 0),
    CONSTRAINT chk_room_breadth CHECK (breadth > 0),
    CONSTRAINT chk_room_height  CHECK (height  > 0)
) ENGINE=InnoDB;

-- =====================================================================
-- 4. MATERIAL
--    quantity   = stock available in the store.
--    total_cost = derived attribute (dashed oval in your ER diagram),
--                 so it is NOT stored. It is calculated in a view:
--                 quantity_used * unit_cost.
-- =====================================================================
CREATE TABLE Material (
    material_id    INT           NOT NULL AUTO_INCREMENT,
    material_name  VARCHAR(100)  NOT NULL,
    brand          VARCHAR(100)  NOT NULL DEFAULT 'Generic',
    unit           VARCHAR(20)   NOT NULL DEFAULT 'piece',   -- kg, sqft, litre, piece...
    quantity       INT           NOT NULL DEFAULT 0,
    unit_cost      DECIMAL(10,2) NOT NULL,

    CONSTRAINT pk_material PRIMARY KEY (material_id),
    CONSTRAINT uq_material_name_brand UNIQUE (material_name, brand),
    CONSTRAINT chk_material_name     CHECK (CHAR_LENGTH(TRIM(material_name)) > 0),
    CONSTRAINT chk_material_quantity CHECK (quantity  >= 0),
    CONSTRAINT chk_material_cost     CHECK (unit_cost >= 0)
) ENGINE=InnoDB;

-- =====================================================================
-- 5. ROOM_MATERIAL    (Room N ---- M Material : "material used")
--    This table was MISSING in your old schema. A many-to-many
--    relationship always needs its own table.
-- =====================================================================
CREATE TABLE Room_Material (
    room_id        INT NOT NULL,
    material_id    INT NOT NULL,
    quantity_used  INT NOT NULL,

    CONSTRAINT pk_room_material PRIMARY KEY (room_id, material_id),
    CONSTRAINT fk_rm_room FOREIGN KEY (room_id)
        REFERENCES Room (room_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_rm_material FOREIGN KEY (material_id)
        REFERENCES Material (material_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,   -- cannot delete a material that is in use
    CONSTRAINT chk_rm_quantity CHECK (quantity_used > 0)
) ENGINE=InnoDB;

-- =====================================================================
-- 6. ESTIMATE         (Project 1 ---- 1 Estimate : "has")
--    UNIQUE(project_id) makes it one estimate per project.
--    total_cost = material + labor + other, calculated by MySQL.
-- =====================================================================
CREATE TABLE Estimate (
    estimate_id    INT            NOT NULL AUTO_INCREMENT,
    project_id     INT            NOT NULL,
    material_cost  DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    labor_cost     DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    other_cost     DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    total_cost     DECIMAL(13,2)  GENERATED ALWAYS AS (material_cost + labor_cost + other_cost) STORED,
    created_at     TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_estimate PRIMARY KEY (estimate_id),
    CONSTRAINT uq_estimate_project UNIQUE (project_id),
    CONSTRAINT fk_estimate_project FOREIGN KEY (project_id)
        REFERENCES Project (project_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT chk_estimate_material CHECK (material_cost >= 0),
    CONSTRAINT chk_estimate_labor    CHECK (labor_cost    >= 0),
    CONSTRAINT chk_estimate_other    CHECK (other_cost    >= 0)
) ENGINE=InnoDB;

-- =====================================================================
-- 7. PAYMENT          (Estimate 1 ---- N Payment : "has") - weak entity
--    RESTRICT on delete: payment records must never disappear silently.
--    Non-cash payments must have a transaction id.
-- =====================================================================
CREATE TABLE Payment (
    payment_id      INT            NOT NULL AUTO_INCREMENT,
    estimate_id     INT            NOT NULL,
    amount          DECIMAL(12,2)  NOT NULL,
    payment_mode    ENUM('Cash','UPI','Card','Net Banking','Cheque') NOT NULL,
    transaction_id  VARCHAR(100)       NULL,
    payment_date    TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_payment PRIMARY KEY (payment_id),
    CONSTRAINT uq_payment_txn UNIQUE (transaction_id),   -- NULLs allowed (cash)
    CONSTRAINT fk_payment_estimate FOREIGN KEY (estimate_id)
        REFERENCES Estimate (estimate_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_payment_amount CHECK (amount > 0),
    CONSTRAINT chk_payment_txn    CHECK (payment_mode = 'Cash' OR transaction_id IS NOT NULL)
) ENGINE=InnoDB;

CREATE INDEX idx_payment_date ON Payment (payment_date);

-- =====================================================================
-- 8. EMPLOYEE
-- =====================================================================
CREATE TABLE Employee (
    emp_id       INT           NOT NULL AUTO_INCREMENT,
    emp_name     VARCHAR(100)  NOT NULL,
    phone_no     VARCHAR(15)   NOT NULL,
    email        VARCHAR(100)  NOT NULL,
    designation  VARCHAR(50)   NOT NULL DEFAULT 'Worker',  -- Engineer, Carpenter...
    is_active    BOOLEAN       NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_employee PRIMARY KEY (emp_id),
    CONSTRAINT uq_employee_email UNIQUE (email),
    CONSTRAINT uq_employee_phone UNIQUE (phone_no),
    CONSTRAINT chk_employee_name  CHECK (CHAR_LENGTH(TRIM(emp_name)) > 0),
    CONSTRAINT chk_employee_phone CHECK (phone_no REGEXP '^[0-9+]{10,15}$'),
    CONSTRAINT chk_employee_email CHECK (email LIKE '_%@_%._%')
) ENGINE=InnoDB;

-- =====================================================================
-- 9. PROJECT_EMPLOYEE (Employee M ---- N Project : "assign")
--    The stray word "workers" in your old file is now a real column.
-- =====================================================================
CREATE TABLE Project_Employee (
    project_id        INT          NOT NULL,
    emp_id            INT          NOT NULL,
    role_in_project   VARCHAR(50)  NOT NULL DEFAULT 'Worker',
    assigned_date     DATE         NOT NULL DEFAULT (CURRENT_DATE),

    CONSTRAINT pk_project_employee PRIMARY KEY (project_id, emp_id),
    CONSTRAINT fk_pe_project FOREIGN KEY (project_id)
        REFERENCES Project (project_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_pe_employee FOREIGN KEY (emp_id)
        REFERENCES Employee (emp_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- =====================================================================
-- 10. EMPLOYEE_AUTH (additive credentials for employee JWT login)
--     Existing Employee rows remain valid and can receive credentials
--     through the backend employee API.
-- =====================================================================
CREATE TABLE Employee_Auth (
    emp_id     INT          NOT NULL,
    username   VARCHAR(50)  NOT NULL,
    password   VARCHAR(255) NOT NULL,

    CONSTRAINT pk_employee_auth PRIMARY KEY (emp_id),
    CONSTRAINT uq_employee_auth_username UNIQUE (username),
    CONSTRAINT fk_employee_auth_employee FOREIGN KEY (emp_id)
        REFERENCES Employee (emp_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;


