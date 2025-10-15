# Ubuntu Terminal Website

A unique personal website styled after the Ubuntu terminal interface with an integrated contact form, hosted on AWS using infrastructure as code.

## Project Overview

This project consists of:
1. **Static website** - Ubuntu terminal-inspired interface with interactive commands
2. **Contact form** - Serverless contact form with AWS Lambda, API Gateway, and SES
3. **Bot protection** - reCAPTCHA v3 for spam prevention
4. **Infrastructure as Code** - Terraform for AWS deployment
5. **CI/CD** - GitHub Actions workflow for automated deployment

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy-s3.yml           # Deployment workflow
│
├── web/                            # Web application
│   ├── index.html                  # Main page
│   ├── error.html                  # CloudFront error page
│   ├── css/
│   │   └── style.css              # Terminal styling
│   └── js/
│       ├── terminal.js            # Terminal commands
│       └── contact.js             # Contact form handler
│
├── infrastructure/
│   ├── iac-backend/               # Terraform state backend
│   │   ├── main.tf
│   │   ├── template.auto.tfvars   # Configuration template
│   │   └── secrets.auto.tfvars    # Your secrets (gitignored)
│   │
│   └── web/                       # Web infrastructure
│       ├── main.tf                # S3, CloudFront, Route53
│       ├── _contact-form.tf       # Contact form (Lambda, API Gateway, SES)
│       ├── _waf.tf                # AWS WAF (rate limiting, security rules)
│       ├── variables.tf           # Configuration variables
│       ├── outputs.tf             # Terraform outputs
│       ├── template.auto.tfvars   # Configuration template
│       ├── secrets.auto.tfvars    # Your secrets (gitignored)
│       └── lambdas/
│           └── web-contact-form/
│               ├── contact-form.py
│               └── requirements.txt
│
├── .gitignore
└── README.md
```

## Features

### Terminal Interface
- Ubuntu terminal-inspired design with authentic styling
- Interactive command-line interface
- Command history navigation (arrow keys)
- Responsive design for all devices

**Available Commands:**
- `help` - Show available commands
- `clear` - Clear the terminal
- `whoami` - Display name and title
- `ls` - List available files
- `cat summary.txt` - Display professional summary
- `cat skills.txt` - Display technical skills
- `cat certifications.md` - Display certifications
- `cat education.txt` - Display education history

### Contact Form
- **Serverless architecture** - AWS Lambda + API Gateway
- **Multi-layer security** - WAF rate limiting, CORS restrictions, Lambda concurrency limits
- **Bot protection** - reCAPTCHA v3 with backend verification
- **Email notifications** - AWS SES sends to multiple recipients
- **Form validation** - Client-side and server-side
- **Automatic responses** - Confirmation emails to visitors (when SES is out of sandbox)

### Technical Stack

**Frontend:**
- HTML5, CSS3, JavaScript (ES6+)
- Bootstrap 5
- Google reCAPTCHA v3

**Backend:**
- AWS Lambda (Python 3.12)
- AWS API Gateway v2 (HTTP API)
- AWS SES (Simple Email Service)
- AWS S3 + CloudFront
- AWS Route53 + ACM

**Infrastructure:**
- Terraform
- GitHub Actions (CI/CD)

## Infrastructure

### AWS Services

**Core Infrastructure:**
- **S3** - Static website hosting and Terraform state storage
- **CloudFront** - Global CDN with HTTPS
- **Route53** - DNS management
- **ACM** - SSL/TLS certificates

**Contact Form:**
- **Lambda** - Serverless function (Python 3.12) with reserved concurrency
- **API Gateway v2** - HTTP API endpoint with throttling
- **WAF** - Web Application Firewall with rate limiting and managed rules
- **SES** - Email sending with domain verification (DKIM, SPF)
- **IAM** - Roles and permissions

**CI/CD:**
- **GitHub Actions** - Automated deployment
- **OIDC** - Keyless AWS authentication

## Setup and Deployment

### Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with a profile
3. **Terraform** >= 1.1.0
4. **Domain** registered (for custom domain)
5. **Google reCAPTCHA** account (for bot protection)

### Step 1: Configure Infrastructure

Copy the template files and configure your values:

```bash
# Backend configuration
cd infrastructure/iac-backend
cp template.auto.tfvars secrets.auto.tfvars
```

Edit `secrets.auto.tfvars`:
```hcl
project_name        = "my-web"
project_region      = "us-east-1"
project_profile     = "default"  # Your AWS CLI profile
```

```bash
# Web infrastructure configuration  
cd ../web
cp template.auto.tfvars secrets.auto.tfvars
```

Edit `secrets.auto.tfvars`:
```hcl
project_name        = "my-web"
project_environment = "production"
project_region      = "us-east-1"
project_profile     = "default"

