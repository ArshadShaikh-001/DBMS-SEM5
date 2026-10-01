from fastapi import FastAPI

from .routes import auth, dashboard, employees, finance, materials, projects, rooms

app = FastAPI(title="Interior Design System API", version="1.0.0")

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