"""
Database engine/session setup.

Uses DATABASE_URL from the environment so the same code runs against:
  - SQLite for local dev / CI tests   (default)
  - Postgres in AKS                   (set via ConfigMap/Secret in Helm)

This mirrors the "application:  database: postgres" config block from the
platform design in the plan.
"""

import os
from contextlib import contextmanager

from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./customer_api.db")

connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}
engine = create_engine(DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


@contextmanager
def get_session():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()
