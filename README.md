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
│       ├── _contact-form.tf       # Contact form Lambda & API Gateway
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
- **Email notifications** - AWS SES sends to multiple recipients
- **Bot protection** - reCAPTCHA v3 (invisible, no user interaction)
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
- **Lambda** - Serverless function (Python 3.12)
- **API Gateway v2** - HTTP API endpoint
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