# GitHub OIDC for CI/CD
oidc_subjects       = ["my-org/my-repo:*"]

# Domain configuration
cloudfront_aliases  = ["example.com", "*.example.com"]
web_domain          = "example.com"
api_gateway_domain_name = "api.example.com"

# Contact form emails
web_contact_form_email         = "info@example.com"
web_contact_form_forward_email = "personal@gmail.com"  # Optional

# reCAPTCHA (see Step 3)
recaptcha_secret_key = "YOUR_SECRET_KEY"

# Security settings (optional - defaults provided)
# enable_waf                  = false  # Set to true to enable WAF (~$11/month)
# api_throttle_burst_limit    = 10
# api_throttle_rate_limit     = 5
# lambda_reserved_concurrency = 5
# waf_rate_limit_general      = 100   # Only if enable_waf = true
# waf_rate_limit_post         = 10    # Only if enable_waf = true
```

### Step 2: Deploy Infrastructure

```bash
# 1. Deploy backend (Terraform state storage)
cd infrastructure/iac-backend
terraform init
terraform apply

# 2. Deploy web infrastructure
cd ../web
terraform init
terraform apply
```

After deployment, you'll receive outputs with:
- CloudFront distribution URL
- API Gateway endpoint
- SES verification status

### Step 3: Configure reCAPTCHA (Bot Protection)

The contact form uses Google reCAPTCHA v3 to prevent spam. It's invisible to users and runs automatically in the background.

#### Get reCAPTCHA Keys

1. Go to https://www.google.com/recaptcha/admin/create
2. Create a new site:
   - **Label:** your-website-name
   - **Type:** reCAPTCHA v3
   - **Domains:** your-domain.com, localhost
3. Get your **Site Key** (public) and **Secret Key** (private)

#### Configure Frontend

Edit `web/index.html` (line 97):
```html
<script src="https://www.google.com/recaptcha/api.js?render=YOUR_SITE_KEY"></script>
```

Edit `web/js/contact.js` (line 10):
```javascript
const RECAPTCHA_SITE_KEY = 'YOUR_SITE_KEY';
```

#### Configure Backend

Add to `infrastructure/web/secrets.auto.tfvars`:
```hcl
recaptcha_secret_key = "YOUR_SECRET_KEY"
```

Re-deploy:
```bash
cd infrastructure/web
terraform apply
```

**Why reCAPTCHA?**
- Invisible to users (no checkboxes or challenges)
- Scores each submission 0.0-1.0 (bot to human)
- Blocks automated spam submissions
- Free for up to 1M requests/month

### Step 4: Verify SES Email

AWS SES starts in sandbox mode (can only send to verified addresses). To send to anyone:

1. Verify your domain in AWS SES Console
2. Request production access (usually approved in 24-48 hours)

Or, for testing, verify individual email addresses in SES Console.

### Step 5: Deploy Website

Upload your website files to S3 by triggering the github workflow.

## GitHub Actions (CI/CD)

### Automated Deployment

The workflow deploys on:
- Manual trigger (Actions tab)
- Push to main branch (optional)

### Required Secrets

Configure in GitHub Settings > Secrets:

1. `AWS_ROLE_ARN` - IAM role for deployment (created by Terraform)
2. `S3_BUCKET` - Website bucket name
3. `AWS_REGION` - AWS region (e.g., us-east-1)

Terraform outputs these values after deployment.

## Monitoring and Maintenance

### View Contact Form Submissions

Check CloudWatch Logs:
```bash
aws logs tail /aws/lambda/web-contact-form --follow --profile your-profile
```

### View reCAPTCHA Analytics

- Go to https://www.google.com/recaptcha/admin
- View score distribution and request volume

### SES Email Sending

Monitor in AWS SES Console:
- Bounce and complaint rates
- Sending statistics
- Reputation dashboard

## Troubleshooting

### Contact form returns 500 error
- Check CloudWatch Logs for Lambda errors
- Verify SES email/domain is verified
- Check reCAPTCHA keys are correct

### Emails not arriving
- **Sandbox mode**: Verify recipient email in SES Console
- **Production**: Check SES bounce/complaint rates
- Verify DNS records (DKIM, SPF) are set

### reCAPTCHA verification fails
- Verify Site Key matches in HTML and JS
- Check Secret Key in Terraform
- Ensure domain is registered in reCAPTCHA console

## Security

The contact form API is protected by multiple security layers to prevent email flooding, DDoS attacks, and abuse.

### Security Architecture

**Multi-Layer Protection:**

1. **CORS Restriction** - Only allows requests from your domain (not `*`)
2. **AWS WAF** *(optional, disabled by default)* - Rate limiting, SQL injection/XSS protection, bot blocking
3. **API Gateway Throttling** - 10 concurrent requests, 5 requests/second
4. **Lambda Concurrency** - Max 5 simultaneous executions (cost protection)
5. **reCAPTCHA v3** - Backend token verification (score > 0.5)
6. **Input Validation** - Email format, length limits, field validation

> **💡 Note:** AWS WAF is **disabled by default** to avoid the ~$11/month additional cost. The other security layers (API Gateway throttling, Lambda concurrency, reCAPTCHA, CORS) still provide strong protection. To enable WAF, set `enable_waf = true` in your `secrets.auto.tfvars`.

### Key Protection Features

| Attack Type | Protection Layer | Status |
|------------|------------------|--------|
| Direct API flooding (bypassing frontend) | API Gateway throttling + Lambda concurrency | ✅ Always active |
| Direct API flooding (bypassing frontend) | WAF blocks after 10 POST requests / 5 min per IP | ⚡ Optional (enable_waf) |
| Distributed attacks (multiple IPs) | API Gateway throttling + Lambda concurrency limits | ✅ Always active |
| Bot/crawler abuse | reCAPTCHA v3 scoring + validation | ✅ Always active |
| Bot/crawler abuse | WAF user agent blocking | ⚡ Optional (enable_waf) |
| Malicious payloads (SQL, XSS) | AWS WAF Managed Rules (Core Rule Set) | ⚡ Optional (enable_waf) |
| Cost explosion from attacks | Lambda reserved concurrency (5) prevents runaway costs | ✅ Always active |
| Unauthorized domain access | CORS restricted to your domain only | ✅ Always active |

### Security Configuration

All security settings are configurable in `infrastructure/web/secrets.auto.tfvars`:

```hcl
# Enable WAF Protection (optional - adds ~$11/month)
enable_waf = false  # Set to true to enable WAF

