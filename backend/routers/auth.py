import os
import secrets
from datetime import datetime, timedelta
from typing import Optional
import uuid

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status, Response
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from passlib.context import CryptContext
from dotenv import load_dotenv

from database import get_db
from models import (
    User, IncomeEntry, Expense, Loan, CreditCard, Trade, TradingLossCarryforward,
    Investment, CreatorIncome, FriendLedger, NetWorthSnapshot, Goal,
    TaxDeduction, AdvanceTaxPayment, InsurancePolicy,
)
from schemas.auth import (
    UserCreate, UserLogin, UserOut, Token, ModeUpdate, ProfileUpdate,
    PasswordUpdate, FirebaseAuthPayload, RegisterResponse, ResendVerificationPayload,
)
from services.email_service import send_verification_email

load_dotenv()

router = APIRouter(prefix="/api/auth", tags=["auth"])

JWT_SECRET = os.getenv("JWT_SECRET", "super-secret-key-change-in-production-min-32")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
JWT_EXPIRE_HOURS = int(os.getenv("JWT_EXPIRE_HOURS", "24"))
FIREBASE_WEB_API_KEY = os.getenv("FIREBASE_WEB_API_KEY", "AIzaSyAX3Iw8m-ax9o5hbLXlXcoz8hvbWRloQqI")
FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:5173")
VERIFICATION_TOKEN_TTL_HOURS = 24

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
bearer_scheme = HTTPBearer(auto_error=False)


# ── Helpers ──────────────────────────────────────────────────────────────────

def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_access_token(user_id: str, email: str) -> str:
    expire = datetime.utcnow() + timedelta(hours=JWT_EXPIRE_HOURS)
    payload = {"sub": str(user_id), "email": email, "exp": expire}
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def _generate_verification_token() -> tuple[str, datetime]:
    """Return (token, expires_at) pair."""
    token = secrets.token_urlsafe(32)
    expires_at = datetime.utcnow() + timedelta(hours=VERIFICATION_TOKEN_TTL_HOURS)
    return token, expires_at


def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    if credentials is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    token = credentials.credentials
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        user_id = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")
    return user


# ── Email / Password endpoints ────────────────────────────────────────────────

