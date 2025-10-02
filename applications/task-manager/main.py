"""
Task Manager API - C4.md Implementation
FastAPI-based REST API for task management with PostgreSQL
"""

import os
import logging
from datetime import datetime, timezone
from typing import List, Optional
from contextlib import asynccontextmanager

import asyncpg
from fastapi import FastAPI, HTTPException, Depends, Header, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from pydantic import BaseModel, Field, validator
import uvicorn


# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database connection pool
db_pool = None
security = HTTPBearer()


# Pydantic Models
class TaskBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    content: str = Field(..., min_length=1, max_length=2000)
    due_date: str = Field(..., description="Due date in YYYY-MM-DD format")
    request_timestamp: datetime = Field(..., description="Request timestamp in ISO format")

    @validator('due_date')
    def validate_due_date(cls, v):
        try:
            datetime.strptime(v, '%Y-%m-%d')
            return v
        except ValueError:
            raise ValueError('due_date must be in YYYY-MM-DD format')

    @validator('request_timestamp')
    def validate_request_timestamp(cls, v):
        if isinstance(v, str):
            try:
                return datetime.fromisoformat(v.replace('Z', '+00:00'))
            except ValueError:
                raise ValueError('request_timestamp must be in ISO format')
        return v


class TaskCreate(TaskBase):
    pass


class TaskUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    content: Optional[str] = Field(None, min_length=1, max_length=2000)
    due_date: Optional[str] = Field(None, description="Due date in YYYY-MM-DD format")
    done: Optional[bool] = None
    request_timestamp: datetime = Field(..., description="Request timestamp in ISO format")

    @validator('due_date')
    def validate_due_date(cls, v):
        if v is not None:
            try:
                datetime.strptime(v, '%Y-%m-%d')
            except ValueError:
                raise ValueError('due_date must be in YYYY-MM-DD format')
        return v

    @validator('request_timestamp')
    def validate_request_timestamp(cls, v):
        if isinstance(v, str):
            try:
                return datetime.fromisoformat(v.replace('Z', '+00:00'))
            except ValueError:
                raise ValueError('request_timestamp must be in ISO format')
        return v


class TaskDelete(BaseModel):
    request_timestamp: datetime = Field(..., description="Request timestamp in ISO format")

    @validator('request_timestamp')
    def validate_request_timestamp(cls, v):
        if isinstance(v, str):
            try:
                return datetime.fromisoformat(v.replace('Z', '+00:00'))
            except ValueError:
                raise ValueError('request_timestamp must be in ISO format')
        return v


class TaskResponse(BaseModel):
    id: int
    title: str
    content: str
    due_date: str
    done: bool
    created_at: datetime
    updated_at: datetime


# Database functions
async def get_db_pool():
    """Get database connection pool"""
    global db_pool
    if db_pool is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database connection not available"
        )
    return db_pool


async def init_database():
    """Initialize database connection and create tables"""
    global db_pool
    
    # Get database URL from environment
    database_url = os.getenv('DATABASE_URL')
    if not database_url:
        raise ValueError("DATABASE_URL environment variable is required")
    
    try:
        # Create connection pool
        db_pool = await asyncpg.create_pool(
            database_url,
            min_size=1,
            max_size=10,
            command_timeout=60
        )
        
        # Create tables if they don't exist
        async with db_pool.acquire() as connection:
            await connection.execute("""
                CREATE TABLE IF NOT EXISTS tasks (
                    id SERIAL PRIMARY KEY,
                    title VARCHAR(200) NOT NULL,
                    content TEXT NOT NULL,
                    due_date DATE NOT NULL,
                    done BOOLEAN DEFAULT FALSE,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    last_request_timestamp TIMESTAMP WITH TIME ZONE NOT NULL
                );
                
                CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);
                CREATE INDEX IF NOT EXISTS idx_tasks_done ON tasks(done);
                CREATE INDEX IF NOT EXISTS idx_tasks_last_request_timestamp ON tasks(last_request_timestamp);
            """)
        
        logger.info("Database initialized successfully")
        
    except Exception as e:
        logger.error(f"Failed to initialize database: {e}")
        raise


async def close_database():
    """Close database connection pool"""
    global db_pool
    if db_pool:
        await db_pool.close()
        logger.info("Database connection closed")


