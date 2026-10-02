from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..auth import require_roles
from ..database import get_db
from ..models import Customer, Project
from ..schemas import ProjectCreate, ProjectOut

router = APIRouter(prefix="/projects", tags=["Projects"])


def get_project(project_id: int, db: Session) -> Project:
    project = db.get(Project, project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    return project


def visible(project: Project, current) -> bool:
    return current["role"] in ("admin", "employee") or project.username == current["subject"]


@router.get("", response_model=list[ProjectOut])
def list_projects(db: Session = Depends(get_db), current=Depends(require_roles("customer", "admin", "employee"))):
    if current["role"] == "customer":
        return db.query(Project).filter(Project.username == current["subject"]).all()
    return db.query(Project).all()


@router.post("", response_model=ProjectOut, status_code=201)
def create_project(data: ProjectCreate, db: Session = Depends(get_db), current=Depends(require_roles("customer", "admin"))):
    payload = data.model_dump()
    username = current["subject"] if current["role"] == "customer" else payload.pop("username", None)
    payload.pop("username", None)
    if not username:
        raise HTTPException(status_code=400, detail="Admin must provide a customer username")
    if not db.get(Customer, username):
        raise HTTPException(status_code=404, detail="Customer not found")
    project = Project(**payload, username=username)
    db.add(project)
    db.commit()
    db.refresh(project)
    return project


@router.get("/{project_id}", response_model=ProjectOut)
def get_one(project_id: int, db: Session = Depends(get_db), current=Depends(require_roles("customer", "admin", "employee"))):
    project = get_project(project_id, db)
    if not visible(project, current):
        raise HTTPException(status_code=403, detail="Project is not accessible")
    return project


@router.put("/{project_id}", response_model=ProjectOut)
def update_project(project_id: int, data: ProjectCreate, db: Session = Depends(get_db), current=Depends(require_roles("customer", "admin"))):
    project = get_project(project_id, db)
    if current["role"] == "customer" and project.username != current["subject"]:
        raise HTTPException(status_code=403, detail="Project is not accessible")
    for key, value in data.model_dump().items():
        setattr(project, key, value)
    db.commit()
    db.refresh(project)
    return project


@router.delete("/{project_id}", status_code=204)
def delete_project(project_id: int, db: Session = Depends(get_db), current=Depends(require_roles("admin"))):
    project = get_project(project_id, db)
    db.delete(project)
    db.commit()