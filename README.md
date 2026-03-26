# 3-Tier AWS VPC — Terraform Portfolio Project

> **Author:** Lereko Mohlomi 
> **GitHub:** [@TheoMcCoy](https://github.com/TheoMcCoy)  
> **Stack:** Terraform · AWS · RDS PostgreSQL · EC2 · ALB  
> **Provider:** `hashicorp/aws ~> 5.80`  
> **Last Updated:** 2026

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Terraform File Breakdown](#terraform-file-breakdown)
4. [Security Decisions](#security-decisions)
5. [How to Deploy](#how-to-deploy)
6. [Cost Estimate](#cost-estimate)
7. [Lessons Learned](#lessons-learned)

---

## Architecture Overview

This project provisions a production-pattern, 3-tier AWS VPC across **2 Availability Zones** using Terraform. It separates concerns into three network tiers — each with distinct trust boundaries — and uses security group chaining to enforce least-privilege traffic flow.

| Tier | Resources | Subnet Type |
|------|-----------|-------------|
| **Web** | ALB + EC2 (Auto Scaling Group) | Public |
| **App** | EC2 (private application servers) | Private |
| **Database** | RDS PostgreSQL (`db.t3.micro`) | Private |

**Well-Architected Alignment:**  
[Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html) · [Reliability Pillar](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/welcome.html) · [Cost Optimization Pillar](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/welcome.html)

---

## Architecture Diagram
![3TierArch.png](./3TierArch.png)


---


---


---

## Terraform File Breakdown

```
.
├── docs/                           # Documents Folder
|   ├── terraform-plan-output.txt   # Output Plan
├── main.tf                         # Provider config, locals, data sources
├── vpc.tf                          # VPC, subnets, IGW, route tables, NAT Gateway
├── security_groups.tf              # All SG definitions + chaining rules
├── alb.tf                          # Application Load Balancer, target group, listener
├── ec2.tf                          # Web tier ASG + launch template
├── app.tf                          # App tier EC2 instances
├── rds.tf                          # RDS PostgreSQL instance + subnet group
├── variables.tf                    # Input variable declarations
├── outputs.tf                      # ALB DNS, DB endpoint, VPC ID
└── terraform.tfvars                # Variable values (gitignored — never commit secrets)
```

**Key design choices:**
- All resources tagged with `ManagedBy = "Terraform"` for IaC traceability
- `terraform.tfvars` is in `.gitignore` — DB passwords never touch source control
- Outputs expose only what downstream systems need (ALB DNS, DB endpoint)

---

## Security Decisions

### 1. App and DB Tiers Are in Private Subnets

The App and Database tiers have no route to the Internet Gateway and carry no public IP addresses. This enforces the principle of **defence in depth** — even if the Web tier is compromised, the attacker cannot directly reach the application logic or data store without pivoting through an additional layer.

> **Well-Architected reference:** [SEC 6 — Protect compute](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/sec_protect_compute_reduce_exposure.html)

---

### 2. Security Group Chaining

Rather than opening ports to broad CIDR ranges, each tier's inbound rule references the **Security Group ID** of the tier above it:

```hcl
# App SG — only accepts traffic from Web EC2 instances
ingress {
  from_port       = 8080
  to_port         = 8080
  protocol        = "tcp"
  security_groups = [aws_security_group.web.id]   # SG reference, not CIDR
}

# DB SG — only accepts traffic from App EC2 instances
ingress {
  from_port       = 5432
  to_port         = 5432
  protocol        = "tcp"
  security_groups = [aws_security_group.app.id]   # SG reference, not CIDR
}
```

This means if you scale the App tier horizontally, the DB SG rule requires zero modification — new App instances inherit the SG and automatically gain DB access. No manual CIDR management. No risk of overly broad rules accumulating over time.

> **Well-Architected reference:** [SEC 5 — Network protection](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/sec_network_protection_create_layers.html)

---

### 3. `publicly_accessible = false` on RDS

```hcl
publicly_accessible = false
```

This instructs RDS not to provision a public DNS endpoint, regardless of subnet placement. Even if the subnet group were misconfigured to include a public subnet, the database would remain unreachable from the internet. This is a belt-and-suspenders control layered on top of subnet isolation.

> **Well-Architected reference:** [SEC 5 — Protecting networks](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/sec_network_protection_create_layers.html)

---

### 4. Secrets Management

The DB master password is passed via `var.db_master_password` and supplied through `terraform.tfvars`, which is gitignored. For a production deployment, this variable would be sourced from **AWS Secrets Manager** or **SSM Parameter Store** using a `data` block — removing the secret from local state entirely.

> **Well-Architected reference:** [SEC 9 — Protect data at rest](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/sec_protect_data_rest_key_mgmt.html)

---

### 5. Resource Tagging for IaC Discipline

Every resource carries:

```hcl
tags = merge(local.common_tags, {
  ManagedBy = "Terraform"
})
```

Where `local.common_tags` includes `Project`, `Environment`, and `Owner`. This enables cost allocation, automated compliance checks, and clear ownership — all auditable without touching the console.

> **Well-Architected reference:** [COST 2 — Governance](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/cost_govern_usage_establish_policies.html)

---

## How to Deploy

### Prerequisites

- Terraform >= 1.5
- AWS CLI configured (`aws configure`)
- IAM permissions: EC2, VPC, RDS, ELB, IAM (for instance profiles)

### Steps

```bash
# 1. Clone the repo
git clone https://github.com/TheoMcCoy/3tier-vpc-terraform.git
cd <repo-name>

# 2. Create your tfvars (never commit this file)
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set db_master_password and any overrides

# 3. Initialise providers
terraform init

# 4. Review the execution plan BEFORE applying
terraform plan -out=tfplan

# 5. Apply
terraform apply tfplan
```

### Terraform Plan

> **Note for reviewers:** Run `terraform plan` after `terraform init` to see the full resource creation list. Expected output: ~30–35 resources across VPC, subnets, route tables, SGs, ALB, ASG, EC2, and RDS.  
> A sample plan output is available in [`/docs/terraform-plan-output.txt`](./docs/terraform-plan-output.txt).

### Teardown

```bash
terraform destroy
```

> `skip_final_snapshot = true` is set on the RDS instance — destroy will not leave a snapshot. Intentional for dev/portfolio use.

---

## Cost Estimate

> All estimates based on **us-east-1**, Free Tier assumed where applicable. Costs are approximate and depend on traffic and uptime.

| Resource | Type | Est. Monthly Cost |
|----------|------|-------------------|
| Web EC2 (x2) | `t2.micro` / Free Tier | $0.00 |
| App EC2 (x2) | `t2.micro` / Free Tier | $0.00 |
| RDS PostgreSQL | `db.t3.micro` / Free Tier (750 hrs) | $0.00 |
| ALB | Per LCU + hourly | ~$16–20 |
| NAT Gateway | Per GB + hourly | ~$32–45 |
| EBS Storage (20 GB RDS) | Free Tier | $0.00 |
| **Total (est.)** | | **~$50–65/month** |

**Cost decisions documented:**
- Aurora Serverless v2 was evaluated but replaced with `db.t3.micro` RDS — Aurora charges by ACU even at minimum capacity, adding ~$30–50/month with zero benefit for a portfolio workload.
- `multi_az = false` on RDS — Multi-AZ doubles the DB instance cost. Documented as a production gap, not an oversight.
- For a zero-cost teardown strategy, destroy the stack after demo and redeploy on demand. Full `terraform apply` completes in under 5 minutes.

> **Well-Architected reference:** [COST 7 — Manage demand and supply resources](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/cost_manage_demand_resources_cost_effective.html)

---

**Read Replica Capability**

This instance is read-replica ready. `backup_retention_period = 1` is the minimum RDS requires before a replica can be created. In a production deployment, a read replica would be added as a second `aws_db_instance` resource using `replicate_source_db`:

```hcl
resource "aws_db_instance" "database_replica" {
  identifier          = "${local.project}-db-replica"
  replicate_source_db = aws_db_instance.database.identifier
  instance_class      = "db.t3.micro"
  publicly_accessible = false
  skip_final_snapshot = true
  multi_az            = false
  tags                = local.common_tags
}
```

This is intentionally not deployed — a replica is a second billable instance and provides no demonstrable value in a portfolio context. The architecture supports it; the cost decision drives the omission.

---


## Lessons Learned

### 1. Provider Version Pinning Matters More Than You Think

I hit a Terraform error when using `express_configuration` on `aws_rds_cluster` — the block wasn't available until provider `v5.80+`. My initial pin was `~> 5.67.0`. The fix was a provider bump and `terraform init -upgrade`, but the lesson is: **always verify that the resource arguments you're using exist in your pinned provider version.** The AWS provider changelog is the source of truth, not the Terraform docs (which sometimes lag).

---


### 2. Aurora vs. RDS — Know When to Simplify

I designed the DB tier for Aurora Serverless v2 with `express_configuration`. The architecture was sound, but for a Free Tier portfolio project it was over-engineered and would cost real money the moment it provisioned. I documented the Aurora intent in the README and switched to `db.t3.micro` RDS PostgreSQL — demonstrating the same VPC isolation, SG chaining, and `publicly_accessible = false` patterns at zero cost. Hiring managers reviewing portfolios understand cost tradeoffs. Burning $50/month on a demo cluster doesn't signal seniority.

---

### 3. Security Group Chaining — Practical, Not Just Theoretical

Most tutorials show inbound rules as CIDR blocks (`10.0.0.0/8`). I implemented SG-to-SG references throughout this project. The operational benefit became clear immediately: when I modified the App tier ASG min/max values, the DB security group required zero changes. The SG reference is dynamic — it covers all current and future instances carrying that SG. This is the production pattern and it should be the default, not the advanced option.

---

*Built as part of an active Cloud Security Engineering portfolio. Feedback welcome via GitHub Issues.*