/**
 * Contact Form Handler
 * Submits form data to AWS API Gateway endpoint
 */

// API Gateway endpoint
const API_ENDPOINT = 'https://api.lisandroybarra.com/contact';

// reCAPTCHA Site Key (public key)
const RECAPTCHA_SITE_KEY = '6LdZL-krAAAAADGppH8g95lo9TVUXCY2nG8yr5pm';

class ContactForm {
    constructor() {
        this.form = document.getElementById('contactForm');
        this.submitBtn = document.getElementById('submitBtn');
        this.statusDiv = document.getElementById('formStatus');
        this.init();
    }

    init() {
        if (this.form) {
            this.form.addEventListener('submit', (e) => this.handleSubmit(e));
        }
    }

    async handleSubmit(e) {
        e.preventDefault();
        
        // Get form data
        const formData = {
            name: document.getElementById('name').value.trim(),
            email: document.getElementById('email').value.trim(),
            message: document.getElementById('message').value.trim()
        };

        // Validate form
        if (!this.validateForm(formData)) {
            return;
        }

        // Disable submit button and show loading
        this.setLoading(true);
        this.hideStatus();

        try {
            // Get reCAPTCHA token
            const recaptchaToken = await grecaptcha.execute(RECAPTCHA_SITE_KEY, {
                action: 'submit'
            });

            // Add reCAPTCHA token to form data
            formData.recaptchaToken = recaptchaToken;

            // Send request to API Gateway
            const response = await fetch(API_ENDPOINT, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(formData)
            });

            const result = await response.json();

            if (response.ok) {
                this.showStatus('success', '✓ Message sent successfully! I\'ll get back to you soon.');
                this.form.reset();
            } else {
                throw new Error(result.error || 'Failed to send message');
            }
        } catch (error) {
            console.error('Error submitting form:', error);
            this.showStatus('error', `✗ Error: ${error.message}. Please try again or contact me directly.`);
        } finally {
            this.setLoading(false);
        }
    }

    validateForm(data) {
        // Validate name
        if (data.name.length < 2) {
            this.showStatus('error', '✗ Name must be at least 2 characters long');
            return false;
        }

        // Validate email
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(data.email)) {
            this.showStatus('error', '✗ Please enter a valid email address');
            return false;
        }

        // Validate message
        if (data.message.length < 10) {
            this.showStatus('error', '✗ Message must be at least 10 characters long');
            return false;
        }

        if (data.message.length > 1000) {
            this.showStatus('error', '✗ Message is too long (max 1000 characters)');
            return false;
        }

        return true;
    }

    setLoading(isLoading) {
        if (isLoading) {
            this.submitBtn.disabled = true;
            this.submitBtn.innerHTML = '<span class="prompt">$</span> <span class="loading">sending</span>';
        } else {
            this.submitBtn.disabled = false;
            this.submitBtn.innerHTML = '<span class="prompt">$</span> send_message';
        }
    }

    showStatus(type, message) {
        this.statusDiv.className = `form-status ${type}`;
        this.statusDiv.textContent = message;
        
        // Auto-hide success messages after 5 seconds
        if (type === 'success') {
            setTimeout(() => {
                this.hideStatus();
            }, 5000);
        }
    }

    hideStatus() {
        this.statusDiv.className = 'form-status';
        this.statusDiv.textContent = '';
    }
}

// Initialize contact form when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new ContactForm();
});

