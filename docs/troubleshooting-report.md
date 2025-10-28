# Troubleshooting Report  
**Project:** AWS Multi-Account Security and Governance Baseline  
**Author:** Techric  
**Date:** October 2025  

---
## Executive Summary

During the setup of multiple AWS accounts and IAM security baselines, several operational and human-factor issues were encountered — including identity confusion, MFA misconfiguration, and residual VPC resources causing unexpected billing.  
Each problem was diagnosed using AWS CLI tools (`sts`, `iam`, `ec2`) and resolved through methodical verification and cleanup.  
This troubleshooting cycle demonstrates practical cloud engineering discipline: validating assumptions, interpreting error messages, and restoring a secure, zero-cost baseline environment.

---

## Overview

This document summarizes issues encountered during the configuration of AWS root and IAM accounts, alias creation, and MFA integration.  
The purpose is to demonstrate diagnostic reasoning and operational resilience when working with real AWS infrastructure.

---

## 1. Root vs. IAM Identity Confusion

**Symptom:**  

`aws sts get-caller-identity` returned an ARN ending in `:root`. The root and IAM accounts had the same name. Initially, the account owner could not determine whether they were in the root account or an IAM account. 

**Cause:**  
Session credentials belonged to the root account as intended. 

**Resolution:**  
- Logged out of all AWS Console sessions.  
- Re-authenticated using the correct IAM alias URL.  
- Confirmed active session identity via:

  ```bash
  aws sts get-caller-identity

Verified ARN now ends with: root username.

**Lesson Learned:**
Always validate identity context before executing IAM, alias, or policy changes.
Most importantly, root accounts/sessions should be reserved exclusively for high-level account management.


## 2. MFA Authentication Failures

**Symptom:**
AWS sign-in rejected the correct password with an MFA error message.

**Cause:**
MFA token was registered under the wrong account alias.

**Resolution:**
Deregistered and re-enrolled the device using the correct alias sign-in URL.
Verified the alias and account ID match.

**Lesson Learned:**
Each MFA entry is alias-specific. Label and store MFA accounts clearly in an approved authenticator app.


## 3. Delayed Email Verification (iCloud Mail)

**Symptom:**
Verification and password reset emails from AWS took 10+ minutes to arrive.

**Cause:**
Apple iCloud temporarily greylisted AWS SES messages.

**Resolution:**
Waited approximately 15 minutes for delivery.
Whitelisted @amazon.com sender domain in iCloud settings.

**Lesson Learned:**
Corporate or iCloud inboxes may delay automated AWS emails. Plan delays into security setups.


## 4. Missing "Enable Console Access" Option

**Symptom:**
Expected toggle to enable console access for IAM user was missing.

**Cause:**
AWS updated the console UI and replaced “Enable console access” with “Manage console access.”

**Resolution:**
Located the feature under:
IAM → Users → [Username] → Console sign-in → Manage console access.
Reset password successfully from this interface.

**Lesson Learned:**
AWS services evolve frequently; confirm current UI terms before assuming a feature has been removed.


## 5. Orphaned VPC and Network Interface

**Symptom:**
Billing dashboard showed VPC-related charges (~$3.07) even with no active resources.

**Cause:**
A leftover ENI (Elastic Network Interface) was still attached to an old VPC.

**Resolution:** 
Listed ENIs in the Ohio region (us-east-2):

- Listed ENIs in the Ohio region (us-east-2)
```
aws ec2 describe-network-interfaces --region us-east-2
```

- Found and deleted the stale ENI
```
aws ec2 delete-network-interface --network-interface-id eni-09df76f8db307c227
```
- Deleted the VPC after dependencies were cleared.
**Lesson Learned:**

Residual network interfaces can prevent VPC deletion and incur minimal charges.
Always check for orphaned ENIs before concluding cleanup.

## 6. CLI Access Key Sanitation

**Symptom:**

Old IAM access key still active for legacy user techric.

**Cause:**

The access key created during the early testing phase remained active.

**Resolution:**

Verified with:

```
aws iam list-access-keys --ysersaname

```
Deleted old key 

```
aws iam delete-access-key --user-name techric --access-key-id <ID>

```
Reformed MFA-enabled console authentication only. 

**Lesson Learned:**
Access keys should not exist for IAM console users unless explicitly required. 
Use temporary CLI sessions or AWS SSO instead.

## 7. Cross-Account Alias Naming Collision

**Symptom:**
Error when creating a new alias:
Account alias not created. The account alias mainaccountalias already exists.

**Cause:**
AWS account aliases are globally unique — not per organization.

**Resolution:**
Selected a distinct alias: main-account-root.
Re-ran alias creation successfully.

**Lesson Learned:**
Account aliases must be unique across all AWS accounts, not just within your own set.

## Summary

| Category | Root Cause | Resolution |
|-----------|-------------|------------|
| Identity mix-up | Using root instead of IAM credentials | Confirmed ARN type and re-authenticated |
| MFA mismatch | Wrong alias registered | Re-enrolled MFA correctly |
| Email delay | iCloud throttling | Waited and whitelisted sender |
| Console UI change | AWS terminology update | Located new option path |
| VPC billing issue | Orphaned ENI | Deleted ENI and VPC |
| Access key exposure | Old credentials active | Deleted keys |
| Alias conflict | Name collision | Used unique alias |

---
## Next Steps

Periodically audit active IAM users, access keys, and aliases:

```
aws iam list-users
aws iam list-access-keys
aws iam list-account-aliases
```
Enable CloudTrail to log IAM and root API calls.
Document account setup steps for repeatability.

### End of Report

---





