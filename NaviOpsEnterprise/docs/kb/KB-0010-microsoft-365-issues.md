# Microsoft 365 common issues

**Applies to:** all staff using Microsoft 365 (Outlook, Teams, OneDrive, SharePoint) · **KB ID:** KB-0010
**Last reviewed:** 2026-06-21 · **Owner:** Service Desk

## What this covers
Quick fixes for the most common Microsoft 365 problems: signing in, MFA on a new phone, OneDrive sync, and
Teams.

## Can't sign in to Microsoft 365 / Office
1. Confirm your password works at **https://outlook.office.com** (if not, [reset it](KB-0001-password-reset.md)).
2. Approve the **MFA** prompt. If prompts aren't arriving, see "New phone" below.
3. If you see **"your sign-in was blocked"** from an unusual location/device, that may be a security policy
   — contact the desk; don't keep retrying.

## New phone / MFA prompts not arriving
If your authenticator was on your **old** phone, you can't approve prompts on the new one. Contact the
Service Desk to **reset your MFA registration**; they'll verify your identity, then you set up the
**Microsoft Authenticator** app on the new phone at **https://aka.ms/mfasetup**.

> ⚠️ **Getting MFA prompts you didn't request?** **Don't approve them** — someone may have your password.
> **Deny** the prompt and **report it** to the Service Desk immediately.

## OneDrive isn't syncing
1. Check the **OneDrive cloud icon** (bottom-right) — is it **paused** or showing an error? Click it →
   **Resume syncing**.
2. Make sure you're **signed in** to OneDrive with your work account and have **internet** (KB-0004).
3. Still stuck → restart OneDrive (close it from the tray, reopen from Start).

## Teams won't load / stuck signing in
1. **Quit and reopen** Teams; if still stuck, **restart the laptop**.
2. Try Teams on the **web** (https://teams.microsoft.com) to confirm it's the app, not your account.
3. Persistent → contact the desk (a cache reset may be needed).

## "No mailbox" / Office says "unlicensed"
This usually means your account is missing a **license** — contact the Service Desk to have it assigned
(common for brand-new starters).

## Still not working?
Contact the Service Desk with: **which app**, the **exact message**, and whether **webmail/Teams-web**
works. Reference **KB-0010**.

## Related
- [Reset your password](KB-0001-password-reset.md) · [Unlock your account](KB-0002-account-unlock.md) ·
  [Email/Outlook troubleshooting](KB-0005-email-troubleshooting.md) · [VPN](KB-0003-vpn-access.md)
