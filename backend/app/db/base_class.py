from sqlalchemy.orm import DeclarativeBase, declared_attr
from typing import Any

class Base(DeclarativeBase):
    id: Any
    
    # Automate table naming
    @declared_attr.directive
    def __tablename__(cls) -> str:
        return cls.__name__.lower()
