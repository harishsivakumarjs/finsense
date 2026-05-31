"""
Email delivery service for FinSense.

Environment variables (all read at call-time so Render env vars are always current):
  SMTP_HOST      SMTP server hostname                 e.g. smtp.gmail.com
  SMTP_PORT      SMTP port (default: 587 STARTTLS)
  SMTP_USER      Sender login / from address          e.g. noreply@finsense.app
  SMTP_PASSWORD  SMTP password or Gmail App Password
  SMTP_FROM      Display name + address (optional)    e.g. FinSense <noreply@finsense.app>

DEV MODE:
  If SMTP_HOST, SMTP_USER, or SMTP_PASSWORD is empty the function logs the
  full verification URL to stdout so you can test without a real mail server.
  This is intentional — never silently discard the URL.
"""

import logging
import os
import smtplib
import ssl
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

logger = logging.getLogger(__name__)


def send_verification_email(to_email: str, name: str, verification_url: str) -> None:
    """
    Send an account-verification email.

    Designed to be called as a FastAPI BackgroundTask — never raises so the
    HTTP response is not affected, but every failure mode is logged explicitly.
    """
    smtp_host = os.getenv("SMTP_HOST", "").strip()
    smtp_port_raw = os.getenv("SMTP_PORT", "587").strip()
    smtp_user = os.getenv("SMTP_USER", "").strip()
    smtp_password = os.getenv("SMTP_PASSWORD", "").strip()
    smtp_from = os.getenv("SMTP_FROM", "").strip() or f"FinSense <{smtp_user}>"

    # ── Detect missing config early and surface it clearly ──────────────────
    missing = [k for k, v in [
        ("SMTP_HOST", smtp_host),
        ("SMTP_USER", smtp_user),
        ("SMTP_PASSWORD", smtp_password),
    ] if not v]

    if missing:
        logger.warning(
            "[EMAIL] SMTP not configured — missing env vars: %s. "
            "Verification URL for %s: %s",
            ", ".join(missing), to_email, verification_url,
        )
        # Print to stdout so it appears in Render logs even if logging level is high
        print(
            f"\n[EMAIL DEV] Missing SMTP config: {', '.join(missing)}\n"
            f"[EMAIL DEV] Verification link for {to_email}:\n"
            f"  {verification_url}\n"
        )
        return

    # ── Validate port ───────────────────────────────────────────────────────
    try:
        smtp_port = int(smtp_port_raw)
    except ValueError:
        logger.error("[EMAIL] SMTP_PORT is not a valid integer: %r", smtp_port_raw)
        return

    # ── Build message ───────────────────────────────────────────────────────
    html_body = f"""<!DOCTYPE html>
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

    plain_body = (
        f"Hi {name},\n\n"
        f"Thanks for signing up for FinSense. Please verify your email:\n\n"
        f"  {verification_url}\n\n"
        f"This link expires in 24 hours.\n\n"
        f"If you didn't create a FinSense account, you can safely ignore this email.\n\n"
        f"— The FinSense Team"
    )

    msg = MIMEMultipart("alternative")
    msg["Subject"] = "Verify your FinSense account"
    msg["From"] = smtp_from
    msg["To"] = to_email
    msg.attach(MIMEText(plain_body, "plain"))
    msg.attach(MIMEText(html_body, "html"))

    # ── Send ────────────────────────────────────────────────────────────────
    try:
        context = ssl.create_default_context()
        with smtplib.SMTP(smtp_host, smtp_port, timeout=15) as server:
            server.ehlo()
            server.starttls(context=context)
            server.login(smtp_user, smtp_password)
            server.sendmail(smtp_from, to_email, msg.as_string())
        logger.info("[EMAIL] Verification email sent successfully to %s", to_email)

    except smtplib.SMTPAuthenticationError:
        logger.error(
            "[EMAIL] SMTP authentication failed for user %r — "
            "check SMTP_USER and SMTP_PASSWORD (Gmail: use an App Password, not your account password).",
            smtp_user,
        )
    except smtplib.SMTPConnectError:
        logger.error(
            "[EMAIL] Could not connect to SMTP server %s:%s — "
            "check SMTP_HOST and SMTP_PORT.",
            smtp_host, smtp_port,
        )
    except smtplib.SMTPException as exc:
        logger.error("[EMAIL] SMTP error sending to %s: %s", to_email, exc)
    except OSError as exc:
        logger.error(
            "[EMAIL] Network error reaching %s:%s — %s",
            smtp_host, smtp_port, exc,
        )
    except Exception as exc:
        logger.error("[EMAIL] Unexpected error sending to %s: %s", to_email, exc)
