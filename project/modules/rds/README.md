# Universal RDS / Aurora module

This module creates:

- **either** a regular RDS instance (`aws_db_instance`)
- **or** an Aurora PostgreSQL Cluster (`aws_rds_cluster` + writer + readers)

depending on the value of the `use_aurora` variable.

In all cases the module automatically creates:

- `aws_db_subnet_group`
- `aws_security_group`
- `aws_db_parameter_group` **or** `aws_rds_cluster_parameter_group`

The module is designed to:

- be reusable across multiple environments (dev/stage/prod);
- switch the database type (RDS ↔ Aurora) via a single variable without changing the main code;
- provide clear variables with types, descriptions and sensible defaults.

---

## Example 1 - Regular RDS PostgreSQL (as used in the project)

```hcl
module "rds_postgres" {
  source = "./modules/rds"

  name       = "${var.cluster_name}-db"
  use_aurora = false

  # RDS-only
  engine                     = "postgres"
  engine_version             = "17.2"
  parameter_group_family_rds = "postgres17"

  # Shared parameters
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username
  password = random_password.rds_master.result

  vpc_id             = module.vpc.vpc_id
  subnet_private_ids = module.vpc.private_subnet_ids
  subnet_public_ids  = module.vpc.public_subnet_ids
  publicly_accessible = false
  multi_az            = false

  vpc_cidr_block          = var.vpc_cidr_block
  backup_retention_period = "0"

  parameters = {
    max_connections            = "200"
    log_min_duration_statement = "500"
  }

  tags = {
    Environment = "dev"
    Project     = var.cluster_name
  }
}
```

## Example 2 - Aurora PostgreSQL Cluster

```hcl
module "rds_aurora" {
  source = "./modules/rds"

  name       = "${var.cluster_name}-aurora"
  use_aurora = true

  # Aurora-only
  engine_cluster             = "aurora-postgresql"
  engine_version_cluster     = "15.3"
  parameter_group_family_aurora = "aurora-postgresql15"
  aurora_replica_count       = 1

  # RDS-only (ігноруються, коли use_aurora = true)
  engine                     = "postgres"
  engine_version             = "17.2"
  parameter_group_family_rds = "postgres17"

  # Спільні параметри
  instance_class    = "db.t3.medium"
  allocated_storage = 20 # лише для RDS, Aurora масштабує storage сама

  db_name  = "myapp"
  username = "postgres"
  password = random_password.rds_master.result

  vpc_id             = module.vpc.vpc_id
  subnet_private_ids = module.vpc.private_subnet_ids
  subnet_public_ids  = module.vpc.public_subnet_ids
  publicly_accessible = false

  vpc_cidr_block          = var.vpc_cidr_block
  backup_retention_period = "0"

  parameters = {
    max_connections            = "200"
    log_min_duration_statement = "500"
  }

  tags = {
    Environment = "dev"
    Project     = var.cluster_name
  }
}
```

## Main variables

| Variable                      |         Type |        Default        | Description                                                                       |
| ----------------------------- | -----------: | :-------------------: | --------------------------------------------------------------------------------- |
| name                          |       string |           —           | Base name for the DB resources (used in identifiers / group names).               |
| use_aurora                    |         bool |         false         | If true — create an Aurora cluster; if false — create a regular RDS instance.     |
| engine                        |       string |      "postgres"       | Engine for regular RDS (postgres, mysql, etc.).                                   |
| engine_version                |       string |        "17.2"         | Engine version for regular RDS.                                                   |
| parameter_group_family_rds    |       string |     "postgres17"      | Parameter group family for RDS.                                                   |
| engine_cluster                |       string |  "aurora-postgresql"  | Engine for Aurora (aurora-postgresql, aurora-mysql).                              |
| engine_version_cluster        |       string |        "15.3"         | Engine version for Aurora.                                                        |
| parameter_group_family_aurora |       string | "aurora-postgresql15" | Parameter group family for Aurora.                                                |
| aurora_replica_count          |       number |           1           | Number of Aurora read-replica instances.                                          |
| instance_class                |       string |     "db.t3.micro"     | Instance class for RDS / Aurora (db.t3.micro, db.t3.medium, ...).                 |
| allocated_storage             |       number |          20           | Storage size for regular RDS (GB). Ignored for Aurora.                            |
| db_name                       |       string |           —           | Database name.                                                                    |
| username                      |       string |           —           | Database master/admin username.                                                   |
| password                      |       string |     — (sensitive)     | Database user password (sensitive).                                               |
| vpc_id                        |       string |           —           | VPC ID where the database will be deployed.                                       |
| subnet_private_ids            | list(string) |           —           | List of private subnet IDs for RDS/Aurora.                                        |
| subnet_public_ids             | list(string) |           —           | List of public subnet IDs (used when publicly_accessible = true).                 |
| publicly_accessible           |         bool |         false         | Whether the instance should be publicly accessible.                               |
| multi_az                      |         bool |         false         | Enable Multi-AZ for regular RDS.                                                  |
| vpc_cidr_block                |       string |           —           | VPC CIDR used in SG ingress (access to DB from the VPC).                          |
| parameters                    |  map(string) |          {}           | Map of parameter group settings (e.g., max_connections, log_statement, work_mem). |
| backup_retention_period       |       string |          "7"          | Number of days to retain automated backups (0 = disabled).                        |
| tags                          |  map(string) |          {}           | Additional tags applied to all resources.                                         |

## Outputs

|            Output | Description                                                    |
| ----------------: | -------------------------------------------------------------- |
|          endpoint | DNS endpoint of the database (RDS instance or Aurora cluster). |
|              port | Database port.                                                 |
|           db_name | Database name.                                                 |
|   master_username | Master (admin) username.                                       |
|   master_password | Master password (sensitive).                                   |
| security_group_id | ID of the Security Group attached to the database.             |

# Change DB type / engine / instance class

## DB type (RDS ↔ Aurora)

- Toggle the `use_aurora` variable:
  - `use_aurora = false` → regular RDS instance
  - `use_aurora = true` → Aurora cluster

## Engine / version

- For RDS (regular):
  - set `engine`, `engine_version`, `parameter_group_family_rds`
- For Aurora:
  - set `engine_cluster`, `engine_version_cluster`, `parameter_group_family_aurora`

Example — RDS:

```terraform
variable "use_aurora" { default = false }
variable "engine" { default = "postgres" }
variable "engine_version" { default = "17.2" }
variable "parameter_group_family_rds" { default = "postgres17" }
```

Example — Aurora:

```terraform
variable "use_aurora" { default = true }
variable "engine_cluster" { default = "aurora-postgresql" }
variable "engine_version_cluster" { default = "15.3" }
variable "parameter_group_family_aurora" { default = "aurora-postgresql15" }
```

### Resource recommendations (dev vs prod)

**Dev:**
instance_class = "db.t3.micro"
backup_retention_period = "1"
multi_az = false

**Prod:**
instance_class = "db.t3.medium" (or larger)
multi_az = true
backup_retention_period = "7" (or higher)

```terraform
# dev
instance_class = "db.t3.micro"
backup_retention_period = "1"
multi_az = false

# prod
instance_class = "db.t3.medium"
backup_retention_period = "7"
multi_az = true
```
