from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from ..auth import require_roles
from ..database import get_db
from ..models import Customer, Employee, Material, Payment, Project

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("/summary")
def summary(db: Session = Depends(get_db), current=Depends(require_roles("admin"))):
    return {
        "customers": db.query(func.count(Customer.username)).filter(Customer.role == "customer").scalar(),
        "projects": db.query(func.count(Project.project_id)).scalar(),
        "employees": db.query(func.count(Employee.emp_id)).filter(Employee.is_active.is_(True)).scalar(),
        "materials": db.query(func.count(Material.material_id)).scalar(),
        "total_budget": db.query(func.coalesce(func.sum(Project.budget), 0)).scalar(),
        "total_paid": db.query(func.coalesce(func.sum(Payment.amount), 0)).scalar(),
    }


@router.get("/low-stock")
def low_stock(db: Session = Depends(get_db), current=Depends(require_roles("admin", "employee"))):
    return db.query(Material).filter(Material.quantity <= 150).order_by(Material.quantity).all()