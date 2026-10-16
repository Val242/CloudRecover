# CloudRecover — Multi-Region AWS Disaster Recovery Platform

## Project Goal

Build a disaster recovery platform that deploys, monitors, backs up, and restores a NestJS inventory API across two AWS Regions. The primary environment serves normal traffic, while the recovery environment can be provisioned and activated when required.

**Technology stack**

- Backend: NestJS, TypeScript
- Database: PostgreSQL on Amazon RDS
- Infrastructure as Code: Terraform
- Cloud: AWS VPC, EC2, ALB, RDS, IAM, S3, Systems Manager
- CI/CD: GitHub Actions with AWS OIDC federation
- Deployment: SSM and systemd
- Monitoring: Prometheus, Grafana, Node Exporter
- Recovery: Cross-region RDS snapshot copies and automated recovery workflows

## Phase 1 — Backend API Foundation

- [x] Initialize the NestJS inventory API.
- [x] Integrate PostgreSQL using Prisma.
- [x] Implement product CRUD operations.
- [x] Implement health endpoints.
- [x] Implement application metrics.
- [x] Verify the API endpoints.

## Phase 2 — Inventory Reliability

- [x] Implement stock adjustment operations.
- [x] Prevent negative inventory quantities.
- [x] Use atomic database transactions for stock updates and movement records.
- [x] Implement stock movement history.
- [x] Add automated unit and integration tests.
- [x] Verify concurrency and failure handling.

Note: Stock adjustment logic, movement history, and automated tests remain deferred. Health checks and metrics are already implemented.

## Phase 3 — Primary AWS Infrastructure

- [ ] Finalize the primary-region architecture.
- [ ] Define the VPC CIDR and subnet allocation.
- [ ] Select Availability Zones and distribute subnets appropriately.
- [ ] Configure public and private route tables.
- [ ] Configure the Internet Gateway and NAT Gateway.
- [ ] Configure the bastion host and restricted administrative access.
- [ ] Configure security groups and IAM permissions.
- [ ] Provision the internal Application Load Balancer.
- [ ] Provision the application EC2 instance.
- [ ] Provision private RDS PostgreSQL.
- [ ] Validate network connectivity and security boundaries.

## Phase 4 — Application Deployment

- [ ] Configure the Ubuntu application server.
- [ ] Install Node.js and required system dependencies.
- [ ] Configure the application system user and directories.
- [ ] Configure application environment variables and database connectivity.
- [ ] Configure the systemd service.
- [ ] Deploy the NestJS API.
- [ ] Configure the ALB target group and health checks.
- [ ] Verify application readiness and database connectivity.

## Phase 5 — Monitoring and Observability

- [ ] Provision the monitoring infrastructure.
- [ ] Install Node Exporter on the application server.
- [ ] Install and configure Prometheus.
- [ ] Scrape application metrics and host metrics.
- [ ] Install and configure Grafana.
- [ ] Build application and infrastructure dashboards.
- [ ] Configure alerting and notifications.
- [ ] Test monitoring connectivity and alert delivery.

## Phase 6 — CI/CD Automation

- [ ] Create the GitHub Actions workflow.
- [ ] Add dependency installation, linting, testing, and build checks.
- [ ] Add secret scanning and dependency auditing.
- [ ] Package versioned application artifacts.
- [ ] Configure S3 artifact storage.
- [ ] Configure GitHub OIDC federation with AWS IAM.
- [ ] Deploy through Systems Manager.
- [ ] Run database migrations safely.
- [ ] Restart the application service and verify health.
- [ ] Test deployment failures and recovery.

## Phase 7 — Cross-Region Backup and Recovery Preparation

- [ ] Select the primary and recovery AWS Regions.
- [ ] Design separate VPCs and non-overlapping CIDR ranges.
- [ ] Configure Terraform root configurations for both Regions.
- [ ] Use reusable Terraform modules for networking, security, application, database, load balancing, and monitoring.
- [ ] Maintain separate Terraform states for primary and recovery infrastructure.
- [ ] Configure RDS snapshots and cross-region snapshot copies.
- [ ] Configure encryption and KMS permissions for snapshot copying and restoration.
- [ ] Define recovery-region configuration and secrets handling.
- [ ] Document recovery prerequisites and resource dependencies.

## Phase 8 — Automated Recovery Workflow

- [ ] Create a controlled GitHub Actions recovery workflow.
- [ ] Select an available recovery snapshot.
- [ ] Provision the required recovery infrastructure.
- [ ] Restore the database from the selected snapshot.
- [ ] Deploy the compatible application release.
- [ ] Configure the application to use the restored database.
- [ ] Validate application health and restored inventory data.
- [ ] Return clear recovery success or failure results.
- [ ] Handle partial failures and safe retries.

## Phase 9 — Traffic Switching and Disaster Simulation

- [ ] Define the traffic-switching strategy.
- [ ] Simulate a primary-region outage.
- [ ] Run the recovery workflow.
- [ ] Verify the restored database and application.
- [ ] Switch DNS or the appropriate traffic-routing mechanism after validation.
- [ ] Measure recovery time and potential data loss.
- [ ] Document the recovery procedure and rollback considerations.

## Phase 10 — Security, Reliability, and Cost Validation

- [ ] Review IAM permissions for least privilege.
- [ ] Validate security-group and subnet isolation.
- [ ] Test application and database failure scenarios.
- [ ] Test recovery workflow failure handling.
- [ ] Verify snapshot encryption and access controls.
- [ ] Review AWS resource costs.
- [ ] Ensure recovery resources can be safely deprovisioned when no longer needed.
- [ ] Verify that protected primary resources cannot be accidentally destroyed by recovery automation.

## Phase 11 — Documentation and Portfolio

- [ ] Document the architecture and traffic paths.
- [ ] Add infrastructure and recovery diagrams.
- [ ] Document Terraform usage and state management.
- [ ] Document CI/CD and OIDC authentication.
- [ ] Document monitoring dashboards and alerts.
- [ ] Write the disaster recovery runbook.
- [ ] Record recovery timings and test results.
- [ ] Add screenshots and a project demonstration.
- [ ] Update the GitHub README and portfolio.

## Definition of Done

CloudRecover is complete when the primary environment can serve the inventory API, monitor application and infrastructure health, and create recoverable database backups in another AWS Region.

When recovery is triggered, the platform should be able to provision the necessary infrastructure, restore the database, deploy the application, validate service health, and switch traffic only after successful checks.

The workflow should be repeatable, secured through least-privilege permissions, observable, and documented.