@router.post("/register", response_model=RegisterResponse, status_code=201)
def register(
    payload: UserCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    """
    Create a new email/password account.
    Returns a message only — no JWT is issued until the email is verified.
    """
    if db.query(User).filter(User.email == payload.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    token, expires_at = _generate_verification_token()

    user = User(
        email=payload.email,
        password_hash=hash_password(payload.password),
        name=payload.name,
        mode=payload.mode,
        email_verified=False,
        verification_token=token,
        verification_token_expires_at=expires_at,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    verification_url = f"{FRONTEND_URL}/verify-email?token={token}"
    background_tasks.add_task(send_verification_email, user.email, user.name, verification_url)

    return RegisterResponse(
        message="Account created successfully. Please verify your email before signing in.",
        email=user.email,
    )


@router.post("/login", response_model=Token)
def login(payload: UserLogin, response: Response, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email).first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    if not user.email_verified:
        raise HTTPException(
            status_code=403,
            detail="Please verify your email before signing in. Check your inbox or request a new verification email.",
        )

    token = create_access_token(str(user.id), user.email)
    response.set_cookie(
        key="access_token",
        value=token,
        httponly=True,
        max_age=JWT_EXPIRE_HOURS * 3600,
        samesite="lax",
    )
    return Token(access_token=token, user=UserOut.model_validate(user))


@router.get("/verify-email")
def verify_email(token: str, db: Session = Depends(get_db)):
    """
    Called when the user clicks the link in the verification email.
    Marks the account as verified and clears the token.
    """
    user = db.query(User).filter(User.verification_token == token).first()
    if not user:
        raise HTTPException(status_code=400, detail="Invalid or expired verification link.")

    if user.email_verified:
        return {"message": "Email already verified. You can sign in."}

    if (
        user.verification_token_expires_at is not None
        and user.verification_token_expires_at < datetime.utcnow()
    ):
        raise HTTPException(
            status_code=400,
            detail="This verification link has expired. Please request a new one.",
        )

    user.email_verified = True
    user.verification_token = None
    user.verification_token_expires_at = None
    db.commit()

    return {"message": "Email verified successfully! You can now sign in to FinSense."}


@router.post("/resend-verification")
def resend_verification(
    payload: ResendVerificationPayload,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    """
    Generate a fresh token and resend the verification email.
    Always returns a vague success message to avoid email enumeration.
    """
    user = db.query(User).filter(User.email == payload.email).first()

    # Vague response when email not found (don't reveal account existence)
    if not user:
        return {"message": "If that email is registered, a verification link has been sent."}

    if user.email_verified:
        return {"message": "Email is already verified. You can sign in."}

    token, expires_at = _generate_verification_token()
    user.verification_token = token
    user.verification_token_expires_at = expires_at
    db.commit()

    verification_url = f"{FRONTEND_URL}/verify-email?token={token}"
    background_tasks.add_task(send_verification_email, user.email, user.name, verification_url)

    return {"message": "Verification email sent. Check your inbox."}


# ── Google / Firebase endpoint ────────────────────────────────────────────────

@router.post("/google/firebase", response_model=Token)
def google_firebase_login(payload: FirebaseAuthPayload, db: Session = Depends(get_db)):
    """
    Verify a Firebase ID token (from Google Sign-In) and return a FinSense JWT.
    Google accounts are always considered email-verified.
    Creates the DB user on first sign-in.
    """
    import httpx as _httpx
    try:
        resp = _httpx.post(
            f"https://identitytoolkit.googleapis.com/v1/accounts:lookup?key={FIREBASE_WEB_API_KEY}",
            json={"idToken": payload.id_token},
            timeout=10.0,
        )
    except _httpx.RequestError:
        raise HTTPException(status_code=503, detail="Firebase verification service unreachable")

    if resp.status_code != 200:
        raise HTTPException(status_code=401, detail="Invalid or expired Google token")

    firebase_users = resp.json().get("users", [])
    if not firebase_users:
        raise HTTPException(status_code=401, detail="Google token verification failed")

    fb = firebase_users[0]
    email = fb.get("email")
    if not email:
        raise HTTPException(status_code=400, detail="Google account has no email address")

    name = fb.get("displayName") or email.split("@")[0]
    photo = fb.get("photoUrl")

    user = db.query(User).filter(User.email == email).first()
    if not user:
        user = User(
            email=email,
            password_hash=hash_password(str(uuid.uuid4())),
            name=name,
            photo=photo,
            mode="earner",
            email_verified=True,  # Google accounts are auto-verified
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    else:
        changed = False
        if not user.email_verified:
            user.email_verified = True
            changed = True
        if photo and not user.photo:
            user.photo = photo
            changed = True
        if changed:
            db.commit()
            db.refresh(user)

    token = create_access_token(str(user.id), user.email)
    return Token(access_token=token, user=UserOut.model_validate(user))


# ── Session endpoints ─────────────────────────────────────────────────────────

@router.post("/logout")
def logout(response: Response):
    response.delete_cookie("access_token")
    return {"message": "Logged out successfully"}


@router.get("/me", response_model=UserOut)
def get_me(current_user: User = Depends(get_current_user)):
    return UserOut.model_validate(current_user)


# ── Profile endpoints ─────────────────────────────────────────────────────────

@router.put("/mode", response_model=UserOut)
def update_mode(
    payload: ModeUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    current_user.mode = payload.mode
    db.commit()
    db.refresh(current_user)
    return UserOut.model_validate(current_user)


@router.put("/profile", response_model=UserOut)
def update_profile(
    payload: ProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if payload.mobile is not None:
        current_user.mobile = payload.mobile
    if payload.photo is not None:
        current_user.photo = payload.photo
    db.commit()
    db.refresh(current_user)
    return UserOut.model_validate(current_user)


@router.put("/password")
def update_password(
    payload: PasswordUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not verify_password(payload.current_password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    current_user.password_hash = hash_password(payload.new_password)
    db.commit()
    return {"message": "Password updated successfully"}


# ── Account management ────────────────────────────────────────────────────────

@router.delete("/data")
def clear_all_data(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    uid = current_user.id
    for Model in [
        AdvanceTaxPayment, TaxDeduction, Goal, NetWorthSnapshot,
        InsurancePolicy, FriendLedger, CreatorIncome,
        TradingLossCarryforward, Trade, Investment,
        CreditCard, Loan, Expense, IncomeEntry,
    ]:
        db.query(Model).filter(Model.user_id == uid).delete(synchronize_session=False)
    db.commit()
    return {"message": "All data cleared"}


@router.delete("/account")
def delete_account(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    db.delete(current_user)
    db.commit()
    return {"message": "Account deleted"}
