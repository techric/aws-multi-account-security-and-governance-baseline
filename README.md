# AWS Multi-Account Security and Governance Baseline

> A professional demonstration of how to implement secure AWS account governance through root isolation, MFA enforcement, least-privilege IAM, and account alias management.

---

## 0. What This Project Shows

### Problem
Many engineers and organizations blur the line between **root ownership** and **operational IAM usage**, creating security and audit risks.  
Common symptoms include unprotected root accounts, weak MFA policies, and unclear ownership structures.

When I first started my AWS journey, I created two separate AWS accounts. I did this BEFORE I fully understood the difference between root users and subordinate IAM accounts. So, for this project, I am hardening both my Primary Account (PA) and my Sandbox Account (SA). 

NOTE: I've changed the names of my accounts to keep them anonymous. 

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
## 1. Quickstart Guide - A practical walkthrough demonstrating how to configure secure AWS account aliases, IAM users, and MFA-based access control across multiple root accounts.

a. Copy and configure the environment file  
   ```bash
   cp env/.env.example env/.env
   # Open the env/.env and replace the placeholders with your real values.
   # Required fields: ACCOUNT_ALIAS, ADMIN_USER, READONLY_USER, TEMP passwords.
```

b. Run the script

```
bash scripts/aws-cli-setup-commands.sh

```
c. Verify your configuration
```
aws sts get-caller-identity
aws iam list-account-aliases
aws iam list-users
```

The sign-in URL pattern should look like this. AWS refers to this as the account's "alias". 
```
https://<ACCOUNT_ALIAS>.signin.aws.amazon.com/console
```
---

d. Quickstart Implementation Steps
   1. Verified identity and privileges using ``` aws sts get-caller-identity ```.
   2. Created account alias (``` ACCOUNT_ALIAS ```) via AWS CLI.
   3. Configured IAM users for:
      - Admin user with ``` AdministratorAccess ```
      - Read-only user with ``` ReadOnlyAccess ```
   4. Applied MFA to both IAM users and the root user.
   5. Validated access by signing in through the alias URL.

---

## 2. Architecture Overview

The following diagram illustrates the high-level relationships among accounts, users, and privileges.
```
PrimaryAccount (PA)
├── Root-PA (MFA, isolated)
└── AdminUser-PA (AdministratorAccess)

SandboxAccount (SA)
├── Root-SA (MFA, isolated)
├── AdminUser-SA (AdministratorAccess)
└── ReadOnlyUser-SA (ReadOnlyAccess, MFA)
```

Each account enforces MFA for both root and IAM identities. Root users are reserved exclusively for ownership and billing tasks. All administrative and testing activities occur under subordinate IAM users.

---

## 3. Implementation Details

### Key Deliverables
| Task | Description | Tools and Commands | Outcome |
|------|--------------|-------------------|----------|
| Root Hardening | Enabled MFA | AWS Console and CLI | Root users fully secured |
| Account Aliasing | Created descriptive aliases for sign-in | `aws iam create-account-alias` | Simplified human-readable login URLs |
| IAM User Creation | Added `AdminUser` with AdministratorAccess (all operations except account-level ownership) | Console and CLI | Operational account established |
| Read-Only Sandbox | Created `ReadOnlyUser` for testing | `aws iam attach-user-policy` | Safe, restricted environment for education |
| MFA Configuration | Configured MFA for all privileged users | Console | Enforced multi-factor authentication |
| CLI Validation | Verified caller identity and alias mapping | `aws sts get-caller-identity`, `aws iam list-account-aliases` | Confirmed correct identity and permissions context |

---

## 4. Screenshots (Proof of Work)

Recommended visual documentation for the project:
1. IAM dashboard showing created **account aliases**.  
2. IAM **Users** page listing `AdminUser` and `ReadOnlyUser`.  
3. MFA configuration screens for both IAM and root identities.  
4. CLI terminal output of `aws sts get-caller-identity` showing root and IAM sessions.  
5. Console view of `aws iam list-account-aliases` results confirming alias creation.

All screenshots should be redacted to hide account IDs and personal information before publishing.

---

## 5. Technologies and Services Used
- AWS Identity and Access Management (IAM)  
- AWS Security Token Service (STS)  
- AWS Command Line Interface (CLI)  
- macOS environment with email for verification testing
- TOTP mobile applications to store security tokens
  
---

## 6. Cost Considerations
- This project was executed entirely within the AWS Free Tier.  
- All temporary users, aliases, and policies that were not needed were deleted. The accounts are otherwise live.   
- No ongoing charges remain associated with the accounts used for this demonstration.

---

## 7. Repository Structure

aws-multi-account-security-and-governance-baseline/

```

├── README.md
├── env/
│   └── .env 
├── docs/
│ ├── architecture/
│ │ └── aws-account-architecture.png
│ ├── screenshots/
│ │ ├── alias-confirmation.png
│ │ ├── iam-users.png
│ │ ├── mfa-setup.png
│ │ ├── cli-root-session.png
│ │ └── cli-iam-session.png
│ └── troubleshooting-report.md
└── scripts/
  └── aws-cli-setup-commands.sh

```



---

## 8. Key Takeaways
- The root account should only serve as an ownership and billing mechanism.  
- MFA must be enabled for all users with administrative privileges. I used a TOTP app on a device to store the keys.  
- Account aliases simplify sign-in and reinforce identity clarity.  
- Clear documentation and reproducible steps demonstrate governance maturity.  
- This security baseline is ready for expansion into AWS Organizations or Terraform-based automation.

---

**Author:** CloudEngineer (alias)  
**Role:** Cloud and DevSecOps Engineer  
**Date:** October 2025  
**Status:** Completed – Security Baseline Ready


