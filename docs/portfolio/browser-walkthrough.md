# Browser Walkthrough — Följ dessa steg i ordning

Öppna denna fil bredvid webbläsaren och bocka av varje steg.

---

## ✅ Steg 1: CI är grön (KLART)

**URL:** https://github.com/Elli2022/orderflow-security/actions/runs/28645360401

Du ska se:
- Status: **Success** (grön bock)
- Jobb: **Format & Validate** ✅
- Jobb: **Terraform Plan (AWS)** ✅ (hoppade över plan — inga AWS-secrets än)

Detta betyder att Terraform-koden är giltig. Mailet du fick var från den *första* misslyckade körningen — det är fixat.

---

## Steg 2: Logga in på GitHub

Webbläsaren visar inloggningssida när man försöker nå Secrets utan att vara inloggad.

1. Gå till https://github.com/login
2. Logga in som **Elli2022**
3. Verifiera att du ser ditt repo

---

## Steg 3: Skapa AWS-konto (om du inte har)

**URL:** https://portal.aws.amazon.com/billing/signup

1. Klicka **Create an AWS Account**
2. E-post + lösenord
3. Välj **Personal** account
4. Lägg till betalkort (krävs, men Free Tier täcker demo)
5. Välj support plan: **Basic (Free)**
6. Vänta på verifiering (~5 min)

**Viktigt:** Välj region **Europe (Stockholm) eu-north-1** senare — matchar GDPR-storyn i portfolion.

---

## Steg 4: Skapa IAM-användare för Terraform

**Logga in i AWS Console:** https://console.aws.amazon.com/

1. Sök efter **IAM** i sökfältet
2. Vänstermeny → **Users** → **Create user**
3. Användarnamn: `orderflow-terraform`
4. **Attach policies directly** → välj **AdministratorAccess**  
   *(OK för dev/portfolio — begränsa i produktion)*
5. Skapa användaren
6. Klicka på användaren → **Security credentials** → **Create access key**
7. Välj **Command Line Interface (CLI)** → Next → Create
8. **Spara Access Key ID och Secret Access Key** — visas bara en gång!

---

## Steg 5: Konfigurera AWS lokalt

Öppna Terminal och kör:

```bash
aws configure
```

Fyll i:
- AWS Access Key ID: `din-nyckel`
- AWS Secret Access Key: `din-hemlighet`
- Default region: `eu-north-1`
- Default output format: `json`

Testa:
```bash
aws sts get-caller-identity
```

---

## Steg 6: Deploya OrderFlow

```bash
cd ~/Projects/orderflow-security/infra/terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

Skriv `yes` när Terraform frågar.

**Tar ~5–10 min.** När klart får du API-URL och Cognito User Pool ID.

---

## Steg 7: Lägg AWS-secrets i GitHub (valfritt — för CI plan)

**URL:** https://github.com/Elli2022/orderflow-security/settings/secrets/actions

*(Kräver inloggning)*

1. **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret:**
   - Name: `AWS_ACCESS_KEY_ID` → Value: din key
3. **New repository secret:**
   - Name: `AWS_SECRET_ACCESS_KEY` → Value: din secret

Nästa push kör `terraform plan` automatiskt i CI.

---

## Steg 8: Security screenshots (portfolio)

Efter deploy — ta screenshots i AWS Console:

| # | Var | Spara som |
|---|-----|-----------|
| 1 | Security Hub → Compliance score | `docs/security/screenshots/security-hub-score.png` |
| 2 | GuardDuty → Summary | `guardduty-summary.png` |
| 3 | WAF → Web ACL | `waf-overview.png` |
| 4 | CloudTrail → Log file validation | `cloudtrail-validation.png` |
| 5 | DynamoDB → Encryption | `dynamodb-encryption.png` |

Kör testerna i `docs/security/security-test-results.md`.

---

## Steg 9: Städa upp (viktigt!)

När screenshots är tagna:

```bash
cd ~/Projects/orderflow-security/infra/terraform/environments/dev
terraform destroy
```

Annars kostar VPC endpoints ~$50/mån.

---

## Steg 10: LinkedIn

Kopiera text från `docs/portfolio/linkedin-profile.md` och publicera launch-post med länk till repot.

---

## Var är du nu?

- [x] Steg 1 — CI grön
- [ ] Steg 2 — GitHub inloggad
- [ ] Steg 3 — AWS-konto
- [ ] Steg 4 — IAM-användare
- [ ] Steg 5 — `aws configure`
- [ ] Steg 6 — `terraform apply`
- [ ] Steg 7 — GitHub secrets
- [ ] Steg 8 — Screenshots
- [ ] Steg 9 — `terraform destroy`
- [ ] Steg 10 — LinkedIn

**Säg till mig vilket steg du är på** — jag guidar dig vidare därifrån.
