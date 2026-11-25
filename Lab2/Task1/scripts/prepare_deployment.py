"""Validate deployment settings and render non-secret partial backend configuration."""

import argparse
import ipaddress
import json
import os
from pathlib import Path
import re
import sys

TASK_ROOT = Path(__file__).resolve().parents[1]
DEFAULTS = {"AWS_REGION": "us-east-1", "AWS_AUTH_MODE": "session",
            "TF_AVAILABILITY_ZONE": "us-east-1a", "TF_STATE_REGION": "us-east-1",
            "TF_STATE_KEY": "lab2/task1/dev/terraform.tfstate"}


def validate_environment(environment):
    values = {**DEFAULTS, **{k: v.strip() for k, v in environment.items() if v}}
    required = ["AWS_ACCOUNT_ID", "TF_ALLOWED_SSH_CIDR", "TF_STATE_BUCKET", "TF_STATE_STRATEGY"]
    missing = [name for name in required if not values.get(name)]
    if missing:
        raise ValueError("Missing settings: " + ", ".join(missing))
    if values.get("TF_DEPLOYMENT_READY") != "true":
        raise ValueError("TF_DEPLOYMENT_READY must be explicitly enabled after state/auth review")
    if not re.fullmatch(r"\d{12}", values["AWS_ACCOUNT_ID"]):
        raise ValueError("AWS_ACCOUNT_ID must contain 12 digits")
    if values["AWS_AUTH_MODE"] not in {"session", "oidc"}:
        raise ValueError("AWS_AUTH_MODE must be session or oidc")
    if values["AWS_AUTH_MODE"] == "session":
        if not all(values.get(k) for k in ("AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN")):
            raise ValueError("Session mode requires all three AWS credential Secrets")
    else:
        account = values["AWS_ACCOUNT_ID"]
        if not re.fullmatch(rf"arn:aws:iam::{account}:role/[A-Za-z0-9+=,.@_/-]+", values.get("AWS_ROLE_ARN", "")):
            raise ValueError("AWS_ROLE_ARN must identify a role in AWS_ACCOUNT_ID")
    try:
        network = ipaddress.ip_network(values["TF_ALLOWED_SSH_CIDR"], strict=True)
    except ValueError as exc:
        raise ValueError("TF_ALLOWED_SSH_CIDR must be a valid IPv4 /32") from exc
    if network.version != 4 or network.prefixlen != 32:
        raise ValueError("TF_ALLOWED_SSH_CIDR must identify one IPv4 address (/32)")
    if not re.fullmatch(re.escape(values["AWS_REGION"]) + r"[a-z]", values["TF_AVAILABILITY_ZONE"]):
        raise ValueError("TF_AVAILABILITY_ZONE must belong to AWS_REGION")
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]{1,61}[a-z0-9]", values["TF_STATE_BUCKET"]):
        raise ValueError("TF_STATE_BUCKET must be a valid lowercase bucket name (hyphens allowed)")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9/_.-]*\.tfstate", values["TF_STATE_KEY"]):
        raise ValueError("TF_STATE_KEY must identify a .tfstate object")
    if values["TF_STATE_STRATEGY"] not in {"existing", "new"}:
        raise ValueError("TF_STATE_STRATEGY must explicitly be existing or new")
    return values


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check-only", action="store_true")
    args = parser.parse_args()
    try:
        values = validate_environment(os.environ)
        if not args.check_only:
            target = TASK_ROOT / "terraform/environments/dev/backend.hcl"
            content = "\n".join(f"{key} = {json.dumps(values[name])}" for key, name in
                                [("bucket", "TF_STATE_BUCKET"), ("key", "TF_STATE_KEY"), ("region", "TF_STATE_REGION")])
            target.write_text(content + "\n", encoding="utf-8")
        print("Deployment inputs validated; no credentials printed or written to backend.hcl.")
    except (ValueError, OSError) as exc:
        print(f"Deployment preparation failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
