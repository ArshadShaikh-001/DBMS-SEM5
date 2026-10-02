from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..auth import require_roles
from ..database import get_db
from ..models import Material, RoomMaterial
from ..schemas import MaterialCreate, MaterialOut

router = APIRouter(prefix="/materials", tags=["Materials"])


@router.get("", response_model=list[MaterialOut])
def list_materials(db: Session = Depends(get_db), current=Depends(require_roles("customer", "admin", "employee"))):
    return db.query(Material).order_by(Material.material_id).all()


@router.post("", response_model=MaterialOut, status_code=201)
def create_material(data: MaterialCreate, db: Session = Depends(get_db), current=Depends(require_roles("admin"))):
    if db.query(Material).filter(Material.material_name == data.material_name, Material.brand == data.brand).first():
        raise HTTPException(status_code=409, detail="Material with this name and brand already exists")
    material = Material(**data.model_dump())
    db.add(material)
    db.commit()
    db.refresh(material)
    return material


@router.put("/{material_id}", response_model=MaterialOut)
def update_material(material_id: int, data: MaterialCreate, db: Session = Depends(get_db), current=Depends(require_roles("admin"))):
    material = db.get(Material, material_id)
    if not material:
        raise HTTPException(status_code=404, detail="Material not found")
    if db.query(Material).filter(
        Material.material_id != material_id,
        Material.material_name == data.material_name,
        Material.brand == data.brand,
    ).first():
        raise HTTPException(status_code=409, detail="Material with this name and brand already exists")
    for key, value in data.model_dump().items():
        setattr(material, key, value)
    db.commit()
    db.refresh(material)
    return material


@router.delete("/{material_id}", status_code=204)
def delete_material(material_id: int, db: Session = Depends(get_db), current=Depends(require_roles("admin"))):
    material = db.get(Material, material_id)
    if not material:
        raise HTTPException(status_code=404, detail="Material not found")
    if db.query(RoomMaterial).filter(RoomMaterial.material_id == material_id).first():
        raise HTTPException(status_code=409, detail="Material is used by a room")
    db.delete(material)
    db.commit()