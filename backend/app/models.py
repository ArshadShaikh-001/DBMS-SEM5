from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Numeric, String, Table, Column
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base


class Customer(Base):
    __tablename__ = "Customer"

    username: Mapped[str] = mapped_column(String(50), primary_key=True)
    password: Mapped[str] = mapped_column(String(255), nullable=False)
    customer_name: Mapped[str] = mapped_column(String(100), nullable=False)
    phone_no: Mapped[str] = mapped_column(String(15), nullable=False)
    email: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    role: Mapped[str] = mapped_column(String(20), default="customer", nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    projects: Mapped[list["Project"]] = relationship(back_populates="customer")


class Project(Base):
    __tablename__ = "Project"

    project_id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(ForeignKey("Customer.username"), nullable=False)
    project_name: Mapped[str] = mapped_column(String(100), nullable=False)
    project_type: Mapped[str] = mapped_column(String(30), default="Residential")
    budget: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date | None] = mapped_column(Date)
    status: Mapped[str] = mapped_column(String(30), default="Planned")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    customer: Mapped[Customer] = relationship(back_populates="projects")
    rooms: Mapped[list["Room"]] = relationship(back_populates="project", cascade="all, delete-orphan")
    estimate: Mapped["Estimate | None"] = relationship(back_populates="project", uselist=False)
    assignments: Mapped[list["ProjectEmployee"]] = relationship(back_populates="project", cascade="all, delete-orphan")


class Room(Base):
    __tablename__ = "Room"

    room_id: Mapped[int] = mapped_column(primary_key=True)
    project_id: Mapped[int] = mapped_column(ForeignKey("Project.project_id"), nullable=False)
    room_type: Mapped[str] = mapped_column(String(30), default="Other")
    length: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    breadth: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    height: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    area: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))
    project: Mapped[Project] = relationship(back_populates="rooms")
    materials: Mapped[list["RoomMaterial"]] = relationship(back_populates="room", cascade="all, delete-orphan")


class Material(Base):
    __tablename__ = "Material"

    material_id: Mapped[int] = mapped_column(primary_key=True)
    material_name: Mapped[str] = mapped_column(String(100), nullable=False)
    brand: Mapped[str] = mapped_column(String(100), default="Generic")
    unit: Mapped[str] = mapped_column(String(20), default="piece")
    quantity: Mapped[int] = mapped_column(default=0)
    unit_cost: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)


class RoomMaterial(Base):
    __tablename__ = "Room_Material"

    room_id: Mapped[int] = mapped_column(ForeignKey("Room.room_id"), primary_key=True)
    material_id: Mapped[int] = mapped_column(ForeignKey("Material.material_id"), primary_key=True)
    quantity_used: Mapped[int] = mapped_column(nullable=False)
    room: Mapped[Room] = relationship(back_populates="materials")
    material: Mapped[Material] = relationship()


class Estimate(Base):
    __tablename__ = "Estimate"

    estimate_id: Mapped[int] = mapped_column(primary_key=True)
    project_id: Mapped[int] = mapped_column(ForeignKey("Project.project_id"), unique=True, nullable=False)
    material_cost: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0)
    labor_cost: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0)
    other_cost: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0)
    total_cost: Mapped[Decimal | None] = mapped_column(Numeric(13, 2))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    project: Mapped[Project] = relationship(back_populates="estimate")
    payments: Mapped[list["Payment"]] = relationship(back_populates="estimate")


class Payment(Base):
    __tablename__ = "Payment"

    payment_id: Mapped[int] = mapped_column(primary_key=True)
    estimate_id: Mapped[int] = mapped_column(ForeignKey("Estimate.estimate_id"), nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    payment_mode: Mapped[str] = mapped_column(String(30), nullable=False)
    transaction_id: Mapped[str | None] = mapped_column(String(100), unique=True)
    payment_date: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    estimate: Mapped[Estimate] = relationship(back_populates="payments")


class Employee(Base):
    __tablename__ = "Employee"

    emp_id: Mapped[int] = mapped_column(primary_key=True)
    emp_name: Mapped[str] = mapped_column(String(100), nullable=False)
    phone_no: Mapped[str] = mapped_column(String(15), nullable=False)
    email: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    designation: Mapped[str] = mapped_column(String(50), default="Worker")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    auth: Mapped["EmployeeAuth | None"] = relationship(back_populates="employee", uselist=False, cascade="all, delete-orphan")
    assignments: Mapped[list["ProjectEmployee"]] = relationship(back_populates="employee")


class EmployeeAuth(Base):
    __tablename__ = "Employee_Auth"

    emp_id: Mapped[int] = mapped_column(ForeignKey("Employee.emp_id"), primary_key=True)
    username: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    password: Mapped[str] = mapped_column(String(255), nullable=False)
    employee: Mapped[Employee] = relationship(back_populates="auth")


class ProjectEmployee(Base):
    __tablename__ = "Project_Employee"

    project_id: Mapped[int] = mapped_column(ForeignKey("Project.project_id"), primary_key=True)
    emp_id: Mapped[int] = mapped_column(ForeignKey("Employee.emp_id"), primary_key=True)
    role_in_project: Mapped[str] = mapped_column(String(50), default="Worker")
    assigned_date: Mapped[date] = mapped_column(Date, default=date.today)
    project: Mapped[Project] = relationship(back_populates="assignments")
    employee: Mapped[Employee] = relationship(back_populates="assignments")