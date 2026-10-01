from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class APIModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)


class RegisterRequest(BaseModel):
    username: str = Field(min_length=3, max_length=50)
    password: str = Field(min_length=6, max_length=100)
    customer_name: str
    phone_no: str
    email: EmailStr


class LoginRequest(BaseModel):
    username: str
    password: str


class Token(APIModel):
    access_token: str
    token_type: str
    role: str


class CustomerOut(APIModel):
    username: str
    customer_name: str
    phone_no: str
    email: EmailStr
    role: str


class ProjectCreate(BaseModel):
    username: str | None = None
    project_name: str
    project_type: str = "Residential"
    budget: Decimal = Field(default=0, ge=0)
    start_date: date
    end_date: date | None = None
    status: str = "Planned"


class ProjectOut(ProjectCreate, APIModel):
    project_id: int
    username: str


class RoomCreate(BaseModel):
    room_type: str = "Other"
    length: Decimal = Field(gt=0)
    breadth: Decimal = Field(gt=0)
    height: Decimal = Field(gt=0)


class RoomOut(RoomCreate, APIModel):
    room_id: int
    project_id: int
    area: Decimal | None = None


class MaterialCreate(BaseModel):
    material_name: str
    brand: str = "Generic"
    unit: str = "piece"
    quantity: int = Field(default=0, ge=0)
    unit_cost: Decimal = Field(ge=0)


class MaterialOut(MaterialCreate, APIModel):
    material_id: int


class EstimateCreate(BaseModel):
    material_cost: Decimal = Field(default=0, ge=0)
    labor_cost: Decimal = Field(default=0, ge=0)
    other_cost: Decimal = Field(default=0, ge=0)


class EstimateOut(EstimateCreate, APIModel):
    estimate_id: int
    project_id: int
    total_cost: Decimal | None = None
    created_at: datetime


class PaymentCreate(BaseModel):
    amount: Decimal = Field(gt=0)
    payment_mode: str
    transaction_id: str | None = None


class PaymentOut(PaymentCreate, APIModel):
    payment_id: int
    estimate_id: int
    payment_date: datetime


class EmployeeCreate(BaseModel):
    emp_name: str
    phone_no: str
    email: EmailStr
    designation: str = "Worker"
    is_active: bool = True
    username: str | None = None
    password: str | None = Field(default=None, min_length=6)


class EmployeeOut(APIModel):
    emp_id: int
    emp_name: str
    phone_no: str
    email: EmailStr
    designation: str
    is_active: bool


class AssignmentCreate(BaseModel):
    emp_id: int
    role_in_project: str = "Worker"
    assigned_date: date | None = None