# Authentication
async def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """
    Verify JWT token - simplified for demo
    In production, implement proper JWT verification
    """
    token = credentials.credentials
    
    # For demo purposes, accept any non-empty token
    # In production, verify JWT signature and claims
    if not token or len(token) < 10:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return {"user_id": "demo_user", "scopes": ["read", "write"]}


# Lifecycle management
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle"""
    # Startup
    await init_database()
    yield
    # Shutdown
    await close_database()


# FastAPI application
app = FastAPI(
    title="Task Manager API",
    description="RESTful Task Manager API - C4.md Implementation",
    version="1.0.0",
    lifespan=lifespan
)

# Security middleware
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["*"]  # Configure properly in production
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint for load balancer"""
    try:
        pool = await get_db_pool()
        async with pool.acquire() as connection:
            await connection.fetchval("SELECT 1")
        return {"status": "healthy", "timestamp": datetime.now(timezone.utc)}
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Service unavailable"
        )


# Task endpoints
@app.post("/tasks", status_code=status.HTTP_201_CREATED, response_model=TaskResponse)
async def create_task(
    task: TaskCreate,
    correlation_id: str = Header(...),
    user: dict = Depends(verify_token)
):
    """Create a new task"""
    pool = await get_db_pool()
    
    try:
        async with pool.acquire() as connection:
            # Check for potential timestamp conflicts
            existing = await connection.fetchrow(
                """
                SELECT id FROM tasks 
                WHERE title = $1 AND last_request_timestamp >= $2
                """,
                task.title, task.request_timestamp
            )
            
            if existing:
                logger.warning(f"Timestamp conflict for task '{task.title}' - correlation_id: {correlation_id}")
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Task creation conflict - timestamp/duplicate issue"
                )
            
            # Insert new task
            row = await connection.fetchrow(
                """
                INSERT INTO tasks (title, content, due_date, last_request_timestamp)
                VALUES ($1, $2, $3, $4)
                RETURNING id, title, content, due_date, done, created_at, updated_at
                """,
                task.title, task.content, task.due_date, task.request_timestamp
            )
            
            logger.info(f"Created task {row['id']} - correlation_id: {correlation_id}")
            
            return TaskResponse(
                id=row['id'],
                title=row['title'],
                content=row['content'],
                due_date=row['due_date'].isoformat(),
                done=row['done'],
                created_at=row['created_at'],
                updated_at=row['updated_at']
            )
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create task - correlation_id: {correlation_id}, error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error"
        )


@app.get("/tasks", response_model=List[TaskResponse])
async def list_tasks(
    correlation_id: str = Header(...),
    user: dict = Depends(verify_token)
):
    """List all tasks"""
    pool = await get_db_pool()
    
    try:
        async with pool.acquire() as connection:
            rows = await connection.fetch(
                """
                SELECT id, title, content, due_date, done, created_at, updated_at
                FROM tasks
                ORDER BY created_at DESC
                """
            )
            
            tasks = [
                TaskResponse(
                    id=row['id'],
                    title=row['title'],
                    content=row['content'],
                    due_date=row['due_date'].isoformat(),
                    done=row['done'],
                    created_at=row['created_at'],
                    updated_at=row['updated_at']
                )
                for row in rows
            ]
            
            logger.info(f"Listed {len(tasks)} tasks - correlation_id: {correlation_id}")
            return tasks
            
    except Exception as e:
        logger.error(f"Failed to list tasks - correlation_id: {correlation_id}, error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error"
        )


@app.get("/tasks/{task_id}", response_model=TaskResponse)
async def get_task(
    task_id: int,
    correlation_id: str = Header(...),
    user: dict = Depends(verify_token)
):
    """Get a specific task"""
    pool = await get_db_pool()
    
    try:
        async with pool.acquire() as connection:
            row = await connection.fetchrow(
                """
                SELECT id, title, content, due_date, done, created_at, updated_at
                FROM tasks
                WHERE id = $1
                """,
                task_id
            )
            
            if not row:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Task not found"
                )
            
            logger.info(f"Retrieved task {task_id} - correlation_id: {correlation_id}")
            
            return TaskResponse(
                id=row['id'],
                title=row['title'],
                content=row['content'],
                due_date=row['due_date'].isoformat(),
                done=row['done'],
                created_at=row['created_at'],
                updated_at=row['updated_at']
            )
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get task {task_id} - correlation_id: {correlation_id}, error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error"
        )


