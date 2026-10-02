from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..auth import require_roles
from ..database import get_db
from ..models import Project, Room
from ..schemas import RoomCreate, RoomOut
from .projects import visible

router = APIRouter(prefix="/rooms", tags=["Rooms"])


def project_or_404(project_id: int, db: Session):
    project = db.get(Project, project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    return project


@router.get("/project/{project_id}", response_model=list[RoomOut])
def list_rooms(project_id: int, db: Session = Depends(get_db), current=Depends(require_roles("customer", "admin", "employee"))):
    project = project_or_404(project_id, db)
    if not visible(project, current):
        raise HTTPException(status_code=403, detail="Project is not accessible")
    return db.query(Room).filter(Room.project_id == project_id).all()


@router.post("/project/{project_id}", response_model=RoomOut, status_code=201)
def create_room(project_id: int, data: RoomCreate, db: Session = Depends(get_db), current=Depends(require_roles("customer", "admin"))):
    project = project_or_404(project_id, db)
    if not visible(project, current):
        raise HTTPException(status_code=403, detail="Project is not accessible")
    room = Room(project_id=project_id, **data.model_dump())
    db.add(room)
    db.commit()
    db.refresh(room)
    return room


@router.delete("/{room_id}", status_code=204)
def delete_room(room_id: int, db: Session = Depends(get_db), current=Depends(require_roles("admin"))):
    room = db.get(Room, room_id)
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    db.delete(room)
    db.commit()