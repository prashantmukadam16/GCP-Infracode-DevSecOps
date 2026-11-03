# GCP Terraform Modules + Jenkins CI/CD

This starter repository provisions:
- Custom VPC and regional web/app subnets
- Private Service Access for Cloud SQL
- Private-IP Cloud SQL for MySQL
- Compute Engine instance template, regional Managed Instance Group, health check, and CPU autoscaler
- Jenkins pipeline for Terraform fmt, init, validate, plan, approval, and apply

## Important

This is a starter example, not a production-ready application platform. Review all quotas, regional zones, firewall rules, IAM, secrets, costs, and application requirements before deployment. The autoscaling example uses NGINX as a placeholder app. It does not include an external HTTP(S) load balancer.

## Repository layout

```text
.
├── Jenkinsfile
├── terraform/
│   ├── backend.tf.example
│   ├── versions.tf
│   ├── variables.tf
│   ├── terraform.tfvars.example
│   ├── main.tf
│   ├── outputs.tf
│   └── modules/
│       ├── network/
│       ├── mysql/
│       └── autoscaling/
└── .gitignore
```

## Prerequisites

- GCP project and billing enabled
- Terraform >= 1.5
- Jenkins agent with Terraform and `gcloud` installed
- A dedicated Jenkins service account or Workload Identity Federation
- Required APIs enabled
- A pre-created GCS bucket for Terraform state

Enable APIs (run with an appropriately privileged administrator identity):

```bash
gcloud services enable \
  compute.googleapis.com \
  sqladmin.googleapis.com \
  servicenetworking.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --project YOUR_GCP_PROJECT_ID
```

## Configure

1. Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and set your project ID.
2. For remote state, copy `terraform/backend.tf.example` to `terraform/backend.tf`, replace the bucket name, and make sure the bucket exists first.
3. Configure Jenkins authentication securely. Prefer Workload Identity Federation. Do not commit service-account JSON keys or database passwords.
4. In the Jenkinsfile, set `GOOGLE_PROJECT` or provide it as a Jenkins parameter/credential.
5. Ensure the Jenkinsfile `dir('terraform')` matches this repository layout.
6. Review the sample CIDR ranges and ensure they do not overlap with existing networks.

## Run locally (optional)

```bash
cd terraform
terraform init
terraform fmt -recursive
terraform validate
terraform plan -var="project_id=YOUR_GCP_PROJECT_ID"
```

Apply only after reviewing the plan:

```bash
terraform apply -var="project_id=YOUR_GCP_PROJECT_ID"
```

## Jenkins flow

Checkout → Terraform init → fmt check → validate → plan → manual approval → apply.

The pipeline expects `GOOGLE_PROJECT` to be configured in its environment. For production, use Jenkins credentials / workload identity and avoid hard-coded project IDs.

## Security and production notes

- VMs have no external IP. Package installation in the example startup script requires controlled egress (for example, Cloud NAT) or a prebuilt image; Cloud NAT is not included.
- The sample app firewall rule allows TCP/8080 from a placeholder proxy-only subnet. The NGINX sample listens on port 80. Adjust the firewall and health-check design consistently before deployment.
- No load balancer is included. The MIG and autoscaler can be created without one, but application traffic routing requires a suitable load balancer or another access path.
- Cloud SQL private IP uses Private Service Access. The allocated range must not overlap with existing VPC ranges or other allocated service ranges.
- `MYSQL_8_0` is an example engine version; check currently supported versions in your target region.
- Cloud SQL is configured with regional HA and backups, which increase cost.
- Deletion protection is enabled. To intentionally destroy the DB, first disable it in configuration and apply that change, then destroy in a separately approved process.
- Terraform state and plan files can contain sensitive data. Restrict access, enable bucket versioning, and do not publish state or plan artifacts.
