# Ubuntu Terminal Portfolio

A unique personal portfolio website styled after the Ubuntu terminal interface, hosted on AWS using infrastructure as code.

## Project Overview

This project consists of three main components:
1. A static website with an Ubuntu terminal-inspired interface
2. Infrastructure as code (Terraform) for AWS deployment
3. GitHub Actions workflow for automated deployment

## Repository Structure

```
.
├── .github/                      # GitHub specific configurations
│   └── workflows/               # GitHub Actions workflows
│       └── deploy-s3.yml       # Deployment workflow
│
├── web/                         # Web application files
│   ├── index.html              # Main HTML file
│   ├── error.html              # Error page for CloudFront
│   ├── css/
│   │   └── style.css          # Custom styles
│   └── js/
│       └── terminal.js        # Terminal functionality
│
├── infrastructure/
│   ├── backend/           # Terraform Backend Resources
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── providers.tf
│   │
│   └── web-hosting/       # Web Hosting Resources
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── providers.tf
│
├── .gitignore                  # Git ignore rules
└── README.md                   # Project documentation
```

## Web Application

### Features

- Ubuntu terminal-inspired design
- Interactive command-line interface
- Responsive design for all devices
- Command history navigation
- Real terminal-like experience
- Social media integration (GitHub, LinkedIn)

### Available Commands

- `help` - Show available commands
- `clear` - Clear the terminal
- `whoami` - Display name and title
- `ls` - List available files
- `cat summary.txt` - Display professional summary
- `cat skills.txt` - Display technical skills
- `cat certifications.md` - Display certifications
- `cat education.txt` - Display education history

### Technical Stack

- HTML5
- CSS3
- JavaScript (ES6+)
- Bootstrap 5
- Ubuntu Mono font (Google Fonts)
- Font Awesome icons

## Infrastructure

### AWS Resources

The website is hosted on AWS using the following services:
- S3 bucket for static website hosting
- CloudFront for content delivery
- Route53 for DNS management
- ACM for SSL/TLS certificate
- IAM for resource permissions

### Infrastructure Organization

The infrastructure is organized by region and resource type:

#### Backend Resources
- S3 bucket for Terraform state storage

#### Web Hosting Resources
- S3 bucket for static website files
- CloudFront distribution
- ACM certificate for HTTPS
- Route53 DNS records
- IAM roles and policies

## GitHub Actions

### Deployment Workflow

The project uses GitHub Actions for automated deployment to AWS. The workflow is triggered on:
- Push to main branch (not yet)
- Manual workflow dispatch

### Required Secrets

The following secrets must be configured in GitHub repository settings:

1. `AWS_ROLE_ARN`
   - Description: AWS IAM Role for the action

2. `S3_BUCKET`
   - Description: S3 bucket name to deploy the assets

3. `AWS_REGION`
   - Description: AWS region where resources are deployed
   - Example value: us-east-1

### Workflow Features

- Automated deployment to S3
- CloudFront cache invalidation
- Error handling and notifications
- Secure secret management
- Deployment status checks

## Setup and Deployment

### Web Application
1. Navigate to the `web` directory
2. Open `index.html` in a web browser for local testing
3. Modify content in `terminal.js` as needed

### Infrastructure Deployment

1. Deploy Backend Infrastructure:
   ```bash
   cd infrastructure/us-east-1/backend
   terraform init
   terraform plan
   terraform apply
   ```

2. Deploy Web Hosting Resources:
   ```bash
   cd ../web-hosting
   terraform init
   terraform plan
   terraform apply
   ```

### GitHub Actions Setup

1. Configure required secrets in GitHub repository settings:
   - Go to Settings > Secrets and variables > Actions
   - Add the three required secrets listed above

2. The workflow will automatically run on push to main branch (NOT YET)
3. Manual deployment can be triggered from the Actions tab

## Development

### Web Content
To modify the website content, edit the `data` object in `terminal.js`. The styling can be customized in `style.css`.

### Infrastructure
To modify the AWS infrastructure:
1. Backend changes:
   - Update files in `infrastructure/us-east-1/backend/`
   - Apply changes using Terraform
2. Web hosting changes:
   - Update files in `infrastructure/us-east-1/web-hosting/`
   - Apply changes using Terraform

### Important Notes
- Always deploy backend infrastructure first
- Use consistent naming conventions across resources
- Review security configurations before deployment
- Test website in multiple browsers after deployment
- Ensure GitHub Actions secrets are properly configured
- Keep AWS IAM credentials secure

## Browser Compatibility

- Chrome (recommended)
- Firefox
- Safari
- Edge
