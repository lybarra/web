class Terminal {
    constructor() {
        this.terminalOutput = document.getElementById('terminalOutput');
        this.terminalInput = document.getElementById('terminalInput');
        this.commandHistory = [];
        this.historyIndex = -1;
        this.data = {
            summary: `DevOps Engineer with 3+ years of experience managing scalable infrastructure on AWS and Kubernetes. Specialized in cloud automation, CI/CD pipelines, and infrastructure security. Passionate about optimizing developer workflows and delivering reliable, secure platforms using tools like Terraform, Terragrunt, ArgoCD, Prometheus, and Serverless Framework. Known for collaborating effectively across teams, I listen closely to stakeholder needs, communicate clearly with both technical and non-technical audiences, and bring patience and persistence to solving complex infrastructure challenges.`,
            skills: {
                'Cloud': 'AWS (EKS, ECS, Lambda, S3, IAM, SSO), Serverless Framework',
                'Containerization': 'Docker, Kubernetes, Karpenter',
                'IaC': 'Terraform, Terragrunt, Kustomize, Helm, CloudFormation',
                'CI/CD': 'GitHub Actions, GitLab, CircleCI',
                'Monitoring': 'Prometheus, Grafana, OpenSearch, Fluent Bit, Datadog, Prometheus adapter',
                'Languages': 'Bash, Python',
                'Cloud Native Projects': 'ArgoCD, Traefik, Linkerd, Metrics server, kubecost'
            },
            certifications: [
                'AWS Certified SysOps Administrator – Associate [2024]',
                'Certified Kubernetes Administrator – CKA [2024]',
                'Deep Learning Diploma – ITBA [2020]'
            ],
            education: [
                'Electrical Engineer - Rosario National University [2012 - 2019]'
            ]
        };

        this.init();
    }

    init() {
        this.terminalInput.addEventListener('keydown', (e) => this.handleInput(e));
        this.displayWelcomeMessage();
        this.terminalInput.focus();
    }

    displayWelcomeMessage() {
        const welcomeMessage = `Welcome to Lisandro Ybarra's terminal!
Type 'help' to see available commands.
`;
        this.appendOutput(welcomeMessage);
    }

    handleInput(e) {
        if (e.key === 'Enter') {
            const command = this.terminalInput.value.trim();
            this.commandHistory.push(command);
            this.historyIndex = this.commandHistory.length;
            this.executeCommand(command);
            this.terminalInput.value = '';
        } else if (e.key === 'ArrowUp') {
            e.preventDefault();
            if (this.historyIndex > 0) {
                this.historyIndex--;
                this.terminalInput.value = this.commandHistory[this.historyIndex];
            }
        } else if (e.key === 'ArrowDown') {
            e.preventDefault();
            if (this.historyIndex < this.commandHistory.length - 1) {
                this.historyIndex++;
                this.terminalInput.value = this.commandHistory[this.historyIndex];
            } else {
                this.historyIndex = this.commandHistory.length;
                this.terminalInput.value = '';
            }
        }
    }

    executeCommand(command) {
        this.appendOutput(`visitor@lybarra-web:~$ ${command}\n`);
        
        const cmd = command.toLowerCase();
        switch (cmd) {
            case 'help':
                this.showHelp();
                break;
            case 'clear':
                this.clearTerminal();
                break;
            case 'whoami':
                this.appendOutput('Lisandro Ybarra - DevOps Engineer\n');
                break;
            case 'ls':
            case 'ls -l':
                this.listFiles();
                break;
            case 'cat summary.txt':
                this.appendOutput(this.data.summary + '\n');
                break;
            case 'cat skills.txt':
                this.showSkills();
                break;
            case 'cat certifications.md':
                this.showCertifications();
                break;
            case 'cat education.txt':
                this.showEducation();
                break;
            default:
                this.appendOutput(`Command not found: ${command}. Type 'help' for available commands.\n`);
        }
    }

    showHelp() {
        const helpText = `
Available commands:
  help               - Show this help message
  clear             - Clear the terminal
  whoami            - Display name and title
  ls                - List available files
  cat summary.txt   - Display professional summary
  cat skills.txt    - Display technical skills
  cat certifications.md - Display certifications
  cat education.txt - Display education history
`;
        this.appendOutput(helpText);
    }

    listFiles() {
        const files = `
-rw-r--r-- summary.txt
-rw-r--r-- skills.txt
-rw-r--r-- certifications.md
-rw-r--r-- education.txt
`;
        this.appendOutput(files);
    }

    showSkills() {
        let output = '\nTechnical Skills:\n';
        for (const [category, skills] of Object.entries(this.data.skills)) {
            output += `● ${category}: ${skills}\n`;
        }
        this.appendOutput(output);
    }

    showCertifications() {
        let output = '\nCertifications:\n';
        this.data.certifications.forEach(cert => {
            output += `- ${cert}\n`;
        });
        this.appendOutput(output);
    }

    showEducation() {
        let output = '\nEducation:\n';
        this.data.education.forEach(edu => {
            output += `- ${edu}\n`;
        });
        this.appendOutput(output);
    }

    clearTerminal() {
        this.terminalOutput.innerHTML = '';
    }

    appendOutput(text) {
        const output = document.createElement('div');
        output.className = 'command-output';
        output.innerText = text;
        this.terminalOutput.appendChild(output);
        this.terminalOutput.scrollTop = this.terminalOutput.scrollHeight;
    }
}

// Initialize the terminal when the page loads
document.addEventListener('DOMContentLoaded', () => {
    new Terminal();
}); 