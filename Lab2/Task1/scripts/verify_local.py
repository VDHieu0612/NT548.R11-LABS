"""CI without AWS credentials; create a disposable source-only copy under Task1/.cache."""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

TASK_ROOT = Path(__file__).resolve().parents[1]


def run(command, cwd, env):
    print("CHECK:", " ".join(map(str, command)), flush=True)
    subprocess.run(list(map(str, command)), cwd=cwd, env=env, check=True, timeout=300)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--plugin-dir", type=Path, help="Optional existing provider mirror for offline validation")
    parser.add_argument("--terraform-only", action="store_true", help="Only fmt/validate/mock tests; no security result")
    args = parser.parse_args()
    terraform = shutil.which("terraform")
    if not terraform:
        print("Terraform executable is required", file=sys.stderr)
        return 1
    env = os.environ.copy()
    for key in list(env):
        if key.startswith(("TF_VAR_", "TF_CLI_ARGS")) or key in {
            "TF_DATA_DIR", "TF_WORKSPACE", "TF_PLUGIN_CACHE_DIR", "AWS_ACCESS_KEY_ID",
            "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN", "AWS_PROFILE", "AWS_DEFAULT_PROFILE",
            "AWS_ROLE_ARN", "AWS_WEB_IDENTITY_TOKEN_FILE", "AWS_CONTAINER_CREDENTIALS_FULL_URI",
            "AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"}:
            env.pop(key)
    env.update({"CHECKPOINT_DISABLE": "1", "TF_IN_AUTOMATION": "true", "PYTHONDONTWRITEBYTECODE": "1",
                "AWS_EC2_METADATA_DISABLED": "true"})
    cache = TASK_ROOT / ".cache"
    cache.mkdir(exist_ok=True)
    try:
        with tempfile.TemporaryDirectory(prefix="verify-", dir=cache, ignore_cleanup_errors=True) as temporary:
            scratch = Path(temporary).resolve()
            assert scratch.is_relative_to(cache.resolve())
            empty = scratch / "empty.config"
            empty.write_text("", encoding="utf-8")
            env.update({"TF_CLI_CONFIG_FILE": str(empty), "AWS_CONFIG_FILE": str(empty),
                        "AWS_SHARED_CREDENTIALS_FILE": str(empty)})
            for directory in ["terraform", "bootstrap"]:
                source = TASK_ROOT / directory
                run([terraform, "fmt", "-check", "-recursive", source], TASK_ROOT, env)
                for path in source.rglob("*"):
                    if not path.is_file() or ".terraform" in path.relative_to(source).parts:
                        continue
                    if path.suffix != ".tf" and not path.name.endswith(".tftest.hcl") and path.name not in {
                        ".terraform.lock.hcl", ".terraform-version"}:
                        continue
                    dest = scratch / directory / path.relative_to(source)
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(path, dest)
                root = scratch / directory
                if directory == "terraform":
                    root /= "environments/dev"
                init = [terraform, "init", "-backend=false", "-input=false", "-lockfile=readonly", "-no-color"]
                if args.plugin_dir:
                    init.append("-plugin-dir=" + str(args.plugin_dir.resolve()))
                run(init, root, env)
                run([terraform, "validate", "-no-color"], root, env)
                run([terraform, "test", "-no-color"], root, env)
            if not args.terraform_only:
                run([sys.executable, TASK_ROOT / "scripts/security_gate.py"], TASK_ROOT, env)
        return 0
    except (OSError, AssertionError, subprocess.SubprocessError) as exc:
        print(f"LOCAL CHECKS FAILED: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
