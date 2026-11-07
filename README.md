# roboshop_complete_deployment
A complete end-to-end deployment of roboshop web-app using CI/CD, terraform, docker, AWS, Prometheus-Grafana, ELK stack

## Project Overview

This repository contains the complete deployment infrastructure and microservices architecture for the **roboshop** e-commerce application. The project implements a full cloud-native deployment pipeline including:

- **Infrastructure as Code** with Terraform for AWS resources
- **Containerized microservices** using Docker
- **Kubernetes** deployment manifests
- **CI/CD pipeline** with GitHub Actions
- **Monitoring and observability** integration

## Architecture

The application follows a microservices architecture with the following components:

| Service | Technology | Database |
|---------|-----------|----------|
| **Frontend** | Nginx | - |
| **Catalogue** | Node.js | MongoDB |
| **User** | Node.js | MongoDB + Redis |
| **Cart** | Java (JVM) | - |
| **Payment** | Node.js | - |
| **Shipping** | Java (JVM) | MySQL |

## Repository Structure

```
.
├── .github/              # GitHub Actions workflows
├── docker/               # Dockerfiles and service configurations
│   ├── cart/             # Cart service (Java)
│   ├── catalogue/        # Catalogue service (Node.js)
│   ├── frontend/         # Nginx frontend
│   ├── mongodb/          # MongoDB Docker config
│   ├── mysql/            # MySQL Docker config
│   ├── payment/          # Payment service
│   ├── shipping/         # Shipping service (Java)
│   └── user/             # User service (Node.js)
├── infrastructure/       # Terraform AWS infrastructure
│   ├── eks/              # EKS cluster configuration
│   ├── route53/          # DNS configuration
│   ├── vpc/              # VPC network setup
│   ├── variables.tf      # Input variables
│   └── main.tf           # Main Terraform configuration
├── k8s/                  # Kubernetes manifests
│   ├── base/             # Base deployments, services, ingress
│   └── ...
├── sonar-project.properties  # SonarCloud analysis config
└── .gitignore
```

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/deploy.yml`) includes:

1. **SonarCloud Analysis** - Static code analysis
2. **Trivy Vulnerability Scan** - Container image security scanning
3. **Checkov/Terraform Security Scan** - Infrastructure as code security
4. **Terraform Validate & Plan** - Infrastructure validation
5. **Manual Approval Gate** - Production deployment requires approval
6. **Deploy to EKS** - Infrastructure apply and Kubernetes manifest deployment

The destroy workflow (`.github/workflows/destroy.yml`) provides a manual infrastructure teardown.

## Getting Started

### Prerequisites

- AWS account with appropriate permissions
- Terraform >= 1.0.0
- Docker
- kubectl
- AWS CLI configured with credentials

### Local Development

Each microservice can be built and run locally using its respective Dockerfile. See individual service directories for build instructions.

### Terraform Deployment

```bash
# Initialize Terraform
terraform -chdir=infrastructure init

# Validate configuration
terraform -chdir=infrastructure validate

# View planned changes
terraform -chdir=infrastructure plan

# Apply infrastructure
terraform -chdir=infrastructure apply
```

## Monitoring & Observability

- **Prometheus-Grafana**: Metrics collection and visualization
- **ELK Stack**: Log aggregation and analysis
- **Instana**: Application performance monitoring (instrumented in all services)
- **Health endpoints**: Each service exposes `/health` endpoint

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request
4. CI/CD pipeline will run automated testing and security scanning
5. Manual approval required for production deployments

## License

This project is licensed under the terms specified in the repository.

## Contact

For questions and support, please open an issue in the GitHub repository.
