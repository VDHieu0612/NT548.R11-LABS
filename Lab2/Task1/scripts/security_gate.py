"""Run pinned Checkov; fail on findings, tool errors, parsing errors or lost coverage."""

import argparse
from importlib.metadata import version
import json
import os
from pathlib import Path
import subprocess
import sys

TASK_ROOT = Path(__file__).resolve().parents[1]
REQUIRED = {
    # NAT/routing resources count toward resource_count, but have no standalone
    # Checkov checks. Require checks for the security-relevant VPC/SG/EC2 objects.
    "workload": (15, {"aws_vpc.main",
                       "aws_security_group.public_ec2_sg", "aws_security_group.private_ec2_sg",
                       "aws_instance.public_ec2", "aws_instance.private_ec2"}),
    "bootstrap": (7, {"aws_s3_bucket.state", "aws_s3_bucket_public_access_block.state"}),
}


def matches(actual, expected):
    return actual == expected or actual.endswith("." + expected)


def validate_report(report, label, exceptions, exit_code):
    reports = report if isinstance(report, list) else [report]
    terraform = [r for r in reports if isinstance(r, dict) and r.get("check_type") == "terraform"]
    if len(terraform) != 1:
        raise ValueError("Expected exactly one Terraform report")
    data = terraform[0]
    summary = data.get("summary", {})
    results = data.get("results", {})
    if exit_code != 0 or summary.get("failed", 0) or results.get("failed_checks"):
        raise ValueError(f"{label}: Checkov failed (exit={exit_code}, findings={summary.get('failed')})")
    if summary.get("parsing_errors", 0) or results.get("parsing_errors"):
        raise ValueError(f"{label}: Terraform parsing errors")
    minimum, required = REQUIRED[label]
    if summary.get("resource_count", 0) < minimum:
        raise ValueError(f"{label}: insufficient resource coverage")
    checks = sum((results.get(k, []) for k in ("passed_checks", "failed_checks", "skipped_checks")), [])
    seen = {c.get("resource", "") for c in checks}
    if any(not any(matches(actual, expected) for actual in seen) for expected in required):
        raise ValueError(f"{label}: a required module/resource is absent from the scan")
    for check in results.get("skipped_checks", []):
        comment = str(check.get("check_result", {}).get("suppress_comment", ""))
        allowed = [e for e in exceptions if e["check_id"] == check.get("check_id")
                   and matches(check.get("resource", ""), e["resource"])
                   and e["id"] in comment and e.get("reason") and e.get("mitigation")]
        if not allowed:
            raise ValueError(f"Unregistered suppression: {check.get('check_id')} {check.get('resource')}")
    return summary


def scan(task_root, label):
    expected_version = (task_root / "requirements-checkov.txt").read_text(encoding="utf-8").strip().split("==")[1]
    if version("checkov") != expected_version:
        raise ValueError("Installed Checkov does not match requirements-checkov.txt")
    directory = task_root / ("terraform" if label == "workload" else "bootstrap")
    artifacts = task_root / ".artifacts"
    artifacts.mkdir(parents=True, exist_ok=True)
    report_path = artifacts / f"checkov-{label}.json"
    error_path = artifacts / f"checkov-{label}.stderr"
    command = [sys.executable, "-X", "utf8", "-m", "checkov.main", "--config-file", str(task_root / ".checkov.yaml"),
               "--directory", str(directory), "--var-file", str(task_root / "config/checkov.tfvars.example"),
               "--output", "json"]
    env = os.environ.copy()
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    env["PYTHONUTF8"] = "1"
    # A parent environment must not silently weaken the gate or request remote enforcement.
    for key in list(env):
        if key.startswith(("CKV_", "BC_", "PRISMA_", "CHECKOV_")):
            env.pop(key)
    with report_path.open("w", encoding="utf-8") as out, error_path.open("w", encoding="utf-8") as err:
        result = subprocess.run(command, cwd=task_root, env=env, stdout=out, stderr=err, timeout=300)
    report = json.loads(report_path.read_text(encoding="utf-8"))
    exceptions = json.loads((task_root / "security-exceptions.json").read_text(encoding="utf-8"))
    summary = validate_report(report, label, exceptions, result.returncode)
    print(f"{label}: {summary}")
    return summary


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--task-root", type=Path, default=TASK_ROOT)
    parser.add_argument("--only", choices=["workload", "bootstrap"])
    args = parser.parse_args()
    try:
        for label in ([args.only] if args.only else ["workload", "bootstrap"]):
            scan(args.task_root.resolve(), label)
    except (ValueError, KeyError, OSError, subprocess.SubprocessError) as exc:
        print(f"SECURITY GATE FAILED: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
