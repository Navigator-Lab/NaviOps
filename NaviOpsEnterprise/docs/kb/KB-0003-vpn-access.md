# Connect to the VPN

**Applies to:** staff working remotely on a company laptop · **KB ID:** KB-0003
**Last reviewed:** 2026-06-21 · **Owner:** Service Desk

## What this covers
How to connect to the company VPN so you can reach internal resources (file shares, intranet,
line-of-business apps) from outside the office.

## Before you start
- You need: a working **internet connection**, your **company sign-in**, and your **MFA** method.
- The VPN client (**Corp VPN**) is pre-installed on company laptops. If it's missing, request it
  (KB-0008) — don't install a personal VPN.

## Connect
1. Make sure you have **internet** first (open a website). The VPN runs *on top of* your internet.
2. Open **Corp VPN** from the Start menu (or the system-tray icon, bottom-right).
3. Click **Connect** (the server `vpn.corp.example` is pre-filled).
4. Sign in with your work email + password, then **approve the MFA prompt**.
5. The icon turns **green / "Connected."** You can now reach internal sites like
   `intranet.corp.example`.

## When you're done
Click **Disconnect** when you no longer need internal resources (saves bandwidth and is good
practice).

## Still not working?

| What you see | Try this |
|---|---|
| Won't connect at all | Confirm normal internet works first; restart the VPN app; restart the laptop |
| "Authentication failed" | Your password may have changed — sign in to email to confirm it works (KB-0001); re-approve MFA |
| Connected but can't reach internal sites | Disconnect/reconnect; check you're using the internal name (`intranet.corp.example`) |
| MFA prompt never arrives | See KB-0010 (Microsoft 365 / MFA issues) |

If it still fails, contact the Service Desk with: your location, your internet status (working?),
and the exact error from the VPN app. Reference **KB-0003**.

## Related
- Wi-Fi troubleshooting (KB-0004) · [Reset your password](KB-0001-password-reset.md) ·
  Microsoft 365 common issues (KB-0010)
