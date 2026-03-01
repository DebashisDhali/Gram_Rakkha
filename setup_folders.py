import os

folders = [
    "backend/app/api/v1/endpoints",
    "backend/app/core",
    "backend/app/db",
    "backend/app/models",
    "backend/app/repositories",
    "backend/app/schemas",
    "backend/app/services",
    "backend/alembic",
    "flutter_app/lib/core",
    "flutter_app/lib/features/auth",
    "flutter_app/lib/features/emergency",
    "flutter_app/lib/features/community"
]

for folder in folders:
    os.makedirs(folder, exist_ok=True)
    with open(os.path.join(folder, ".gitkeep"), "w") as f:
        pass

print("Folders created successfully.")
