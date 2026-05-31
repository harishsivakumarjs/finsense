"""
Email delivery service for FinSense.

Priority order:
  1. Resend API  (set RESEND_API_KEY — easiest, free tier at resend.com)
  2. SMTP        (set SMTP_HOST + SMTP_USER + SMTP_PASSWORD)
  3. Dev mode    (no credentials → prints URL to console/Render logs)

Resend setup (5 minutes):
  1. Sign up at https://resend.com  (free: 3,000 emails/month)
  2. Create an API key
  3. Set RESEND_API_KEY=re_xxxx in Render environment variables
  4. Optionally set SMTP_FROM=FinSense <you@yourdomain.com>
     (leave blank to use the Resend default sender)

SMTP setup (Gmail):
  SMTP_HOST=smtp.gmail.com  SMTP_PORT=587
  SMTP_USER=you@gmail.com
  SMTP_PASSWORD=<App Password — NOT your Gmail login password>
  Enable: Google Account → Security → 2-Step Verification → App Passwords
"""

import logging
import os
import smtplib
import ssl
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

logger = logging.getLogger(__name__)


# ── Shared email content ──────────────────────────────────────────────────────

def _build_bodies(name: str, verification_url: str) -> tuple[str, str]:
    """Return (plain_text, html) for the verification email."""
    html = f"""<!DOCTYPE html>
<html lang="en">
<body style="margin:0;padding:0;background:#f7f9fc;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f7f9fc;padding:40px 0;">
    <tr><td align="center">
      <table width="520" cellpadding="0" cellspacing="0"
             style="background:#ffffff;border-radius:16px;padding:40px;border:1px solid #eceef1;
                    box-shadow:0 4px 24px rgba(0,0,0,0.06);">
        <tr><td align="center" style="padding-bottom:28px;">
          <table cellpadding="0" cellspacing="0"><tr>
            <td style="background:#2AB5A0;width:40px;height:40px;border-radius:10px;
                       text-align:center;vertical-align:middle;
                       font-weight:800;font-size:18px;color:#ffffff;">F</td>
            <td style="padding-left:10px;font-size:18px;font-weight:700;color:#191c1e;">FinSense</td>
          </tr></table>
        </td></tr>
        <tr><td style="text-align:center;padding-bottom:8px;">
          <h1 style="margin:0;font-size:22px;font-weight:700;color:#191c1e;">Verify your email address</h1>
        </td></tr>
        <tr><td style="text-align:center;padding-bottom:28px;">
          <p style="margin:0;color:#8BA8C8;font-size:14px;">Hi {name}, thanks for signing up for FinSense.</p>
        </td></tr>
        <tr><td align="center" style="padding-bottom:28px;">
          <a href="{verification_url}"
             style="display:inline-block;background:#2AB5A0;color:#ffffff;
                    padding:14px 36px;border-radius:10px;font-size:15px;
                    font-weight:600;text-decoration:none;">
            Verify Email Address
          </a>
        </td></tr>
        <tr><td style="padding-bottom:24px;">
          <p style="margin:0 0 8px;color:#3d4946;font-size:13px;">
            If the button doesn't work, paste this link into your browser:
          </p>
          <p style="margin:0;word-break:break-all;">
            <a href="{verification_url}" style="color:#2AB5A0;font-size:12px;">{verification_url}</a>
          </p>
        </td></tr>
        <tr><td>
          <hr style="border:none;border-top:1px solid #eceef1;margin-bottom:20px;">
          <p style="margin:0;color:#8BA8C8;font-size:12px;text-align:center;">
            This link expires in <strong>24 hours</strong>.
            If you didn't create a FinSense account, you can safely ignore this email.
          </p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>"""

    plain = (
        f"Hi {name},\n\n"
        f"Thanks for signing up for FinSense. Please verify your email:\n\n"
        f"  {verification_url}\n\n"
        f"This link expires in 24 hours.\n\n"
        f"If you didn't create a FinSense account, you can safely ignore this email.\n\n"
        f"— The FinSense Team"
    )
    return plain, html


# ── Delivery methods ──────────────────────────────────────────────────────────

