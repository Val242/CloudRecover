# CloudRecover

**A TypeScript and NestJS inventory API with automated AWS deployment, private infrastructure, monitoring, and recovery in a second AWS region.**

CloudRecover combines a practical backend with a disaster recovery exercise. The application manages products and stock movements. The infrastructure provisions isolated networks, deploys the API behind an Application Load Balancer, collects application and server metrics, and prepares database backups and application releases for restoration in another region.

The central question is: **Can the service be restored with verified inventory data when the primary environment is unavailable?**

> **Project status: In development.** This README describes the agreed architecture, API contract, and implementation plan. Infrastructure, workflows, and recovery results should be treated as planned until verified in the repository and AWS environment. The results table intentionally contains no invented measurements.

## Contents

- [Project goals](#project-goals)
- [Technology stack](#technology-stack)
- [Architecture](#architecture)
- [Networking and access](#networking-and-access)
- [API and inventory behavior](#api-and-inventory-behavior)
- [Local development](#local-development)
- [API examples](#api-examples)
- [Monitoring and alerts](#monitoring-and-alerts)
- [Infrastructure and repository organization](#infrastructure-and-repository-organization)
- [Deployment pipeline](#deployment-pipeline)
- [Backup and recovery](#backup-and-recovery)
- [Recovery exercise](#recovery-exercise)
- [Recovery objectives and results](#recovery-objectives-and-results)
- [Verification checklist](#verification-checklist)
- [Seven-day roadmap](#seven-day-roadmap)
- [Troubleshooting](#troubleshooting)
- [Resource cleanup and cost management](#resource-cleanup-and-cost-management)
- [Scope and future improvements](#scope-and-future-improvements)
- [References](#references)

## Project goals

CloudRecover builds on deployment and monitoring skills by adding a new application and a repeatable recovery process.

The intended outcomes are:

1. Build a functioning inventory API with validation and a persistent stock movement history.
2. Provision dedicated VPCs in two AWS regions using reusable Terraform modules.
3. Keep application, monitoring, and database resources in private subnets.
4. Expose the API through a public load balancer with HTTPS.
5. Deploy versioned application releases through GitHub Actions using short-lived AWS credentials.
6. Observe application behavior separately from host resource usage.
7. Copy database snapshots and required application dependencies to the recovery region.
8. Restore the service through a manually triggered, automated recovery workflow.
9. Validate recovered data before moving user traffic.
10. Measure actual downtime and data loss against defined recovery objectives.

Services run directly on Linux. Docker and Kubernetes are outside the initial implementation.

## Technology stack

| Area | Technology | Responsibility |
| --- | --- | --- |
| Language | TypeScript | Application implementation and type checking |
| Backend | NestJS on Node.js | REST endpoints, dependency injection, validation, health checks |
| Database access | Prisma ORM 7 | Typed queries, schema management, transactions |
| Local database | PostgreSQL | Local application development |
| Cloud database | Amazon RDS for PostgreSQL | Private, persistent inventory storage |
| Compute | Amazon EC2 | Application and monitoring servers |
| Public entry point | Application Load Balancer | HTTPS listener, target health checks, request forwarding |
| TLS certificates | AWS Certificate Manager | Regional certificates for the public ALBs |
| Reverse proxy | Nginx | Forward application requests locally and restrict metrics exposure |
| Service management | systemd | Start services at boot and restart failed processes |
| Infrastructure | Terraform | Networking, IAM, compute, database, and supporting resources |
| Automation | GitHub Actions | Checks, deployments, backups, recovery, and verification |
| AWS authentication | GitHub OIDC and IAM roles | Short-lived workflow credentials |
| Server management | AWS Systems Manager | Deployment commands and private administrative access |
| Release storage | Amazon S3 | Versioned application packages and recovery copies |
| Runtime credentials | AWS Secrets Manager | Database and other sensitive configuration |
| Encryption | AWS KMS | Encryption keys used by regional resources and snapshot copies |
| Application metrics | Prometheus Node.js client | Request counts, durations, and process metrics |
| Host metrics | Node Exporter | Linux CPU, memory, filesystem, and network metrics |
| Metrics collection | Prometheus | Scrape targets and retain time-series data |
| Dashboards | Grafana | Query Prometheus and visualize measurements |
| Alert routing | Alertmanager | Group and route Prometheus alerts |
| DNS | Amazon Route 53 | Resolve the API hostname to the selected regional ALB |
| Security checks | Gitleaks and dependency scanning | Detect committed secrets and dependency vulnerabilities |
| Testing | Jest and Supertest | Service and API behavior verification |

## Architecture

### Regional roles

The primary region serves normal traffic and holds the writable application database. The recovery region holds the dependencies needed to reconstruct the service.

The region pair and VPC ranges below are examples. They are configuration choices, not fixed AWS defaults or evidence of deployed resources.

| Role | Example region | Example VPC CIDR |
| --- | --- | --- |
| Primary | `us-east-1` — Northern Virginia | `10.10.0.0/16` |
| Recovery | `us-west-2` — Oregon | `10.20.0.0/16` |

Both regions use the same Terraform architecture. In the backup-and-restore design, recovery networking is prepared first; the recovery ALB, EC2 instances, and restored database are created when recovery is triggered. A recovery NAT gateway can also be provisioned on demand.

| Component | Normal primary state | Normal recovery state |
| --- | --- | --- |
| Dedicated VPC and subnets | Provisioned | Provisioned |
| ALB and application EC2 | Running | Created during recovery |
| Prometheus and Grafana EC2 | Running | Created during recovery |
| RDS PostgreSQL | Running | Restored from a copied snapshot during recovery |
| Database snapshots | Produced by backup workflow | Completed copies available |
| Application releases | Published by deployment workflow | Compatible copies available |
| Configuration, secrets, keys, certificates | Available | Prepared independently |
| API DNS target | Primary ALB | Selected only after recovery verification |

### Request flow and regional recovery

The following diagram shows the main request and recovery paths. The monitoring connections are expanded in the next diagram. DNS arrows indicate hostname resolution; DNS does not proxy HTTP requests.

```mermaid
flowchart TD
    CLIENT["API clients"]
    DNS["Route 53 API hostname"]
    CLIENT -.->|"DNS lookup"| DNS
    CLIENT -->|"Normal HTTPS traffic"| PALB
    CLIENT -.->|"HTTPS after recovery cutover"| RALB
    DNS -.->|"Normal DNS target"| PALB
    DNS -.->|"Verified recovery target"| RALB

    subgraph PRIMARY["Primary VPC: active environment"]
        direction TB
        PALB["Public ALB: HTTPS 443"]
        PAPP["Private application EC2: Nginx and NestJS"]
        PDB["Private RDS PostgreSQL"]
        PALB -->|"HTTP 80"| PAPP
        PAPP -->|"PostgreSQL 5432 with TLS"| PDB
    end

    subgraph RECOVERY["Recovery VPC: network prepared; service created on demand"]
        direction TB
        RALB["Public recovery ALB: HTTPS 443"]
        RAPP["Private recovery application EC2"]
        RDB["Private restored RDS PostgreSQL"]
        RALB -->|"HTTP 80"| RAPP
        RAPP -->|"PostgreSQL 5432 with TLS"| RDB
    end

    SNAPSHOT["Completed snapshot copy in recovery region"]
    PDB -.->|"Snapshot and cross-region copy"| SNAPSHOT
    SNAPSHOT -.->|"Restore a new database"| RDB
```

### Application request lifecycle

1. A client resolves the API hostname through DNS.
2. The client connects to the active region's ALB on HTTPS port `443`.
3. The ALB terminates TLS using a certificate provisioned in that region.
4. The ALB forwards the request to Nginx on the application instance's private address, port `80`.
5. Nginx forwards the API request locally to NestJS on port `3000`.
6. NestJS validates the request and invokes the appropriate service.
7. Prisma accesses the private RDS endpoint when data is needed.
8. The response returns through Nginx and the ALB.

Only the ALB is the public application entry point. The application instance has no public IP address. The ALB uses private addresses to reach its registered targets, and its subnets cover at least two Availability Zones. See [AWS load balancer behavior](https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/how-elastic-load-balancing-works.html).

HTTPS terminates at the ALB in the initial lab. ALB-to-Nginx and local Nginx-to-NestJS forwarding use HTTP; database connections use TLS with certificate verification.

## Networking and access

### Subnet design

Each region contains public ingress subnets, private application subnets, private monitoring subnets, and private database subnets.

| Tier | Primary CIDR examples | Recovery CIDR examples | Resources |
| --- | --- | --- | --- |
| Public, AZ A | `10.10.1.0/24` | `10.20.1.0/24` | ALB placement; optional NAT gateway placement |
| Public, AZ B | `10.10.2.0/24` | `10.20.2.0/24` | Second ALB placement |
| Private application, AZ A | `10.10.10.0/24` | `10.20.10.0/24` | Initial application EC2 |
| Private application, AZ B | `10.10.11.0/24` | `10.20.11.0/24` | Prepared capacity for a future second application instance |
| Private monitoring, AZ A | `10.10.30.0/24` | `10.20.30.0/24` | Separate Prometheus and Grafana EC2 instances |
| Private database, AZ A | `10.10.20.0/24` | `10.20.20.0/24` | RDS subnet group member |
| Private database, AZ B | `10.10.21.0/24` | `10.20.21.0/24` | Second RDS subnet group member |

Public route tables provide an internet gateway route. Application and monitoring instances use NAT for required internet downloads, or appropriate VPC endpoints for supported AWS service access. Database subnet route tables remain isolated from direct internet access.

The initial application uses one EC2 instance. Preparing subnets in two AZs does not create another instance or enable RDS Multi-AZ failover; those are separate deployment decisions.

### Security group rules

All ports below use TCP. References between security groups identify the permitted source workload.

| Destination | Port | Permitted source | Purpose |
| --- | --- | --- | --- |
| Public ALB | `443` | Intended API clients | HTTPS API access |
| Public ALB | `80`, if enabled | Intended clients | Redirect HTTP to HTTPS |
| Application Nginx | `80` | ALB security group | Forward client requests |
| Application NestJS | `3000` | Prometheus security group | Scrape application metrics |
| Application Node Exporter | `9100` | Prometheus security group | Scrape host metrics |
| Prometheus | `9090` | Grafana security group | PromQL queries |
| RDS PostgreSQL | `5432` | Application security group | Database queries and migrations |
| Grafana | `3000` | Local Systems Manager tunnel | Operator dashboard access |
| Alertmanager | `9093` | Local Prometheus process | Alert delivery on the Prometheus instance |

Nginx accesses NestJS through the same instance, so that local forwarding does not require an additional security group ingress rule. Block public `/metrics` requests in Nginx or at the public routing layer; Prometheus reaches the application's private port directly.

### Private administration

Use Systems Manager for deployment and operator access. Instances require the SSM Agent, an appropriate instance role, and connectivity to the relevant Systems Manager endpoints. VPC endpoints can provide private AWS management connectivity; access to external package repositories still requires an outbound path such as NAT. See [Systems Manager VPC endpoint setup](https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-create-vpc.html).

For example, after replacing the placeholders, tunnel the private Grafana instance to workstation port `3300`:

```bash
aws ssm start-session \
  --region us-east-1 \
  --target i-YOUR_GRAFANA_INSTANCE_ID \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["3000"],"localPortNumber":["3300"]}'
```

Open `http://localhost:3300`. This example requires AWS CLI credentials with session permissions and the Session Manager plugin on the workstation.

## API and inventory behavior

### Database models

| Model | Important fields | Purpose |
| --- | --- | --- |
| `Product` | `id`, `sku`, `name`, `description`, `quantity`, `createdAt`, `updatedAt`, `deletedAt` | Current product details and stock quantity |
| `StockMovement` | `id`, `productId`, `change`, `reason`, `createdAt` | History of stock additions and removals |

Product and movement IDs are UUIDs. `deletedAt` records archival. A unique SKU continues to identify a product even after it has been archived.

### Endpoint contract

Local base URL: `http://localhost:3000`

Deployed base URL: the API hostname configured for the regional ALB.

| Method | Endpoint | Behavior | Expected success |
| --- | --- | --- | --- |
| POST | `/products` | Create a product, optionally with opening stock | `201` |
| GET | `/products` | List active products, newest first | `200` |
| GET | `/products/:id` | Retrieve one active product | `200` |
| PATCH | `/products/:id` | Update SKU, name, or description | `200` |
| DELETE | `/products/:id` | Archive a product while retaining its history | `204`, no body |
| POST | `/products/:id/stock-adjustments` | Atomically adjust quantity and record a movement | `201` |
| GET | `/products/:id/stock-movements` | List an active product's movements, newest first | `200` |
| GET | `/health/live` | Confirm the API process responds | `200` |
| GET | `/health/ready` | Check database connectivity | `200`, or `503` when unavailable |
| GET | `/metrics` | Return Prometheus exposition text | `200` |

### Product validation

- `sku` is required, trimmed, and normalized to uppercase. It accepts letters, digits, periods, underscores, and hyphens, with an alphanumeric first character and a maximum length of 64.
- `name` is required, trimmed, nonempty, and at most 200 characters.
- `description` is optional and at most 2,000 characters. An empty string can clear a description through PATCH.
- Opening `quantity` is an optional integer from `0` to `2,147,483,647`; it defaults to zero.
- PATCH accepts descriptive fields only. All later quantity changes use the stock adjustment endpoint.
- Unexpected body fields, invalid UUIDs, invalid numeric types, and invalid supplied values return `400`.
- A valid UUID for a missing or archived product returns `404`.
- A duplicate SKU returns `409`.

### Stock consistency

A stock adjustment accepts a nonzero signed integer `change` and a nonempty `reason` of at most 300 characters. Positive changes add stock; negative changes remove it.

The service uses a conditional atomic update inside a PostgreSQL transaction. The update checks the permitted quantity range before changing the value. It then inserts the movement record and reads the updated product before committing.

The transaction preserves these application invariants:

1. Stock cannot become negative through the adjustment endpoint.
2. Quantity cannot exceed the PostgreSQL integer limit used by the model.
3. A successful adjustment records both the quantity change and its history.
4. A failed movement insertion rolls back the associated quantity change.
5. Concurrent requests do not overwrite a quantity calculated from a stale application-side read.

A product created with positive opening stock gets an `Opening stock` movement in the same atomic nested write. A zero-opening-stock product starts without a movement.

DELETE sets `deletedAt`; it does not physically delete the product or movement records. Archived products are excluded from the active API, including its movement-history route. Historical rows remain available for database auditing or a future archive-management endpoint.

## Local development

### Prerequisites

- Node.js supported by the pinned NestJS and Prisma dependencies.
- npm, Git, and a local PostgreSQL installation.
- A database created for this project, such as `cloudrecover`.
- The NestJS application source and the product, health, and metrics controllers/services.

Infrastructure work additionally requires Terraform, AWS CLI, an AWS account, and suitable deployment permissions. Local API development does not require AWS access.

### Application directory

This README assumes the NestJS backend lives in `cloudrecover-api/` beneath the repository root. Adjust that path if your application folder has another name.

```bash
cd cloudrecover-api
npm install
```

For the Prisma 7 implementation, the CLI, client, and PostgreSQL adapter must use compatible versions. The reference implementation uses `7.10.0`. Avoid installing an unqualified Prisma CLI version into this implementation, because the Prisma 8 CLI/API differs.

If these dependencies have not yet been installed:

```bash
npm install @prisma/client@7.10.0 @prisma/adapter-pg@7.10.0 pg
npm install class-validator class-transformer @nestjs/mapped-types prom-client@15.1.3 dotenv
npm install --save-dev prisma@7.10.0 @types/pg
```

See the [NestJS Prisma integration guide](https://docs.nestjs.com/data/prisma) for the generated client and driver adapter setup.

### Environment configuration

Create `cloudrecover-api/.env` from your committed `.env.example` template:

```dotenv
PORT=3000
DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@localhost:5432/cloudrecover"
```

Replace the password and database name with your local values. URL-encode reserved characters in credentials. Keep the real `.env` file out of Git and ensure the application loads it before constructing `DatabaseService`.

Prisma 7 reads the connection URL through its Prisma configuration, while the PostgreSQL adapter used by the running application also needs the connection settings. Configure both the CLI and application; setting one does not automatically configure the other.

For a standard CommonJS NestJS setup, the schema generator can be:

```prisma
generator client {
  provider     = "prisma-client"
  output       = "../src/generated/prisma"
  moduleFormat = "cjs"
}

datasource db {
  provider = "postgresql"
}
```

Keep your product and movement models below these blocks. Import the generated client from this configured output directory.

### Database schema and startup

For the first local inventory schema change:

```bash
npx prisma migrate dev --name inventory
npx prisma generate
npm run start:dev
```

When migrations are already committed, apply the existing development migrations rather than creating duplicate initial migrations. Deployed environments use `prisma migrate deploy` as part of the release workflow.

The application listens on `0.0.0.0:3000` so local clients and, later, private Prometheus scraping can reach it. Cloud security groups and Nginx control permitted access.

## API examples

The following requests demonstrate the intended contract once the application is running. IDs and timestamps in sample responses are illustrative.

### Create a product

```bash
curl -i -X POST http://localhost:3000/products \
  -H 'Content-Type: application/json' \
  -d '{
    "sku": "LAPTOP-001",
    "name": "Developer Laptop",
    "description": "Laptop for engineering work",
    "quantity": 10
  }'
```

An illustrative response is:

```json
{
  "id": "c55086e9-52f5-4ccb-92bf-8488054ce6e6",
  "sku": "LAPTOP-001",
  "name": "Developer Laptop",
  "description": "Laptop for engineering work",
  "quantity": 10,
  "createdAt": "2026-10-13T15:00:00.000Z",
  "updatedAt": "2026-10-13T15:00:00.000Z",
  "deletedAt": null
}
```

Use the actual returned ID in subsequent requests:

```bash
PRODUCT_ID="REPLACE_WITH_RETURNED_UUID"
```

### Read and update product details

```bash
curl http://localhost:3000/products
curl "http://localhost:3000/products/$PRODUCT_ID"

curl -i -X PATCH "http://localhost:3000/products/$PRODUCT_ID" \
  -H 'Content-Type: application/json' \
  -d '{"name":"Developer Laptop Pro"}'
```

### Receive and issue stock

```bash
curl -i -X POST "http://localhost:3000/products/$PRODUCT_ID/stock-adjustments" \
  -H 'Content-Type: application/json' \
  -d '{"change":5,"reason":"New stock received"}'

curl -i -X POST "http://localhost:3000/products/$PRODUCT_ID/stock-adjustments" \
  -H 'Content-Type: application/json' \
  -d '{"change":-3,"reason":"Units issued to employees"}'

curl "http://localhost:3000/products/$PRODUCT_ID/stock-movements"
```

Starting with 10 units, these adjustments produce a quantity of 12. The ledger contains the opening movement, the receipt of 5 units, and the issue of 3 units. Adjustment responses contain both `product` and `movement` objects.

An adjustment of `-13` at that point must return `400` and leave both quantity and movement count unchanged. A zero adjustment must also return `400`.

### Archive a product

```bash
curl -i -X DELETE "http://localhost:3000/products/$PRODUCT_ID"
```

A successful archival returns `204` with no body. The active product route then returns `404`, and the product disappears from the active list.

### Health and metrics

```bash
curl -i http://localhost:3000/health/live
curl -i http://localhost:3000/health/ready
curl http://localhost:3000/metrics
```

The liveness response identifies the running `cloudrecover-api` service. Readiness runs a database probe and returns `503` when it fails or times out. The reference health service bounds the response wait; driver connection and query timeouts should also be configured to limit outstanding database work.

## Monitoring and alerts

### Collection architecture

This monitoring pattern is repeated in whichever region is serving the application. Grafana and Prometheus run on separate private EC2 instances.

```mermaid
flowchart TD
    OP["Operator"] -->|"Systems Manager tunnel"| G
    G["Private Grafana EC2"] -->|"PromQL on private port 9090"| P
    P["Private Prometheus EC2"] -->|"HTTP 3000/metrics"| API
    P -->|"HTTP 9100/metrics"| NE
    P -->|"Local alert delivery: 9093"| AM

    subgraph APP["Private application EC2"]
        API["NestJS application metrics"]
        NE["Node Exporter host metrics"]
    end

    AM["Alertmanager on Prometheus EC2"]
```

Prometheus initiates scraping. Exporters respond with metrics; they do not push the measurements to Grafana. Grafana queries Prometheus's stored time series.

### Metric categories

| Source | Measurements | What they help explain |
| --- | --- | --- |
| NestJS request instrumentation | Request count, status code, route, duration histogram | Traffic distribution, server errors, API latency |
| Node.js default metrics | Process memory, CPU time, event loop and runtime measurements | Application process behavior |
| Node Exporter | Host CPU, memory, filesystem, disk, network | EC2 operating system resource pressure |
| External smoke tests | Public HTTPS, readiness, representative API operations | Whether clients can actually use the service |

Application metrics do not automatically expose every internal module or RDS's internal performance. Add dedicated instrumentation or database monitoring when those measurements are needed. A successful Prometheus scrape confirms the target responds, not that the public user path is healthy.

### Example Prometheus configuration

Replace these example private addresses with Terraform outputs or discovered instance targets:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: ["127.0.0.1:9093"]

rule_files:
  - "rules/*.yml"

scrape_configs:
  - job_name: cloudrecover-api
    metrics_path: /metrics
    static_configs:
      - targets: ["10.10.10.25:3000"]
        labels:
          environment: primary
          region: us-east-1

  - job_name: node-exporter
    metrics_path: /metrics
    static_configs:
      - targets: ["10.10.10.25:9100"]
        labels:
          environment: primary
          region: us-east-1
```

Static addresses are illustrative. Update targets when EC2 instances are replaced or use EC2 tag-based service discovery. Recovery targets and region labels must refer to the recovered instances.

Because Grafana is on a different EC2 instance, configure its Prometheus datasource as `http://PROMETHEUS_PRIVATE_IP:9090`. Prometheus must listen on an address reachable from Grafana. Grafana itself can remain accessible only through the operator's Systems Manager tunnel.

### Example dashboard queries

Requests per second by route:

```promql
sum by (route) (
  rate(http_requests_total{job="cloudrecover-api",route!~"/health/.*"}[5m])
)
```

Server error percentage, excluding health probes:

```promql
100 * (
  (sum(rate(http_requests_total{
    job="cloudrecover-api",status_code=~"5..",route!~"/health/.*"
  }[5m])) or vector(0))
  /
  clamp_min(sum(rate(http_requests_total{
    job="cloudrecover-api",route!~"/health/.*"
  }[5m])), 0.000000001)
)
```

95th percentile request duration by route, in seconds:

```promql
histogram_quantile(
  0.95,
  sum by (le, route) (
    rate(http_request_duration_seconds_bucket{
      job="cloudrecover-api",route!~"/health/.*"
    }[5m])
  )
)
```

Dashboards should also include target `up` status, process memory, host CPU, available memory, and filesystem capacity. Low traffic and insufficient histogram samples can produce sparse charts; generate repeatable test traffic before evaluating latency panels.

### Alerts

Configure and test alerts for unavailable API/exporter targets, sustained HTTP 5xx responses, and selected host resource thresholds. Tune thresholds and minimum traffic volumes to the lab; a single failed request should not automatically imply a prolonged outage.

Alertmanager runs on the Prometheus instance and uses a configured receiver. Verify both firing and resolved notifications. Prometheus stores metrics; application logs remain in the systemd journal and Nginx log files unless a separate logging platform is added.

## Infrastructure and repository organization

The following is the proposed repository layout. It includes planned infrastructure and workflow files; their presence and behavior must be verified as implementation progresses.

```text
cloudrecover/
├── README.md
├── .gitignore
├── cloudrecover-api/
│   ├── src/
│   │   ├── products/
│   │   │   ├── dto/
│   │   │   ├── products.controller.ts
│   │   │   └── products.service.ts
│   │   ├── database/
│   │   ├── health/
│   │   ├── metrics/
│   │   ├── app.module.ts
│   │   └── main.ts
│   ├── prisma/
│   │   ├── schema.prisma
│   │   └── migrations/
│   ├── test/
│   ├── prisma.config.ts
│   ├── .env.example
│   ├── package.json
│   └── package-lock.json
├── infrastructure/
│   ├── bootstrap/
│   ├── modules/
│   │   ├── networking/
│   │   ├── security/
│   │   ├── application/
│   │   ├── database/
│   │   ├── load-balancer/
│   │   └── monitoring/
│   ├── primary/
│   └── recovery/
├── configuration/
│   ├── nginx/
│   ├── systemd/
│   ├── prometheus/
│   │   └── rules/
│   ├── grafana/
│   │   ├── dashboards/
│   │   └── provisioning/
│   └── alertmanager/
├── scripts/
│   ├── deploy.sh
│   ├── backup.sh
│   ├── recover.sh
│   ├── verify-recovery.sh
│   └── smoke-test.sh
├── .github/workflows/
│   ├── ci.yml
│   ├── deploy.yml
│   ├── backup.yml
│   └── recover.yml
└── docs/
    ├── architecture/
    ├── runbooks/
    └── recovery-results/
```

`bootstrap/` manages foundational resources such as remote state and workflow access. Region-specific root modules call the reusable modules with their region, address ranges, keys, and resource settings.

Use distinct remote state keys for bootstrap, primary, and recovery. Enable state locking, restrict state access, and keep recovery state available without a primary-region dependency. IAM roles and the GitHub OIDC provider are account-level resources; create shared identity resources once and scope permissions to the appropriate regional workloads.

Commit lock files, migrations, dashboard definitions, alert rules, and configuration templates. Ignore real `.env` files, `node_modules/`, generated build output, local Terraform state, `.terraform/`, and credential-bearing files. Preserve `.env.example` with placeholders.

## Deployment pipeline

The intended GitHub Actions delivery process is:

1. Check out the selected commit and install dependencies from the lock file.
2. Run linting, application tests, compilation, secret scanning, and dependency checks.
3. Assume the deployment IAM role through GitHub OIDC.
4. Review/apply the relevant Terraform configuration.
5. Produce an immutable application release identified by commit and release version.
6. Upload the release package and checksum to a restricted, versioned S3 location.
7. Copy a recovery-compatible release package and metadata to the recovery region.
8. Use Systems Manager to download and install the release on private EC2.
9. Retrieve runtime credentials and execute committed Prisma migrations from inside the VPC.
10. Restart the systemd application service.
11. Verify local readiness, ALB target health, public HTTPS, and representative inventory requests.

Build or install dependencies for the EC2 Linux runtime and architecture. Prisma-generated code and its runtime dependencies must be present in the deployed package. A build produced on a developer workstation should not be assumed to contain suitable native dependencies for the target server.

Store runtime secrets in Secrets Manager and allow the instance role to read only the required secret. Startup logic must explicitly load the secret. Use a restricted application database user; keep schema migration privileges separate where practical. Configure PostgreSQL TLS with the AWS RDS CA and certificate verification.

Record the deployed release and schema/migration state with backup metadata. Restoring an older database and immediately deploying the newest application can create compatibility problems. Application rollback and database schema recovery require separate decisions.

Systemd starts the service after reboot and restarts failed processes. Nginx and the ALB use health checks to expose only a ready backend. An ALB does not itself launch replacement EC2 instances; an Auto Scaling Group is a future enhancement.

## Backup and recovery

### Recovery strategy

CloudRecover starts with backup and restore. The recovery service is assembled from prepared networking, copied database snapshots, and stored application dependencies. Snapshot copies are discrete recovery points; this design does not continuously replicate every database write.

The recovery workflow is manually triggered. The steps inside it are automated, while traffic cutover occurs only after validation. Merely deploying an ALB or configuring a second region does not establish a complete recovery workflow.

### Backup workflow

The planned backup workflow:

1. Records the source database and compatible application release.
2. Creates a uniquely named RDS snapshot.
3. Waits for the source snapshot to become available.
4. Requests a copy in the recovery region.
5. Uses an appropriate destination-region KMS key for an encrypted copy.
6. Waits for the destination copy to become available.
7. Records the source recovery point, copy completion, snapshot ARN, release identifier, and schema version.
8. Applies the project's backup retention policy.

A copy that is still pending or failed is not an available recovery point. The destination must support the required PostgreSQL engine version. See [RDS snapshot copying](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_CopySnapshot.html).

Choose a backup schedule from the RPO objective. A daily schedule alone does not guarantee a 24-hour recoverable data window: failed runs and copy delays can leave an older completed snapshot. Monitor the age of the latest usable destination backup and verify it through restoration.

### Recovery dependencies

Prepare the following independently of the primary region:

- Destination VPC, subnet layout, route design, and security group configuration.
- Completed encrypted snapshot copies and permission to use their KMS key.
- A compatible PostgreSQL engine version and database settings.
- Versioned application packages, checksums, and migration/release metadata.
- Regional secrets, IAM permissions, and configuration required at startup.
- A certificate for the API hostname in the recovery ALB's region.
- Terraform state, recovery scripts, dashboard definitions, and operator access.

Snapshot copying uses the RDS service APIs. The API in each region connects to its local regional database; application-to-database connectivity does not depend on a cross-region VPC peering connection.

### Recovery workflow

Suggested workflow inputs are `snapshot_arn`, `release_id`, and `cutover_enabled`. Resolve explicit versions rather than relying on an unverified `latest` label.

The workflow should:

1. Validate the selected completed backup, release, region, and required permissions.
2. Provision recovery egress, private EC2, monitoring, and the public ALB.
3. Restore a new private RDS instance from the copied snapshot.
4. Apply the intended database security groups, subnet group, and parameter settings.
5. Discover the restored database endpoint and prepare the recovered application's connection settings.
6. Deploy the selected application release and start its services.
7. Execute only schema changes appropriate to that recovered release.
8. Validate readiness, ALB health, TLS, inventory records, and stock consistency.
9. Update monitoring targets and verify telemetry from the recovery region.
10. If cutover is enabled and checks pass, update Route 53 to select the recovery ALB.
11. Confirm API requests through the normal hostname and record recovery results.

Serialize operations affecting the same regional state or database. A failed check must stop the cutover step. Record partial resources so cleanup or a retry can be performed deliberately.

### Traffic cutover and return to primary

During the lab exercise, stop the primary application before cutover and keep it stopped. This prevents two independent databases from accepting inventory writes while clients refresh DNS.

Validate traffic through the normal hostname after the DNS change; cached DNS and existing connections affect when clients reach the new service. Include this interval in client-visible recovery measurements.

Once new writes have occurred in recovery, returning traffic to the old primary requires synchronizing the current data and revalidating the application. Changing DNS back without that step can lose the recovered region's newer transactions. A repeatable failback process is a later enhancement.

## Recovery exercise

The drill uses a controlled application outage and checks that recovery can proceed without depending on primary-region release storage, secrets, or database access.

1. Create a known batch of products and stock adjustments, then save their IDs and expected quantities as a test fixture.
2. Create and copy a database snapshot. Wait for the destination copy to complete.
3. Create a second batch of products or movements after that snapshot.
4. Record the outage start time and stop the primary application service.
5. Confirm the outage using the public API path and monitoring.
6. Trigger recovery with the completed destination snapshot and compatible application release.
7. Compare recovered products and movements against the first fixture.
8. Identify which post-backup writes are absent and quantify the lost records and time window.
9. Confirm that the recovered API can accept a new stock adjustment without violating quantity/history consistency.
10. Perform DNS cutover after verification, then retest through the normal hostname.
11. Record the client-visible service restoration time, pipeline duration, and any manual interventions.
12. Keep the original application stopped until a planned return or cleanup.

A successful infrastructure apply is only one checkpoint. The demonstration is complete when clients can use the recovered API and the restored data has been checked. AWS recommends [periodic recovery testing](https://docs.aws.amazon.com/wellarchitected/latest/framework/rel_backing_up_data_periodic_recovery_testing_data.html) to assess backup integrity and recovery objectives.

## Recovery objectives and results

**RTO — Recovery Time Objective:** the target maximum downtime for restoring usable service.

**RPO — Recovery Point Objective:** the target maximum tolerable data-loss window, measured in time.

Set both objectives before the drill. Measure observed recovery time from outage detection/start, using the explicitly chosen start definition, until verified client access. Measure observed data loss using known writes and the restored recovery point. Snapshot age is useful supporting evidence but does not replace checking the recovered records.

| Measurement | Objective or actual result |
| --- | --- |
| Target RTO | To be defined |
| Target RPO | To be defined |
| Outage start / detection definition | To be defined |
| Actual client-visible recovery time | Not measured |
| Recovery workflow duration | Not measured |
| Selected snapshot and source recovery point | Not recorded |
| Destination copy completion time | Not recorded |
| Observed data-loss window | Not measured |
| Verified surviving records and quantities | Not recorded |
| Missing post-backup records | Not recorded |
| Manual interventions | Not recorded |
| RTO / RPO objectives met | Not evaluated |

Store timestamped results, workflow run identifiers, fixture checks, and redacted monitoring screenshots under `docs/recovery-results/` when available.

## Verification checklist

These are acceptance criteria, not claims of completed testing.

### Application

- [ ] Product CRUD works with expected response codes.
- [ ] Duplicate SKUs return `409`; invalid requests and UUIDs return `400`.
- [ ] Valid missing UUIDs return `404`.
- [ ] Opening stock and later adjustments produce the expected movement history.
- [ ] Insufficient-stock adjustments leave quantity and history unchanged.
- [ ] Concurrent adjustments preserve nonnegative stock and matching history.
- [ ] Archived products disappear from the active API while historical rows remain.
- [ ] Product data survives an application restart.
- [ ] Readiness returns `503` when the database is unavailable.

### Infrastructure and delivery

- [ ] Both regional VPCs and subnet tiers match the documented layout.
- [ ] Application and monitoring instances have no public IP addresses.
- [ ] RDS is private and accepts database access only from the intended workload.
- [ ] Public HTTPS works and public metrics access is blocked.
- [ ] Workflow AWS access uses OIDC rather than committed access keys.
- [ ] A versioned release deploys through Systems Manager and passes smoke tests.
- [ ] Systemd restores application operation after an EC2 reboot.
- [ ] Terraform state is separated, locked, and accessible for recovery.

### Monitoring and recovery

- [ ] Prometheus scrapes application and Node Exporter targets privately.
- [ ] Grafana queries the separate Prometheus instance and displays test traffic.
- [ ] Alerts fire and resolve in a controlled failure exercise.
- [ ] A completed destination snapshot can be restored successfully.
- [ ] Recovery uses destination-region releases, credentials, and configuration.
- [ ] Recovered product quantities and movement records match the fixture.
- [ ] Cutover runs only after the recovered application passes verification.
- [ ] Actual recovery time and data loss are recorded against the objectives.

## Seven-day roadmap

| Day | Focus | Deliverable |
| --- | --- | --- |
| 1 | Architecture and API foundation | Regional design, product models, validated product endpoints |
| 2 | Inventory consistency and application checks | Transactional adjustments, movement history, tests, health and metrics |
| 3 | Dedicated networking | Reusable Terraform module and both regional VPC layouts |
| 4 | Primary deployment and monitoring | Private application/database/monitoring, public ALB, CI/CD deployment |
| 5 | Recovery preparation | Scheduled backups, destination copies, releases, secrets, and configuration |
| 6 | Recovery automation | Snapshot restoration, service provisioning, deployment, and verification workflow |
| 7 | Exercise and evidence | Outage drill, DNS cutover, measured results, documentation, and demonstration |

This is a focused implementation target. Complete deployment and a verified restore before expanding the scope to fully automatic failover or additional availability features.

## Troubleshooting

| Symptom | Checks |
| --- | --- |
| Prisma generated client import fails | Verify pinned versions, generator output, module format, and `prisma generate` |
| NestJS cannot inject `DatabaseService` | Export it from `DatabaseModule` and import that module where the dependent providers are registered |
| Local database connection fails | Check PostgreSQL service, database name, credentials, URL encoding, port, and environment loading |
| ALB target is unhealthy | Check target registration, port `80`, Nginx, the application process, readiness, and ALB-to-application SG rules |
| EC2 cannot connect to RDS | Check the restored/current endpoint, RDS SG source, VPC routing, database credentials, TLS configuration, and database name |
| Prometheus target is down | Check its private target address, listener interface, port, SG source, exporter service, and configured metrics path |
| Grafana datasource fails | Use the Prometheus private address rather than Grafana's localhost; check port `9090` access and Prometheus listening address |
| Systems Manager instance is offline | Check SSM Agent, instance role, regional endpoint reachability, DNS, and NAT or VPC endpoint configuration |
| Snapshot copy or restore fails | Check completed source/copy state, region and engine compatibility, KMS access, and restore settings |
| Recovered API uses old data unexpectedly | Confirm selected snapshot, source recovery point, release metadata, and actual application database endpoint |
| DNS points to recovery but requests still fail | Check certificate coverage, ALB target health, public-path smoke tests, DNS caching, and existing connections |

## Resource cleanup and cost management

EC2, RDS, ALBs, NAT gateways, storage, snapshot copies, encryption keys, and data transfer can generate charges. Review the chosen resource sizes and current AWS pricing before provisioning.

Tag resources with project, region role, environment, and owner. Configure a budget alert. Create recovery service resources only when needed for the backup-and-restore exercise, and retain monitoring data only for the intended period.

Stopping EC2 does not remove other resources. Cleanup should explicitly consider ALBs, NAT gateways, RDS instances, attached/unattached EBS volumes, retained snapshots, release objects, and log storage according to the project's retention policy.

Before destroying a tested environment, preserve the required recovery evidence and verify that the backup/release resources intended for retention are outside that destruction target. Review each regional Terraform destroy plan and keep state, shared identity resources, and retained recovery dependencies separate from disposable stacks.

## Scope and future improvements

The initial design demonstrates regional backup restoration with one application instance and a Single-AZ RDS deployment unless configured otherwise. Monitoring instances are also single-instance services. The public ALB's multi-AZ placement does not make those individual components highly available.

Authentication and authorization are outside the initial API contract. Use synthetic lab inventory data until access controls are implemented. Stock adjustment requests currently represent individual transactions; idempotency keys are a future improvement for safe client retries.

Further work can include:

- A second application instance with an Auto Scaling Group across AZs.
- RDS Multi-AZ availability and tested maintenance/failover behavior.
- A pilot-light or warm-standby strategy with a measured cost/recovery comparison.
- Automated recovery-point freshness checks and periodic restore exercises.
- Controlled automatic traffic failover after the recovery service is ready.
- Write fencing and a tested data-synchronization/failback workflow.
- Idempotency keys, bounded pagination, and archive-management endpoints.
- Authentication, authorization, structured audit logging, and API rate limits.
- External HTTPS probes and a dedicated application logging platform.
- Cross-account recovery isolation and more formal backup retention controls.

## References

- [NestJS Prisma integration](https://docs.nestjs.com/data/prisma)
- [Prisma 7 transactions](https://www.prisma.io/docs/orm/v7/prisma-client/queries/transactions)
- [AWS load balancer behavior](https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/how-elastic-load-balancing-works.html)
- [RDS snapshot copying](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_CopySnapshot.html)
- [Systems Manager VPC endpoint setup](https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-create-vpc.html)
- [AWS disaster recovery strategies](https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-options-in-the-cloud.html)
- [AWS recovery testing guidance](https://docs.aws.amazon.com/wellarchitected/latest/framework/rel_backing_up_data_periodic_recovery_testing_data.html)
- [Prometheus Node Exporter guide](https://prometheus.io/docs/guides/node-exporter/)
- [Grafana support for Prometheus](https://prometheus.io/docs/visualization/grafana/)
