from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .routes import auth, dashboard, employees, finance, materials, projects, rooms

app = FastAPI(title="Interior Design System API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(projects.router)
app.include_router(rooms.router)
app.include_router(materials.router)
app.include_router(finance.router)
app.include_router(employees.router)
app.include_router(dashboard.router)


@app.get("/health", tags=["System"])
def health():
    return {"status": "ok"}