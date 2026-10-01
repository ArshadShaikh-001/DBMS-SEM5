from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..auth import hash_password, require_roles
from ..database import get_db
from ..models import Employee, EmployeeAuth, Project, ProjectEmployee
from ..schemas import AssignmentCreate, EmployeeCreate, EmployeeOut

router = APIRouter(prefix="/employees", tags=["Employees"])


@router.get("", response_model=list[EmployeeOut])
def list_employees(db: Session = Depends(get_db), current=Depends(require_roles("admin", "employee"))):
    return db.query(Employee).order_by(Employee.emp_id).all()


@router.post("", response_model=EmployeeOut, status_code=201)
def create_employee(data: EmployeeCreate, db: Session = Depends(get_db), current=Depends(require_roles("admin"))):
    employee = Employee(**data.model_dump(exclude={"username", "password"}))
    db.add(employee)
    db.flush()
    if data.username and data.password:
        db.add(EmployeeAuth(emp_id=employee.emp_id, username=data.username, password=hash_password(data.password)))
    db.commit()
    db.refresh(employee)
    return employee


@router.put("/{emp_id}", response_model=EmployeeOut)
def update_employee(emp_id: int, data: EmployeeCreate, db: Session = Depends(get_db), current=Depends(require_roles("admin"))):
    employee = db.get(Employee, emp_id)
    if not employee:
        raise HTTPException(status_code=404, detail="Employee not found")
    for key, value in data.model_dump(exclude={"username", "password"}).items():
        setattr(employee, key, value)
    if data.username and data.password:
        employee.auth = EmployeeAuth(username=data.username, password=hash_password(data.password))
    db.commit()
    db.refresh(employee)
    return employee


@router.post("/projects/{project_id}/assign", status_code=201)
def assign_employee(project_id: int, data: AssignmentCreate, db: Session = Depends(get_db), current=Depends(require_roles("admin"))):
    if not db.get(Project, project_id) or not db.get(Employee, data.emp_id):
        raise HTTPException(status_code=404, detail="Project or employee not found")
    if db.get(ProjectEmployee, {"project_id": project_id, "emp_id": data.emp_id}):
        raise HTTPException(status_code=409, detail="Employee is already assigned")
    assignment = ProjectEmployee(project_id=project_id, **data.model_dump(exclude_none=True))
    db.add(assignment)
    db.commit()
    return {"project_id": project_id, "emp_id": data.emp_id, "message": "Employee assigned"}


@router.get("/projects/{project_id}")
def project_employees(project_id: int, db: Session = Depends(get_db), current=Depends(require_roles("admin", "employee", "customer"))):
    rows = db.query(ProjectEmployee).filter(ProjectEmployee.project_id == project_id).all()
    return [{"emp_id": row.emp_id, "emp_name": row.employee.emp_name, "designation": row.employee.designation, "role_in_project": row.role_in_project, "assigned_date": row.assigned_date} for row in rows]