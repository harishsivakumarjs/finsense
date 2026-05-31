"""
Email delivery service for FinSense.

Configuration (all via environment variables):
  SMTP_HOST      SMTP server hostname            e.g. smtp.gmail.com
  SMTP_PORT      SMTP port (default: 587)        e.g. 587
  SMTP_USER      Sender login / from address     e.g. noreply@finsense.app
  SMTP_PASSWORD  SMTP password or App Password
  SMTP_FROM      Display name + address          e.g. FinSense <noreply@finsense.app>

If SMTP_HOST or SMTP_USER are not set the function logs the URL and returns
immediately so local dev works without email credentials.
"""

import logging
import os
import smtplib
import ssl
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

logger = logging.getLogger(__name__)


def send_verification_email(to_email: str, name: str, verification_url: str) -> None:
    """Send an account-verification email. Safe to call as a background task."""
    smtp_host = os.getenv("SMTP_HOST", "")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_user = os.getenv("SMTP_USER", "")
    smtp_password = os.getenv("SMTP_PASSWORD", "")
    smtp_from = os.getenv("SMTP_FROM", f"FinSense <{smtp_user}>") if smtp_user else "FinSense"

    if not smtp_host or not smtp_user or not smtp_password:
        # Dev / CI fallback: print the URL so it can be tested without an SMTP server
        logger.info("[EMAIL DEV] Verification link for %s: %s", to_email, verification_url)
        print(f"\n[EMAIL DEV] Verification link for {to_email}:\n  {verification_url}\n")
        return

    html_body = f"""<!DOCTYPE html>
<html lang="en">
<body style="margin:0;padding:0;background:#f7f9fc;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f7f9fc;padding:40px 0;">
    <tr><td align="center">
      <table width="520" cellpadding="0" cellspacing="0"
             style="background:#ffffff;border-radius:16px;padding:40px;border:1px solid #eceef1;
                    box-shadow:0 4px 24px rgba(0,0,0,0.06);">
        <!-- Logo -->
        <tr><td align="center" style="padding-bottom:28px;">
          <table cellpadding="0" cellspacing="0"><tr>
            <td style="background:#2AB5A0;width:40px;height:40px;border-radius:10px;
                       text-align:center;vertical-align:middle;
                       font-weight:800;font-size:18px;color:#ffffff;">F</td>
            <td style="padding-left:10px;font-size:18px;font-weight:700;color:#191c1e;">FinSense</td>
          </tr></table>
        </td></tr>

        <!-- Heading -->
        <tr><td style="text-align:center;padding-bottom:8px;">
          <h1 style="margin:0;font-size:22px;font-weight:700;color:#191c1e;">Verify your email address</h1>
        </td></tr>
        <tr><td style="text-align:center;padding-bottom:28px;">
          <p style="margin:0;color:#8BA8C8;font-size:14px;">
            Hi {name}, thanks for signing up for FinSense.
          </p>
        </td></tr>

        <!-- CTA button -->
        <tr><td align="center" style="padding-bottom:28px;">
          <a href="{verification_url}"
             style="display:inline-block;background:#2AB5A0;color:#ffffff;
                    padding:14px 36px;border-radius:10px;font-size:15px;
                    font-weight:600;text-decoration:none;">
            Verify Email Address
          </a>
        </td></tr>

        <!-- Fallback URL -->
        <tr><td style="padding-bottom:24px;">
          <p style="margin:0 0 8px;color:#3d4946;font-size:13px;">
            If the button doesn't work, paste this link into your browser:
          </p>
          <p style="margin:0;word-break:break-all;">
            <a href="{verification_url}" style="color:#2AB5A0;font-size:12px;">{verification_url}</a>
          </p>
        </td></tr>

        <!-- Footer note -->
        <tr><td>
          <hr style="border:none;border-top:1px solid #eceef1;margin-bottom:20px;">
          <p style="margin:0;color:#8BA8C8;font-size:12px;text-align:center;">
            This link expires in <strong>24 hours</strong>. If you didn't create a FinSense account,
            you can safely ignore this email.
          </p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>"""

    plain_body = (
        f"Hi {name},\n\n"
        f"Thanks for signing up for FinSense. Please verify your email address by visiting:\n\n"
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

    try:
        context = ssl.create_default_context()
        with smtplib.SMTP(smtp_host, smtp_port, timeout=10) as server:
            server.ehlo()
            server.starttls(context=context)
            server.login(smtp_user, smtp_password)
            server.sendmail(smtp_from, to_email, msg.as_string())
        logger.info("Verification email sent to %s", to_email)
    except Exception as exc:
        logger.error("Failed to send verification email to %s: %s", to_email, exc)
