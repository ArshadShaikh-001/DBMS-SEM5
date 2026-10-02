from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session

from ..auth import require_roles
from ..database import get_db
from ..models import Estimate, Payment, Project
from ..schemas import EstimateCreate, EstimateOut, PaymentCreate, PaymentOut
from .projects import visible

router = APIRouter(tags=["Estimates and Payments"])


@router.post("/projects/{project_id}/estimate", response_model=EstimateOut, status_code=201)
def create_estimate(project_id: int, data: EstimateCreate, db: Session = Depends(get_db), current=Depends(require_roles("admin", "customer"))):
    project = db.get(Project, project_id)
    if not project or not visible(project, current):
        raise HTTPException(status_code=404, detail="Project not found")
    if project.estimate:
        raise HTTPException(status_code=409, detail="Project already has an estimate")
    estimate = Estimate(project_id=project_id, **data.model_dump())
    db.add(estimate)
    db.commit()
    db.refresh(estimate)
    return estimate


@router.get("/projects/{project_id}/estimate", response_model=EstimateOut)
def get_estimate(project_id: int, db: Session = Depends(get_db), current=Depends(require_roles("admin", "customer", "employee"))):
    project = db.get(Project, project_id)
    if not project or not visible(project, current) or not project.estimate:
        raise HTTPException(status_code=404, detail="Estimate not found")
    return project.estimate


@router.get("/estimates/{estimate_id}/payments", response_model=list[PaymentOut])
def list_payments(estimate_id: int, db: Session = Depends(get_db), current=Depends(require_roles("admin", "customer", "employee"))):
    estimate = db.get(Estimate, estimate_id)
    if not estimate or not visible(estimate.project, current):
        raise HTTPException(status_code=404, detail="Estimate not found")
    return db.query(Payment).filter(Payment.estimate_id == estimate_id).all()


@router.post("/estimates/{estimate_id}/payments", response_model=PaymentOut, status_code=201)
def create_payment(estimate_id: int, data: PaymentCreate, db: Session = Depends(get_db), current=Depends(require_roles("admin", "customer"))):
    estimate = db.get(Estimate, estimate_id)
    if not estimate or not visible(estimate.project, current):
        raise HTTPException(status_code=404, detail="Estimate not found")
    if data.payment_mode != "Cash" and not data.transaction_id:
        raise HTTPException(status_code=400, detail="Transaction ID is required for non-cash payments")
    payment = Payment(estimate_id=estimate_id, **data.model_dump())
    db.add(payment)
    db.commit()
    db.refresh(payment)
    return payment