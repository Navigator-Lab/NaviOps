# Ticket Library — NaviOpsEnterprise

A library of **100+ realistic support tickets** spanning the categories a Help Desk / IT Support
tech works daily. Use them to practice triage and the diagnostic spine, to seed lesson ticket-sims,
and to build the capstone queues (Lessons 34–36).

- **Worked** ✅ = a full ticket file exists in this folder (intake → diagnosis → resolution note).
- **Queued** ⏳ = scenario defined here; flesh into a full file when its lesson lands or during a
  capstone drill.
- All identities are placeholders (`corp.example`, RFC 1918, asset tags) — `navi.project.md` HR#1.

> Priority key: **P1** critical/major-incident · **P2** high · **P3** normal · **P4** low/standard
> request. Type: **INC** incident (broken) · **REQ** request (give/do).

## Worked tickets (full files)
| ID | Title | Cat | Pri | Lesson |
|---|---|---|---|---|
| [ENT-01](ENT-01-account-lockout.md) ✅ | Account locked before client call | Account/Access | P2 | 01 |
| [ENT-02](ENT-02-laptop-no-display.md) ✅ | Laptop powers on, black screen | Hardware | P3 | 02 |
| [ENT-03](ENT-03-bsod-after-update.md) ✅ | BSOD on dock connect after update | OS/Endpoint | P2 | 03 |

## Account & Access (target lessons 07, 18, 20, 21)
| ID | Title | Type | Pri |
|---|---|---|---|
| INC-0101 | Forgot password, can't sign in | INC | P3 |
| INC-0102 | Account locked out repeatedly | INC | P2 |
| INC-0103 | "Your password has expired" with no way to change | INC | P3 |
| REQ-0104 | New employee onboarding — full setup | REQ | P3 |
| REQ-0105 | Employee offboarding — disable & preserve | REQ | P3 |
| REQ-0106 | Add user to the Finance security group | REQ | P3 |
| INC-0107 | Can't access a shared folder they had yesterday | INC | P2 |
| INC-0108 | MFA prompts not arriving on phone | INC | P2 |
| REQ-0109 | Re-enroll MFA after new phone | REQ | P3 |
| INC-0110 | Disabled account still showing as active in app | INC | P3 |
| REQ-0111 | Temporary elevated access for a project | REQ | P4 |
| INC-0112 | Name change after marriage — account + email | INC | P4 |
| INC-0113 | Service account password expired, app down | INC | P1 |
| INC-0114 | User can sign in to PC but not to email | INC | P2 |
| REQ-0115 | Distribution list membership change | REQ | P4 |

## Connectivity & Network (target lessons 08, 09)
| ID | Title | Type | Pri |
|---|---|---|---|
| INC-0201 | No internet on a single PC | INC | P3 |
| INC-0202 | Entire floor lost network at 9am | INC | P1 |
| INC-0203 | Wi-Fi keeps dropping | INC | P3 |
| INC-0204 | Can ping IP but not by name (DNS) | INC | P2 |
| INC-0205 | Got a 169.254 address, no connectivity (DHCP) | INC | P2 |
| INC-0206 | Cannot connect to VPN | INC | P2 |
| INC-0207 | VPN connects but no internal resources | INC | P2 |
| INC-0208 | Slow network only for one app | INC | P3 |
| INC-0209 | New device can't get on the network | INC | P3 |
| INC-0210 | Intermittent connection in a conference room | INC | P3 |
| INC-0211 | Network drive won't reconnect at logon | INC | P3 |
| INC-0212 | DNS resolves to wrong/old server | INC | P2 |

## Hardware & Peripherals (target lessons 02, 06, 10, 24)
| ID | Title | Type | Pri |
|---|---|---|---|
| INC-0301 | Desktop won't power on | INC | P3 |
| INC-0302 | Laptop black screen, fans running | INC | P3 |
| INC-0303 | Laptop won't charge | INC | P3 |
| INC-0304 | Random shutdowns (overheating) | INC | P3 |
| INC-0305 | Disk almost full, can't save | INC | P3 |
| INC-0306 | "No boot device found" | INC | P2 |
| INC-0307 | Printer shows offline | INC | P3 |
| INC-0308 | Print jobs stuck in queue | INC | P3 |
| INC-0309 | Printer prints garbage/wrong driver | INC | P3 |
| REQ-0310 | Install/share a new printer | REQ | P4 |
| INC-0311 | External monitor not detected via dock | INC | P3 |
| INC-0312 | Keyboard/mouse not working | INC | P4 |
| INC-0313 | Webcam not detected in Teams | INC | P3 |
| INC-0314 | USB headset has no audio | INC | P4 |
| INC-0315 | Laptop very hot and loud (dust/fan) | INC | P3 |

