# CloudRecover Recovery Trigger Lambda

## Overview

The CloudRecover Recovery Trigger is an AWS Lambda function responsible for initiating the disaster recovery workflow when the primary application environment becomes unhealthy.

It acts as the communication bridge between AWS monitoring services and GitHub Actions.

When the primary CloudWatch health alarm enters the `ALARM` state, Amazon SNS delivers a notification to this Lambda function. The function validates the notification and dispatches the GitHub Actions disaster recovery workflow.

## Architecture

The Lambda participates in the following event-driven architecture:

```text
Route 53 Health Check
        |
        v
CloudWatch Metric Alarm
        |
        v
Amazon SNS Topic
        |
        v
AWS Lambda
        |
        v
GitHub Actions Workflow
        |
        v
Recovery Infrastructure
     eu-west-2
```

**AWS Region:** `us-east-1`

The Lambda is deployed in the same region as the SNS notification topic.

## Responsibilities

The function is responsible for:

1. Receiving CloudWatch alarm notifications through SNS.
2. Parsing and validating incoming alarm messages.
3. Identifying the expected primary health alarm.
4. Ignoring notifications that do not indicate an active alarm.
5. Retrieving the GitHub authentication token from AWS Secrets Manager.
6. Dispatching the GitHub Actions disaster recovery workflow through the GitHub REST API.
7. Logging workflow dispatch results and errors.

## Project Structure

```text
recovery-trigger/
│
├── src/
│   └── handler.ts
│
├── package.json
├── package-lock.json
├── tsconfig.json
├── .env.example
├── .gitignore
└── README.md
```

## Technology Stack

- AWS Lambda
- Node.js 22
- TypeScript
- Amazon SNS
- AWS Secrets Manager
- GitHub REST API
- GitHub Actions

## Environment Configuration

The function uses environment variables to configure its GitHub repository and Secrets Manager integration.

| Variable | Description |
|---|---|
| `GITHUB_OWNER` | GitHub username or organization |
| `GITHUB_REPOSITORY` | Repository containing the recovery workflow |
| `GITHUB_WORKFLOW` | GitHub Actions workflow filename or ID |
| `GITHUB_REF` | Branch used to dispatch the workflow |
| `GITHUB_SECRET_ARN` | ARN of the Secrets Manager secret containing the GitHub token |

Example `.env.example`:

```env
GITHUB_OWNER=
GITHUB_REPOSITORY=
GITHUB_WORKFLOW=disaster-recovery.yml
GITHUB_REF=main
GITHUB_SECRET_ARN=
```

The actual `.env` file must not be committed to version control.

The GitHub authentication token is stored in AWS Secrets Manager. The Lambda execution role will receive permission to retrieve the secret.

## Dependencies

The function uses the following packages:

- `@aws-sdk/client-secrets-manager`
- `@types/aws-lambda`
- `typescript`

Install the dependencies using:

```bash
npm install @aws-sdk/client-secrets-manager
npm install --save-dev @types/aws-lambda typescript
```

## GitHub Actions Integration

The function communicates with GitHub using the workflow dispatch REST API:

```text
POST /repos/{owner}/{repo}/actions/workflows/{workflow_id}/dispatches
```

The workflow receives the following inputs:

| Input | Value |
|---|---|
| `trigger_source` | `cloudwatch_alarm` |
| `alarm_name` | Primary CloudWatch alarm name |
| `source_region` | `eu-west-1` |
| `recovery_region` | `eu-west-2` |

The GitHub Actions workflow must support the `workflow_dispatch` event and define the corresponding inputs.

A successful dispatch response means GitHub accepted the workflow request. It does not mean that disaster recovery has completed successfully.

## Security Considerations

- GitHub credentials must never be hardcoded in the source code.
- GitHub tokens must be stored in AWS Secrets Manager.
- Lambda permissions should follow the principle of least privilege.
- The execution role should only access the required secret and logging resources.
- Sensitive credentials must not be written to CloudWatch logs.
- Production configuration must be managed through AWS infrastructure configuration rather than committed environment files.

## Current Scope and Limitations

The initial implementation handles SNS notification processing and GitHub Actions workflow dispatch.

The following capabilities are planned separately:

- DynamoDB-based recovery execution locking.
- Duplicate notification protection and idempotency.
- Failure recovery and controlled dispatch retries.
- End-to-end disaster recovery testing.
- Recovery infrastructure provisioning and database restoration.
- Application readiness validation.
- Route 53 DNS failover.

The Lambda does not directly provision infrastructure, restore RDS snapshots, deploy the application, or modify DNS records. These responsibilities belong to the GitHub Actions disaster recovery workflow.

## Recovery Workflow

The intended recovery process is:

1. Detect primary application failure.
2. Trigger the Lambda through SNS.
3. Dispatch the GitHub Actions recovery workflow.
4. Provision recovery infrastructure in `eu-west-2`.
5. Restore the latest usable RDS snapshot.
6. Deploy the application.
7. Validate application and database readiness.
8. Activate recovery DNS only after successful validation.

## Project

**CloudRecover** is a multi-region AWS disaster recovery platform designed to automate infrastructure recovery and application failover using Terraform, AWS services, and GitHub Actions.
