# Interior Design System Backend

Basic FastAPI backend for the existing `college_project` MySQL schema.

## Setup

1. Create the database and load the root SQL files in order:
   `1-ddl-tablecreation.sql`, then `2-insert-data.sql`, then `3-check_constrians-queries.sql`.
2. If using the original DDL from before this backend, add the small employee-login table once:

```sql
CREATE TABLE college_project.Employee_Auth (
    emp_id INT NOT NULL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    CONSTRAINT fk_employee_auth_employee FOREIGN KEY (emp_id)
        REFERENCES college_project.Employee (emp_id) ON DELETE CASCADE
);
```

This is additive only. Existing employee rows remain valid; an admin can create credentials through `POST /employees`.

3. From this directory, install dependencies:

```powershell
python -m pip install -r requirements.txt
```

4. Set the database URL and JWT secret. Use `mysql+pymysql://root:YOUR_MYSQL_PASSWORD@localhost:3306/college_project` with your local password.

```powershell
$env:DATABASE_URL = "mysql+pymysql://root:your_password@localhost:3306/college_project"
$env:JWT_SECRET = "use-a-long-random-value"
```

5. Run the API:

```powershell
uvicorn app.main:app --reload
```

Interactive API documentation is available at `http://127.0.0.1:8000/docs`.

Customer registration creates a customer account. Admin and employee accounts are created from the seeded admin or directly in MySQL. Passwords entered through the API are hashed before storage. The seeded demo strings are accepted for local testing only; replace them with real hashes in production.