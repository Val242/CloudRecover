import type { SNSEvent, SNSHandler } from "aws-lambda";
import {
  SecretsManagerClient,
  GetSecretValueCommand,
} from "@aws-sdk/client-secrets-manager";

const secretsManager = new SecretsManagerClient({});

const EXPECTED_ALARM =
  "cloudrecover-primary-health-alarm";

const GITHUB_API = "https://api.github.com";

interface CloudWatchAlarmMessage {
  AlarmName: string;
  NewStateValue: string;
  NewStateReason?: string;
  Region?: string;
  StateChangeTime?: string;
}

const getGitHubToken = async (): Promise<string> => {
  const secretArn = process.env.GITHUB_SECRET_ARN;

  if (!secretArn) {
    throw new Error("GITHUB_SECRET_ARN is not configured");
  }

  const response = await secretsManager.send(
    new GetSecretValueCommand({
      SecretId: secretArn,
    })
  );

  if (!response.SecretString) {
    throw new Error("GitHub secret is empty");
  }

  return response.SecretString;
};

const dispatchRecoveryWorkflow = async (
  message: CloudWatchAlarmMessage
): Promise<void> => {
  const owner = process.env.GITHUB_OWNER;
  const repo = process.env.GITHUB_REPOSITORY;
  const workflow = process.env.GITHUB_WORKFLOW;
  const branch = process.env.GITHUB_REF || "main";

  if (!owner || !repo || !workflow) {
    throw new Error("GitHub configuration is incomplete");
  }

  const token = await getGitHubToken();

  const response = await fetch(
    `${GITHUB_API}/repos/${owner}/${repo}/actions/workflows/${workflow}/dispatches`,
    {
      method: "POST",
      headers: {
        Accept: "application/vnd.github+json",
        Authorization: `Bearer ${token}`,
        "X-GitHub-Api-Version": "2022-11-28",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        ref: branch,
        inputs: {
          trigger_source: "cloudwatch_alarm",
          alarm_name: message.AlarmName,
          source_region: message.Region || "eu-west-1",
          recovery_region: "eu-west-2",
        },
      }),
    }
  );

  if (!response.ok) {
    const error = await response.text();

    throw new Error(
      `GitHub workflow dispatch failed: ${response.status} ${error}`
    );
  }

  console.log("Recovery workflow successfully dispatched", {
    alarmName: message.AlarmName,
    workflow,
    branch,
  });
};

export const handler: SNSHandler = async (
  event: SNSEvent
): Promise<void> => {
  for (const record of event.Records) {
    const rawMessage = record.Sns.Message;

    let alarm: CloudWatchAlarmMessage;

    try {
      alarm = JSON.parse(rawMessage);
    } catch {
      throw new Error("Invalid CloudWatch alarm notification");
    }

    console.log("Received CloudWatch notification", {
      alarmName: alarm.AlarmName,
      state: alarm.NewStateValue,
    });

    if (alarm.AlarmName !== EXPECTED_ALARM) {
      console.log("Ignoring unrelated alarm");
      continue;
    }

    if (alarm.NewStateValue !== "ALARM") {
      console.log("Primary alarm is not in ALARM state");
      continue;
    }

    await dispatchRecoveryWorkflow(alarm);
  }
};