## Email & Microsoft 365 (target lessons 11, 13)
| ID | Title | Type | Pri |
|---|---|---|---|
| INC-0401 | Not receiving any email | INC | P2 |
| INC-0402 | Outlook stuck "Trying to connect" | INC | P2 |
| INC-0403 | Outlook keeps asking for password | INC | P3 |
| INC-0404 | Bounce-back / NDR 550 5.1.1 | INC | P3 |
| INC-0405 | Mailbox full, can't send/receive | INC | P3 |
| INC-0406 | Shared mailbox access request | REQ | P4 |
| INC-0407 | Calendar invites not updating | INC | P3 |
| INC-0408 | Email going to junk/spam | INC | P3 |
| REQ-0409 | Set up email on a new phone | REQ | P4 |
| INC-0410 | Sent email shows wrong display name | INC | P4 |
| REQ-0411 | Assign/upgrade an M365 license | REQ | P3 |
| INC-0412 | OneDrive not syncing | INC | P3 |
| INC-0413 | Teams won't load / stuck signing in | INC | P3 |
| INC-0414 | Can't access a SharePoint site | INC | P3 |
| INC-0415 | Deleted important email, needs recovery | INC | P3 |

## Software & Endpoint (target lessons 03, 24, 25, 26)
| ID | Title | Type | Pri |
|---|---|---|---|
| REQ-0501 | Install approved software (catalog) | REQ | P4 |
| REQ-0502 | Install non-standard software (approval) | REQ | P4 |
| INC-0503 | Application crashes on launch | INC | P3 |
| INC-0504 | App very slow / hangs | INC | P3 |
| INC-0505 | "Computer is slow" — general | INC | P3 |
| INC-0506 | BSOD after update | INC | P2 |
| INC-0507 | Windows update fails repeatedly | INC | P3 |
| INC-0508 | Activation/license error in Office | INC | P3 |
| INC-0509 | Browser certificate error on internal site | INC | P3 |
| INC-0510 | Browser extension breaking a web app | INC | P4 |
| INC-0511 | SSO login loop on a SaaS app | INC | P2 |
| REQ-0512 | Uninstall conflicting software | REQ | P4 |
| INC-0513 | Profile corruption — new desktop, missing settings | INC | P3 |
| INC-0514 | Antivirus quarantined a needed file | INC | P3 |
| INC-0515 | PDF won't open / wrong default app | INC | P4 |

## File, Print & Server (target lessons 22, 23)
| ID | Title | Type | Pri |
|---|---|---|---|
| INC-0601 | "Access denied" to a shared drive | INC | P2 |
| REQ-0602 | New shared folder for a team | REQ | P3 |
| INC-0603 | Mapped drive missing | INC | P3 |
| REQ-0604 | Change folder permissions for a user | REQ | P3 |
| INC-0605 | Can open file but can't save (read-only) | INC | P3 |
| INC-0606 | File locked by another user | INC | P3 |
| INC-0607 | Server share unreachable (whole team) | INC | P1 |
| INC-0608 | Slow file access from one site | INC | P3 |
| INC-0609 | Accidentally deleted shared file | INC | P3 |
| INC-0610 | Print server not accepting jobs | INC | P2 |

## Security & Awareness (target lesson 29)
| ID | Title | Type | Pri |
|---|---|---|---|
| INC-0701 | User clicked phishing link & entered password | INC | P1 |
| INC-0702 | Suspicious email — is it phishing? | INC | P3 |
| INC-0703 | Repeated unexpected MFA prompts (MFA fatigue) | INC | P2 |
| INC-0704 | Lost/stolen laptop | INC | P1 |
| INC-0705 | Caller requesting reset can't verify identity | INC | P3 |
| INC-0706 | Ransomware note on a file share | INC | P1 |
| INC-0707 | Unknown device on user's account | INC | P2 |
| INC-0708 | USB drive found, plugged in | INC | P3 |
| INC-0709 | Mailbox auto-forwarding to external (suspicious) | INC | P1 |
| INC-0710 | CEO impersonation / gift-card request | INC | P2 |

## Service-Desk Process & Requests (target lessons 15, 16, 17, 27, 30, 33)
| ID | Title | Type | Pri |
|---|---|---|---|
| REQ-0801 | New hardware request (laptop) | REQ | P4 |
| REQ-0802 | Loaner device while in repair | REQ | P3 |
| REQ-0803 | Restore a file from backup | REQ | P3 |
| REQ-0804 | Asset transfer to a new owner | REQ | P4 |
| REQ-0805 | Decommission/wipe a returned device | REQ | P4 |
| REQ-0806 | Conference-room AV not working before meeting | INC | P2 |
| REQ-0807 | Mobile device enrollment | REQ | P4 |
| REQ-0808 | Bulk onboarding (5 new hires Monday) | REQ | P3 |
| REQ-0809 | Software license true-up / report | REQ | P4 |
| REQ-0810 | Recurring report request automated | REQ | P4 |
| INC-0811 | Major incident: email down org-wide | INC | P1 |
| INC-0812 | Repeated incidents → raise a Problem | INC | P3 |
| REQ-0813 | Access review / recertification | REQ | P4 |
| REQ-0814 | Change request: deploy new app to a ring | REQ | P3 |
| REQ-0815 | Backup restore test (DR drill) | REQ | P4 |

---

### How to flesh out a queued ticket
Copy `docs/templates/ticket-note.md`, fill intake → diagnosis → resolution using the diagnostic
spine, save as `docs/tickets/<ID>-<slug>.md`, and mark it ✅ here. Capstone 34 fleshes ~50 of these
into a graded queue with a metrics report.

**Count:** 3 worked + 100 queued = **103 tickets** defined (target ≥100 met; depth grows per lesson).
