import os
from datetime import datetime, timedelta, timezone

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from .database import get_db
from .models import Customer, Employee, EmployeeAuth


SECRET_KEY = os.getenv("JWT_SECRET", "change-this-development-secret")
ALGORITHM = "HS256"
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(password: str, hashed: str) -> bool:
    # The seed script contains demonstration strings rather than password hashes.
    if not hashed.startswith("$2"):
        return password == hashed
    return pwd_context.verify(password, hashed)


def create_token(subject: str, role: str) -> str:
    payload = {"sub": subject, "role": role, "exp": datetime.now(timezone.utc) + timedelta(hours=8)}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_error = HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authentication credentials")
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        subject = payload.get("sub")
        role = payload.get("role")
        if not subject or not role:
            raise credentials_error
    except JWTError as exc:
        raise credentials_error from exc

    if role == "employee":
        auth = db.query(EmployeeAuth).filter(EmployeeAuth.username == subject).first()
        user = auth.employee if auth else None
    else:
        user = db.get(Customer, subject)
    if user is None:
        raise credentials_error
    return {"user": user, "role": role, "subject": subject}


def require_roles(*roles: str):
    def dependency(current=Depends(get_current_user)):
        if current["role"] not in roles:
            raise HTTPException(status_code=403, detail="Insufficient permissions")
        return current
    return dependency