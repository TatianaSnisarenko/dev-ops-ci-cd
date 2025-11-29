# Architecture Overview — Final DevOps Project on AWS

This document describes the high-level architecture of the final DevOps project on AWS.

The infrastructure is provisioned using **Terraform** and runs on **AWS**.  
Application deployment and CI/CD are handled by **Jenkins** and **Argo CD** on top of **EKS**.  
Monitoring is done with **Prometheus + Grafana**.

---

## 1. High-Level Components

- **VPC**

  - Custom VPC with CIDR (e.g. `10.0.0.0/16`)
  - Public subnets (for NAT/ingress/load balancers)
  - Private subnets (for EKS nodes, RDS)
  - Internet Gateway, NAT Gateways, Route Tables

- **EKS Cluster**

  - Managed Kubernetes cluster (control plane by AWS)
  - Worker nodes (Managed Node Group) in private subnets
  - EBS CSI driver installed for dynamic volume provisioning

- **RDS / Aurora**

  - Universal Terraform RDS module (standard RDS or Aurora PostgreSQL, configurable via `use_aurora`)
  - Private DB Subnet Group (only private subnets)
  - Security Group allowing PostgreSQL from VPC CIDR
  - Parameter Group with basic settings (`max_connections`, `log_statement`, `work_mem`)

- **ECR**

  - Private Docker image repository for Django app
  - Used by Jenkins to push images and by EKS to pull images

- **Jenkins**

  - Installed via Helm on EKS in namespace `jenkins`
  - Used to:
    - Build Docker images
    - Push images to ECR
    - Update Helm chart values (image tags) in Git repository

- **Argo CD**

  - Installed via Helm on EKS in namespace `argocd`
  - GitOps controller:
    - Watches Git repository with Helm chart
    - Syncs changes to EKS (Django app deployment, ConfigMap, Secrets, HPA)

- **Django Application**

  - Deployed to EKS via a Helm chart (`charts/django-app`)
  - Uses:
    - Deployment
    - Service (LoadBalancer)
    - ConfigMap for non-sensitive config
    - Secret for DB credentials (created by Terraform)
    - Horizontal Pod Autoscaler (HPA)

- **Monitoring**

  - Namespace: `monitoring`
  - Prometheus:
    - Deployed via Helm `prometheus-community/prometheus`
    - Scrapes metrics from Kubernetes components
  - Grafana:
    - Deployed via Helm `grafana/grafana`
    - Uses Prometheus as a data source
    - Displays Kubernetes & application dashboards

- **Backend for Terraform state**
  - S3 bucket for remote Terraform state
  - DynamoDB table for state locking

---

## 2. Logical Diagram (Textual)

```text
               +------------------------------+
               |           AWS VPC           |
               |        (10.0.0.0/16)        |
               +------------------------------+
                       |              |
                Public Subnets   Private Subnets
                       |              |
        +--------------+              +-------------------------+
        |                                                       |
+--------------------+                              +------------------------+
|  Internet Gateway  |                              |  EKS Managed Node      |
+--------------------+                              |  Group (EC2 workers)   |
                                                    +-----------+------------+
                                                                |
                                                                |
                                                      +---------+--------+
                                                      |    EKS Cluster   |
                                                      |   (Control Plane)|
                                                      +---------+--------+
                                                                |
                   +-----------------------+--------------------+-----------------------+
                   |                       |                    |                       |
           +-------+-------+       +-------+-------+    +-------+--------+      +-------+-------+
           |   Jenkins     |       |    Argo CD    |    | Django App     |      | Monitoring    |
           |  (namespace   |       |  (namespace   |    | (namespace     |      | (namespace    |
           |   jenkins)    |       |   argocd)     |    |  default)      |      |  monitoring)  |
           +---------------+       +---------------+    +----------------+      +---------------+
                   |                       |                    |                       |
                   |                       |                    |                       |
       Builds & pushes images      Syncs Helm chart      Uses RDS endpoint       Prometheus & Grafana
       to ECR via CI pipeline      from Git to EKS       & credentials from      scrape & visualize
                                                          K8s Secret             cluster metrics
```

## Data Flows

### 1. CI/CD Pipeline

1. Developer pushes code to GitHub.
2. Jenkins pipeline (Jenkinsfile) is triggered.
   Jenkins:
   - Builds Docker image for the Django app.
   - Pushes the image to ECR.
   - Updates the Helm chart values (image tag) in the Git repository.
3. Argo CD monitors the Git repository:
   - Detects changes to the Helm chart.
   - Applies changes to EKS (Deployment update).
   - Rolls out the new version of the Django app.

### 2. Application → Database

- Terraform provisions RDS (or Aurora) using the `rds` module.
- Terraform creates a Kubernetes Secret `django-db` containing:
  - `DB_HOST`, `DB_PORT`, `DB_NAME`
  - `DB_USER`, `DB_PASSWORD`
  - `DATABASE_URL`
- The Helm chart (`charts/django-app`) mounts this Secret as environment variables.
- The Django app reads those env vars and connects to the database.

### 3. Monitoring

- Prometheus (namespace `monitoring`) scrapes metrics from:
  - Kubernetes API
  - Node exporter
  - kube-state-metrics
- Grafana uses Prometheus as a data source and shows dashboards (CPU, memory, pod counts, etc.).
- HPA uses Kubernetes metrics (via metrics-server) to scale application pods based on CPU usage. Prometheus provides additional observation/visibility.

## Security & Isolation

- VPC
  - Private subnets for EKS worker nodes and RDS.
  - Public subnets only for NAT Gateways and external load balancers.
- Security Groups
  - RDS SG allows PostgreSQL (port 5432) only from the VPC CIDR.
  - EKS nodes use security groups created by the EKS module.
  - Load Balancers use security groups managed by Kubernetes Service objects.
- IAM
  - A Terraform IAM user (or role) is used for infrastructure provisioning.
  - EKS-associated IAM roles are created/used for node and control-plane integration.

## Autoscaling

- HPA is configured in the Django Helm chart:
  - Scales pods based on CPU utilization.
  - Typical config: `minReplicas: 1`, `maxReplicas: 3`, target CPU ~70%.
- Required components:
  - Metrics Server (in-cluster) — required for HPA.
  - Prometheus — for monitoring and visibility (not required for HPA but recommended).

## This architecture models a production-like DevOps deployment on AWS with:

- Infrastructure as Code (Terraform)
- CI/CD (Jenkins + Argo CD)
- Managed Kubernetes (EKS)
- Managed database (RDS / Aurora)
- Monitoring (Prometheus + Grafana)
- Remote Terraform state (S3 + DynamoDB)