@app.put("/tasks/{task_id}", response_model=TaskResponse)
async def update_task(
    task_id: int,
    task_update: TaskUpdate,
    correlation_id: str = Header(...),
    user: dict = Depends(verify_token)
):
    """Update a task (handles out-of-order requests)"""
    pool = await get_db_pool()
    
    try:
        async with pool.acquire() as connection:
            # Check if task exists and get current timestamp
            current = await connection.fetchrow(
                """
                SELECT id, last_request_timestamp
                FROM tasks
                WHERE id = $1
                """,
                task_id
            )
            
            if not current:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Task not found"
                )
            
            # Handle out-of-order requests: only process if timestamp is newer
            if task_update.request_timestamp <= current['last_request_timestamp']:
                logger.warning(
                    f"Ignoring out-of-order update for task {task_id} - "
                    f"correlation_id: {correlation_id}, "
                    f"request_ts: {task_update.request_timestamp}, "
                    f"current_ts: {current['last_request_timestamp']}"
                )
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Request timestamp is older than current state"
                )
            
            # Build update query dynamically
            updates = []
            values = []
            param_count = 1
            
            if task_update.title is not None:
                updates.append(f"title = ${param_count}")
                values.append(task_update.title)
                param_count += 1
            
            if task_update.content is not None:
                updates.append(f"content = ${param_count}")
                values.append(task_update.content)
                param_count += 1
            
            if task_update.due_date is not None:
                updates.append(f"due_date = ${param_count}")
                values.append(task_update.due_date)
                param_count += 1
            
            if task_update.done is not None:
                updates.append(f"done = ${param_count}")
                values.append(task_update.done)
                param_count += 1
            
            # Always update timestamps
            updates.extend([
                f"updated_at = NOW()",
                f"last_request_timestamp = ${param_count}"
            ])
            values.extend([task_update.request_timestamp, task_id])
            
            if not updates:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="No fields to update"
                )
            
            # Execute update
            row = await connection.fetchrow(
                f"""
                UPDATE tasks
                SET {', '.join(updates)}
                WHERE id = ${param_count + 1}
                RETURNING id, title, content, due_date, done, created_at, updated_at
                """,
                *values
            )
            
            logger.info(f"Updated task {task_id} - correlation_id: {correlation_id}")
            
            return TaskResponse(
                id=row['id'],
                title=row['title'],
                content=row['content'],
                due_date=row['due_date'].isoformat(),
                done=row['done'],
                created_at=row['created_at'],
                updated_at=row['updated_at']
            )
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update task {task_id} - correlation_id: {correlation_id}, error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error"
        )


@app.delete("/tasks/{task_id}", status_code=status.HTTP_200_OK)
async def delete_task(
    task_id: int,
    task_delete: TaskDelete,
    correlation_id: str = Header(...),
    user: dict = Depends(verify_token)
):
    """Delete a task (handles out-of-order requests)"""
    pool = await get_db_pool()
    
    try:
        async with pool.acquire() as connection:
            # Check if task exists and get current timestamp
            current = await connection.fetchrow(
                """
                SELECT id, last_request_timestamp
                FROM tasks
                WHERE id = $1
                """,
                task_id
            )
            
            if not current:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Task not found"
                )
            
            # Handle out-of-order requests
            if task_delete.request_timestamp <= current['last_request_timestamp']:
                logger.warning(
                    f"Ignoring out-of-order delete for task {task_id} - "
                    f"correlation_id: {correlation_id}, "
                    f"request_ts: {task_delete.request_timestamp}, "
                    f"current_ts: {current['last_request_timestamp']}"
                )
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Request timestamp is older than current state"
                )
            
            # Delete the task
            result = await connection.execute(
                "DELETE FROM tasks WHERE id = $1",
                task_id
            )
            
            logger.info(f"Deleted task {task_id} - correlation_id: {correlation_id}")
            
            return {"message": "Task deleted successfully"}
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete task {task_id} - correlation_id: {correlation_id}, error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error"
        )


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=False,
        log_level="info"
    )