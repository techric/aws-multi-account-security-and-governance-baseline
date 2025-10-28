# AWS Multi-Account Security and Governance Baseline

> A professional demonstration of how to implement secure AWS account governance through root isolation, MFA enforcement, least-privilege IAM, and account alias management.

---

## 1. What This Project Shows

### Problem
Many engineers and organizations blur the line between **root ownership** and **operational IAM usage**, creating security and audit risks.  
Common symptoms include unprotected root accounts, weak MFA policies, and unclear ownership structures.

### Solution
This project establishes a **multi-account AWS baseline** using:
- Strict separation between **root** and **IAM administrative roles**.
- Mandatory **multi-factor authentication (MFA)** for all privileged identities.
- Human-readable **account aliases** to improve clarity and login workflow.
- A **read-only sandbox** environment for experimentation and educational use.

### Impact
- Reduced risk of accidental root use or privilege escalation.  
- Simplified administration using aliases and consistent naming.  
- Fully documented and auditable security configuration.  
- Provides a reusable foundation for enterprise or personal multi-account environments.

### Obstacles and Human Factors
| Issue | Cause | Resolution | Lesson |
|-------|--------|-------------|--------|
| Confusion between root and IAM users | Both share the same AWS account ID | Used `aws sts get-caller-identity` to confirm session identity | Always verify ARN type before applying IAM changes |
| MFA login failures | Authenticator configured under wrong alias URL | Re-enrolled MFA under correct alias | MFA tokens are alias-specific |
| Email verification delays | iCloud greylisting of AWS SES mail | Waited ~10 minutes and whitelisted `amazon.com` sender | Cloud mail providers may throttle external verification emails |
| Missing “Enable Console Access” option | AWS Console UI update renamed it to “Manage Console Access” | Located new path under IAM user settings | AWS interfaces evolve; documentation must evolve with them |
| Multiple MFA device confusion | Same phone used for multiple authentications | Consolidated devices into a single app with clear labels | Clear labeling prevents human error and lockouts |

---

## 2. Architecture Overview

High-level design of the account and IAM relationships.