def _send_via_resend(to_email: str, from_addr: str, plain: str, html: str) -> bool:
    """Try to send via the Resend API. Returns True on success."""
    api_key = os.getenv("RESEND_API_KEY", "").strip()
    if not api_key:
        return False

    try:
        import httpx
        resp = httpx.post(
            "https://api.resend.com/emails",
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
            json={
                "from": from_addr,
                "to": [to_email],
                "subject": "Verify your FinSense account",
                "html": html,
                "text": plain,
            },
            timeout=15.0,
        )
        if resp.status_code in (200, 201):
            logger.info("[EMAIL] Sent via Resend to %s (id=%s)",
                        to_email, resp.json().get("id", "?"))
            return True
        logger.error("[EMAIL] Resend API returned %s: %s", resp.status_code, resp.text)
        return False
    except Exception as exc:
        logger.error("[EMAIL] Resend exception: %s", exc)
        return False


def _send_via_smtp(to_email: str, from_addr: str, plain: str, html: str) -> bool:
    """Try to send via SMTP (STARTTLS on port 587). Returns True on success."""
    smtp_host = os.getenv("SMTP_HOST", "").strip()
    smtp_user = os.getenv("SMTP_USER", "").strip()
    smtp_password = os.getenv("SMTP_PASSWORD", "").strip()

    if not smtp_host or not smtp_user or not smtp_password:
        return False  # not configured — caller will fall through to dev mode

    smtp_port_raw = os.getenv("SMTP_PORT", "587").strip()
    try:
        smtp_port = int(smtp_port_raw)
    except ValueError:
        logger.error("[EMAIL] SMTP_PORT is not a valid integer: %r", smtp_port_raw)
        return False

    msg = MIMEMultipart("alternative")
    msg["Subject"] = "Verify your FinSense account"
    msg["From"] = from_addr
    msg["To"] = to_email
    msg.attach(MIMEText(plain, "plain"))
    msg.attach(MIMEText(html, "html"))

    try:
        context = ssl.create_default_context()
        with smtplib.SMTP(smtp_host, smtp_port, timeout=15) as server:
            server.ehlo()
            server.starttls(context=context)
            server.login(smtp_user, smtp_password)
            server.sendmail(from_addr, to_email, msg.as_string())
        logger.info("[EMAIL] Sent via SMTP to %s", to_email)
        return True
    except smtplib.SMTPAuthenticationError:
        logger.error(
            "[EMAIL] SMTP authentication failed for %r — "
            "Gmail users: use an App Password, not your account password. "
            "Enable at: Google Account → Security → 2-Step Verification → App Passwords.",
            smtp_user,
        )
    except smtplib.SMTPConnectError:
        logger.error("[EMAIL] Cannot connect to SMTP server %s:%s — check SMTP_HOST / SMTP_PORT.", smtp_host, smtp_port)
    except OSError as exc:
        logger.error("[EMAIL] Network error reaching %s:%s — %s", smtp_host, smtp_port, exc)
    except smtplib.SMTPException as exc:
        logger.error("[EMAIL] SMTP error: %s", exc)
    return False


# ── Public API ────────────────────────────────────────────────────────────────

def is_email_configured() -> bool:
    """Return True if at least one delivery method is configured."""
    return bool(
        os.getenv("RESEND_API_KEY", "").strip()
        or (
            os.getenv("SMTP_HOST", "").strip()
            and os.getenv("SMTP_USER", "").strip()
            and os.getenv("SMTP_PASSWORD", "").strip()
        )
    )


def send_verification_email(to_email: str, name: str, verification_url: str) -> None:
    """
    Send the account-verification email.

    Safe to call as a FastAPI BackgroundTask — never raises.
    Tries Resend first, then SMTP, then logs to console (dev mode).
    """
    from_addr = (
        os.getenv("SMTP_FROM", "").strip()
        or os.getenv("RESEND_FROM", "").strip()
        or "FinSense <onboarding@resend.dev>"
    )
    plain, html = _build_bodies(name, verification_url)

    # 1. Try Resend
    if _send_via_resend(to_email, from_addr, plain, html):
        return

    # 2. Try SMTP
    if _send_via_smtp(to_email, from_addr, plain, html):
        return

    # 3. Dev / fallback — log the URL so it's visible in Render logs
    logger.warning(
        "[EMAIL] No email delivery configured (set RESEND_API_KEY or SMTP_* env vars). "
        "Verification link for %s: %s",
        to_email, verification_url,
    )
    print(
        f"\n[EMAIL DEV] No delivery config found.\n"
        f"[EMAIL DEV] Verification link for {to_email}:\n"
        f"  {verification_url}\n"
    )
