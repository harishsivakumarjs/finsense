from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional
from datetime import datetime
import uuid


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    name: str
    mode: str = "student"

    @field_validator("mode")
    @classmethod
    def validate_mode(cls, v):
        if v not in ("student", "earner"):
            raise ValueError("mode must be 'student' or 'earner'")
        return v

    @field_validator("password")
    @classmethod
    def validate_password(cls, v):
        if len(v) < 6:
            raise ValueError("Password must be at least 6 characters")
        return v


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserOut(BaseModel):
    id: uuid.UUID
    email: str
    name: str
    mobile: Optional[str] = None
    photo: Optional[str] = None
    mode: str
    email_verified: bool = False
    created_at: datetime

    model_config = {"from_attributes": True}


class RegisterResponse(BaseModel):
    message: str
    email: str


class ResendVerificationPayload(BaseModel):
    email: EmailStr


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class ModeUpdate(BaseModel):
    mode: str

    @field_validator("mode")
    @classmethod
    def validate_mode(cls, v):
        if v not in ("student", "earner"):
            raise ValueError("mode must be 'student' or 'earner'")
        return v


class ProfileUpdate(BaseModel):
    mobile: Optional[str] = None
    photo: Optional[str] = None


class PasswordUpdate(BaseModel):
    current_password: str
    new_password: str

    @field_validator("new_password")
    @classmethod
    def validate_new_password(cls, v):
        if len(v) < 6:
            raise ValueError("Password must be at least 6 characters")
        return v


class FirebaseAuthPayload(BaseModel):
    id_token: str
