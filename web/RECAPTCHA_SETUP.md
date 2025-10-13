# reCAPTCHA v3 Setup Guide

## Step 1: Register with Google reCAPTCHA

1. Go to https://www.google.com/recaptcha/admin/create
2. Fill out the form:
   - **Label:** lybarra-web
   - **reCAPTCHA type:** Select **reCAPTCHA v3**
   - **Domains:** 
     - `lisandroybarra.com`
     - `localhost` (for local testing)
   - Accept terms
3. Click **Submit**

## Step 2: Get Your Keys

After registration, you'll receive:
- **Site Key** (public key) - use in frontend
- **Secret Key** (private key) - use in backend

## Step 3: Configure Frontend

### Update `web/index.html`
Replace `YOUR_SITE_KEY_HERE` with your actual Site Key:
```html
<script src="https://www.google.com/recaptcha/api.js?render=YOUR_ACTUAL_SITE_KEY"></script>
```

### Update `web/js/contact.js`
Replace `YOUR_SITE_KEY_HERE` with your actual Site Key:
```javascript
const RECAPTCHA_SITE_KEY = 'YOUR_ACTUAL_SITE_KEY';
```

## Step 4: Configure Backend

### Update `infrastructure/web/secrets.auto.tfvars`
Add your Secret Key:
```hcl
recaptcha_secret_key = "YOUR_ACTUAL_SECRET_KEY"
```

## Step 5: Deploy

```bash
# Deploy infrastructure
cd infrastructure/web
terraform apply

# Upload website
cd ../..
# Use your deployment method (s3store.sh or manual)
```

## How It Works

### reCAPTCHA v3 (Invisible)
- **No checkbox** or visible challenge for users
- Runs in the background when form is submitted
- Returns a **score** from 0.0 to 1.0:
  - 1.0 = Very likely a human
  - 0.5 = Uncertain
  - 0.0 = Very likely a bot

### Our Configuration
- **Threshold:** 0.5 (adjustable in Lambda)
- Scores above 0.5 are accepted
- Scores below 0.5 are rejected

### Adjust Threshold (Optional)
In `contact-form.py`, line 47:
```python
return success and score > 0.5  # Change 0.5 to your preferred threshold
```

Recommendations:
- **0.7+** - Strict (may block some humans)
- **0.5** - Balanced (recommended)
- **0.3** - Lenient (may allow some bots)

## Testing

### Local Testing
1. Make sure `localhost` is in your reCAPTCHA domains
2. Test the form - check CloudWatch logs for the score
3. Adjust threshold if needed

### Production Testing
1. Submit the form from your live site
2. Check CloudWatch Logs:
   ```bash
   aws logs tail /aws/lambda/web-contact-form --follow --profile lybarra-main
   ```
3. Look for: `reCAPTCHA verification: success=True, score=0.9`

## Monitoring

### View reCAPTCHA Analytics
1. Go to https://www.google.com/recaptcha/admin
2. Select your site
3. View analytics dashboard with:
   - Request volume
   - Score distribution
   - Challenge solve rate

## Troubleshooting

### "reCAPTCHA verification failed"
- Check that Site Key matches in both files
- Verify Secret Key is in Terraform
- Check CloudWatch logs for details
- Ensure domain is registered in reCAPTCHA console

### Score too low for legitimate users
- Lower threshold (e.g., from 0.5 to 0.3)
- Check reCAPTCHA analytics for score distribution

### reCAPTCHA badge visible
This is normal for v3 - shows in bottom right corner:
- Required by Google's terms of service
- Can be hidden with CSS (but must keep terms link visible somewhere)

## Cost

**Free tier:**
- 1,000,000 assessments/month
- More than enough for a personal website

## Security Notes

✅ **Secret Key** is stored:
- In Terraform as a sensitive variable
- In Lambda environment variables
- Never exposed to frontend

✅ **Token validation** happens:
- On the backend (Lambda)
- Google's API verifies it
- Cannot be bypassed by client

## Alternative: Cloudflare Turnstile

If you prefer, Cloudflare Turnstile is a simpler, privacy-focused alternative:
- No tracking
- Better UX
- Similar implementation
- https://www.cloudflare.com/products/turnstile/

