from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from ..auth import create_token, hash_password, verify_password
from ..database import get_db
from ..models import Customer, EmployeeAuth
from ..schemas import CustomerOut, RegisterRequest, Token

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=CustomerOut, status_code=201)
def register(data: RegisterRequest, db: Session = Depends(get_db)):
    if db.get(Customer, data.username) or db.query(Customer).filter(Customer.email == data.email).first():
        raise HTTPException(status_code=409, detail="Username or email already exists")
    customer = Customer(**data.model_dump(exclude={"password"}), password=hash_password(data.password))
    db.add(customer)
    db.commit()
    db.refresh(customer)
    return customer


@router.post("/login", response_model=Token)
def login(data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    customer = db.get(Customer, data.username)
    if customer and verify_password(data.password, customer.password):
        role = customer.role
        return Token(access_token=create_token(customer.username, role), token_type="bearer", role=role)

    employee_auth = db.query(EmployeeAuth).filter(EmployeeAuth.username == data.username).first()
    if employee_auth and employee_auth.employee.is_active and verify_password(data.password, employee_auth.password):
        return Token(access_token=create_token(data.username, "employee"), token_type="bearer", role="employee")
    raise HTTPException(status_code=401, detail="Incorrect username or password")