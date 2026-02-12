# User Account Deactivation Record

**Document Type:** Audit Trail / Compliance Evidence  
**Date:** February 11, 2026  
**Time:** 17:29 UTC  
**Action:** User Account Deactivation  

---

## User Information

**Full Name:** Alex Garcia  
**Email:** alex.garcia@activecompainlabinterview.com  
**User ID:** 00uzlwixqaUhYSSEC697  
**Department:** Security  
**Title:** Compliance Analyst  

---

## Account Status

**Previous Status:** STAGED  
**New Status:** DEPROVISIONED  
**Account Created:** January 28, 2026  
**Last Login:** Never  
**Account Active Duration:** 14 days  

---

## Justification

**Primary Reason:** Account never activated  
**Compliance Context:** SOC 2 compliance remediation - inactive account cleanup  
**Risk Assessment:** Account in STAGED status for 14 days without activation represents unused access that increases attack surface  

**SOC 2 Control Reference:** CC6.1 - Logical and Physical Access Controls  
**Policy Reference:** User accounts should be deprovisioned within 30 days if not activated  

---

## Approval Process

**Method:** GitOps Pull Request  
**Branch:** compliance/deactivate-alex-garcia  
**Reviewers Required:** Security Team + Platform Team  
**Automated Checks:** Terraform plan validation  

---

## Compliance Impact

**Before Deactivation:**
- Total Users: 7
- Active Users: 1 (14%)
- Inactive Users: 6 (86%)

**After Deactivation:**
- Total Users: 6
- Active Users: 1 (17%)
- Inactive Users: 5 (83%)

**Improvement:** 3% reduction in inactive user rate

---

**Document ID:** AUDIT-2026-02-11-001  
**Classification:** Internal - Compliance  
**Retention Period:** 7 years