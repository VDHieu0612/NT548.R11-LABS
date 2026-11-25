"""Reject an empty/wrong existing state before an authenticated deployment."""

import argparse
import subprocess
import sys

EXPECTED = {
    "module.vpc.aws_vpc.main", "module.vpc.aws_internet_gateway.main",
    "module.vpc.aws_subnet.public", "module.vpc.aws_subnet.private",
    "module.vpc.aws_default_security_group.default", "module.nat.aws_eip.nat",
    "module.nat.aws_nat_gateway.main", "module.nat.aws_route_table.public",
    "module.nat.aws_route_table.private", "module.nat.aws_route_table_association.public",
    "module.nat.aws_route_table_association.private", "module.security.aws_security_group.public_ec2_sg",
    "module.security.aws_security_group.private_ec2_sg", "module.ec2.aws_instance.public_ec2",
    "module.ec2.aws_instance.private_ec2",
}


def validate_addresses(addresses, strategy):
    managed = {a for a in addresses if a and ".data." not in a and not a.startswith("data.")}
    if strategy not in {"existing", "new"}:
        raise ValueError("Choose an explicit state strategy")
    if managed == EXPECTED or (not managed and strategy == "new"):
        return len(managed)
    raise ValueError("State does not match the 15 expected workload resources; review migration/key before planning")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--strategy", choices=["existing", "new"], required=True)
    args = parser.parse_args()

    try:
        result = subprocess.run(
            ["terraform", "state", "list"],
            text=True,
            capture_output=True,
            check=False,
            timeout=120
        )

        if result.returncode != 0:
            if (
                args.strategy == "new"
                and result.returncode == 1
                and not result.stdout.strip()
                and result.stderr.strip().startswith(
                    "No state file was found!"
                )
            ):
                print("No remote state found. First deployment allowed.")
                addresses = []
            else:
                raise ValueError(
                    result.stderr.strip()
                    or f"Terraform exited with code {result.returncode}"
                )
        else:
            addresses = result.stdout.splitlines()

        count = validate_addresses(addresses, args.strategy)

        print(
            f"State identity structure checked: "
            f"{count} managed resources ({args.strategy})."
        )

    except (ValueError, OSError, subprocess.SubprocessError) as exc:
        print(f"State check failed: {exc}", file=sys.stderr)
        return 1

    return 0

if __name__ == "__main__":
    sys.exit(main())
