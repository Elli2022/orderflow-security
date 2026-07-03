# Deploy Guide — OrderFlow Security

Steg-för-steg för att deploya, testa, ta screenshots och städa upp.

---

## Förutsättningar

```bash
# Verifiera verktyg
aws --version
terraform --version

# AWS credentials (ett av alternativen)
aws configure                    # access key + secret
# eller: AWS SSO, miljövariabler, IAM role
aws sts get-caller-identity      # ska returnera Account ID
```

**Region:** `eu-north-1` (Stockholm) — ändra inte om du vill behålla GDPR-storyn.

---

## 1. Deploy

```bash
cd ~/Projects/orderflow-security/infra/terraform/environments/dev

cp terraform.tfvars.example terraform.tfvars
# Redigera terraform.tfvars — lägg till alert_email för larm (valfritt)

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

**Spara outputs:**
```bash
terraform output > ../../../../deploy-outputs.txt
```

---

## 2. Skapa testanvändare i Cognito

```bash
USER_POOL_ID=$(terraform output -raw cognito_user_pool_id)

aws cognito-idp admin-create-user \
  --user-pool-id "$USER_POOL_ID" \
  --username testuser@example.com \
  --user-attributes Name=email,Value=testuser@example.com Name=email_verified,Value=true \
  --temporary-password 'TempPass123!@#' \
  --message-action SUPPRESS

aws cognito-idp admin-set-user-password \
  --user-pool-id "$USER_POOL_ID" \
  --username testuser@example.com \
  --password 'YourSecurePass123!@#' \
  --permanent
```

Hämta JWT (via Hosted UI eller AWS CLI initiate-auth).

---

## 3. Testa API

```bash
API_URL=$(terraform output -raw api_endpoint)
TOKEN="<ditt-jwt>"

# Skapa order (ska funka)
curl -s -X POST "$API_URL/orders" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{"items":[{"sku":"SKU-001","qty":1,"price":19900}]}'

# Utan token (ska ge 401)
curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL/orders"
```

Kör alla tester i `docs/security/security-test-results.md`.

---

## 4. Screenshots för portfolio

Spara i `docs/security/screenshots/`:

| # | Var i AWS Console | Filnamn |
|---|-------------------|---------|
| 1 | Security Hub → Compliance score | `security-hub-score.png` |
| 2 | GuardDuty → Summary | `guardduty-summary.png` |
| 3 | WAF → Web ACL → Overview (blocked requests) | `waf-overview.png` |
| 4 | CloudTrail → Trail → Log file validation Enabled | `cloudtrail-validation.png` |
| 5 | DynamoDB → orders → Encryption | `dynamodb-encryption.png` |
| 6 | IAM → order-lambda role → Permissions | `iam-order-lambda.png` |
| 7 | CloudWatch → Alarms (DLQ alarms) | `cloudwatch-alarms.png` |
| 8 | X-Ray → Service map (efter några requests) | `xray-service-map.png` |

Uppdatera `security-test-results.md` med Pass/Fail.

---

## 5. Kostnad & cleanup

**Uppskattad kostnad dev:** ~$50–80/månad (VPC interface endpoints ~$7/st each).

**Destroy när du är klar med screenshots:**
```bash
cd ~/Projects/orderflow-security/infra/terraform/environments/dev
terraform destroy
```

**Tips:** Ta alla screenshots *innan* destroy.

---

## 6. Felsökning

| Problem | Lösning |
|---------|---------|
| `Error: creating WAFv2 WebACL Association` | API stage måste finnas — kör apply igen |
| Lambda timeout i VPC | Kontrollera VPC endpoints och security groups |
| Cognito 401 | Token expired (1h) — hämta nytt |
| Terraform state lock | S3 backend om du lägger till det senare |

---

## Remote state (rekommenderat för prod-lik demo)

Skapa S3 bucket + DynamoDB lock table, lägg till i `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "orderflow-terraform-state-ACCOUNT_ID"
    key            = "dev/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
    dynamodb_table = "orderflow-terraform-locks"
  }
}
```

Skapa bucket och tabell manuellt först (eller separat bootstrap module).