# API Gateway Throttling (always active)
api_throttle_burst_limit    = 10   # Max concurrent requests
api_throttle_rate_limit     = 5    # Requests per second

# Lambda Protection (always active)
lambda_reserved_concurrency = 5    # Max concurrent executions

# WAF Rate Limiting (only if enable_waf = true)
waf_rate_limit_general      = 100  # Max requests per IP / 5 minutes
waf_rate_limit_post         = 10   # Max POST requests per IP / 5 minutes
```

**Adjust based on your traffic:**
- **Low traffic** (< 100 submissions/month): Keep WAF disabled, `api_throttle_rate_limit = 3`
- **Medium traffic** (100-1000 submissions/month): Default settings (WAF optional)
- **High traffic** (> 1000 submissions/month): Enable WAF, increase limits: `waf_rate_limit_post = 20`, `api_throttle_burst_limit = 20`

### Testing Security

**Test rate limiting:**
```bash
# Send 15 rapid requests (should block after 10)
for i in {1..15}; do
  curl -X POST https://api.yourdomain.com/contact \
    -H "Content-Type: application/json" \
    -d '{"name":"Test '$i'","email":"test@example.com","message":"Testing"}' &
done
```
**Expected:** First 10 succeed, requests 11+ get HTTP 429 (Rate Limit Exceeded)

**Test reCAPTCHA validation:**
```bash
curl -X POST https://api.yourdomain.com/contact \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","message":"Test"}'
```
**Expected:** HTTP 400 - reCAPTCHA verification failed

### Monitoring

**CloudWatch Resources:**
- **WAF Logs:** `/aws/wafv2/contact-form-api` (7-day retention)
- **Lambda Logs:** `/aws/lambda/web-contact-form`
- **API Gateway Metrics:** View throttled requests, 4xx/5xx errors

**View WAF blocked requests (if WAF enabled):**
```bash
# AWS Console → WAF & Shield → Web ACLs → contact-form-api-waf
# View "Sampled requests" tab to see blocked IPs
```

**Note:** WAF logs and monitoring are only available when `enable_waf = true`

### Cost Impact

**Base Security (WAF disabled - default):**
| Service | Monthly Cost |
|---------|--------------|
| API Gateway (5k requests) | ~$5 |
| Lambda (moderate usage) | ~$0.20 |
| CloudWatch Logs | ~$0.50 |
| **Total** | **~$6/month** |

**Enhanced Security (WAF enabled - optional):**
| Service | Monthly Cost |
|---------|--------------|
| AWS WAF (WebACL + 5 Rules) | ~$11 |
| API Gateway (5k requests) | ~$5 |
| Lambda (moderate usage) | ~$0.20 |
| CloudWatch Logs (WAF + Lambda) | ~$1 |
| **Total** | **~$17-20/month** |

Set `enable_waf = true` in `secrets.auto.tfvars` to enable enterprise-grade WAF protection.

### Emergency Response

**If email flooding detected:**

1. **Enable WAF (if not already enabled):**
   Edit `infrastructure/web/secrets.auto.tfvars`:
   ```hcl
   enable_waf = true  # Enable WAF protection
   ```
   Apply: `terraform apply`

2. **Check WAF Dashboard (if WAF enabled):**
   - AWS Console → WAF & Shield → Web ACLs → `contact-form-api-waf`
   - View blocked IPs and request patterns

3. **Review CloudWatch Logs:**
   ```bash
   # Lambda logs (always available)
   aws logs tail /aws/lambda/web-contact-form --follow --profile your-profile
   
   # WAF logs (only if WAF enabled)
   aws logs filter-log-events \
     --log-group-name /aws/wafv2/contact-form-api \
     --filter-pattern "BLOCK" \
     --profile your-profile
   ```

4. **Temporary Fix - Reduce Rate Limits:**
   Edit `infrastructure/web/secrets.auto.tfvars`:
   ```hcl
   api_throttle_rate_limit = 2     # More restrictive (always active)
   waf_rate_limit_post = 3         # More restrictive (only if WAF enabled)
   ```
   Apply: `terraform apply`

5. **Block Specific IPs (if WAF enabled):**
   - AWS Console → WAF & Shield → IP Sets
   - Create IP set with attacker IPs
   - Add blocking rule to WAF WebACL

### Protection Verification

**Before deployment:** Vulnerable to unlimited API calls bypassing frontend

**After deployment (base security):**
- ✅ API Gateway throttles to 5 requests/second (burst: 10)
- ✅ Lambda processes max 5 requests simultaneously
- ✅ reCAPTCHA validates all requests on backend
- ✅ CORS prevents unauthorized domains

**After deployment (with WAF enabled - optional):**
- ✅ **All base security features above, plus:**
- ✅ WAF blocks after 10 POST requests per IP in 5 minutes
- ✅ WAF managed rules block SQL injection, XSS attacks
- ✅ WAF blocks suspicious user agents (bots, crawlers)
