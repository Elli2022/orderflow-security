# INC-001: Suspected API Credential or JWT Leak

**Severity:** HIGH  
**Owner:** Security Operations  
**Last reviewed:** 2026-06-29

---

## Triggers

- GuardDuty finding: `UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration`
- GuardDuty: `Recon:IAMUser/MaliciousIPCaller`
- Manual report from developer or customer
- Spike in `401` followed by spike in `200` from new IP ranges
- Cognito alert: unusual sign-in geography

---

## Response Steps

### 1. DETECT & TRIAGE (0–15 min)

- [ ] Confirm alert is not false positive
- [ ] Identify affected principal (IAM user, role, Cognito user pool, client ID)
- [ ] Open incident channel / ticket
- [ ] Assign incident commander

### 2. CONTAIN (15–30 min)

- [ ] **Cognito:** Revoke all active tokens for affected user pool / users
  ```bash
  aws cognito-idp admin-user-global-sign-out --user-pool-id POOL_ID --username USERNAME
  ```
- [ ] **IAM:** Attach deny policy to compromised role/user (break-glass role)
- [ ] **API Gateway:** Reduce stage throttle limits temporarily if active abuse
- [ ] **WAF:** Add IP set block rule for confirmed malicious IPs

### 3. ROTATE (30–60 min)

- [ ] Force Secrets Manager rotation for payment provider secret
- [ ] If IAM access keys compromised: deactivate immediately, create new via Terraform
- [ ] Rotate any affected CMK (last resort — high impact; prefer IAM revocation first)

### 4. INVESTIGATE (1–4 hours)

- [ ] Query CloudTrail last 24–72 hours for affected principal:
  ```bash
  aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=Username,AttributeValue=COMPROMISED_PRINCIPAL \
    --start-time 2026-06-28T00:00:00Z
  ```
- [ ] Identify accessed resources: DynamoDB tables, secrets, S3 buckets
- [ ] Check DynamoDB data events for bulk `GetItem`/`Scan` on orders table
- [ ] Determine blast radius: which customer records may be exposed
- [ ] Preserve evidence: export relevant CloudTrail events to incident folder

### 5. ERADICATE

- [ ] Remove attacker persistence (backdoor IAM users, unknown Lambda triggers)
- [ ] Patch vulnerability that enabled leak (e.g. remove key from git history)
- [ ] Verify Terraform state matches intended configuration (`terraform plan` = no drift)

### 6. RECOVER

- [ ] Re-enable access for legitimate users with new credentials
- [ ] Monitor elevated for 48 hours
- [ ] Restore normal WAF/throttle settings

### 7. NOTIFY (if PII breach confirmed)

- [ ] Notify DPO / legal within **72 hours** (GDPR Art. 33)
- [ ] Document affected data subjects count
- [ ] Prepare regulatory notification if required (NIS2)

### 8. LESSONS LEARNED (within 5 business days)

- [ ] Post-incident review document
- [ ] Update threat model if new attack vector discovered
- [ ] Update ADR-SEC-002 if auth mechanism changes
- [ ] Add detection rule if gap identified

---

## Escalation

| Condition | Escalate to |
|-----------|-------------|
| Confirmed PII exfiltration | DPO + Legal + CISO |
| Root account involved | CISO immediately |
| Ongoing active abuse | Enable DDoS response (Shield Advanced if available) |

---

## Prevention Controls (Reference)

- JWT short TTL (1h) — [SEC-002](../adr/SEC-002-jwt-authorizer.md)
- GuardDuty enabled — [SEC-006](../adr/SEC-006-guardduty-securityhub.md)
- No long-lived API keys in clients
- CloudTrail log file validation — [SEC-005](../adr/SEC-005-cloudtrail-integrity.md)
