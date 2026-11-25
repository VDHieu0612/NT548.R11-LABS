import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from check_state import EXPECTED, validate_addresses
from prepare_deployment import validate_environment
from security_gate import REQUIRED, validate_report


class DeploymentSettingsTests(unittest.TestCase):
    def setUp(self):
        self.env = {
            "AWS_ACCOUNT_ID": "000000000000", "AWS_AUTH_MODE": "session",
            "AWS_ACCESS_KEY_ID": "test-only-id", "AWS_SECRET_ACCESS_KEY": "test-only-secret",
            "AWS_SESSION_TOKEN": "test-only-token", "TF_ALLOWED_SSH_CIDR": "192.0.2.10/32",
            "TF_STATE_BUCKET": "nt548-example-state-not-created", "TF_STATE_STRATEGY": "existing",
            "TF_DEPLOYMENT_READY": "true",
        }

    def test_complete_session_settings(self):
        self.assertEqual(validate_environment(self.env)["AWS_REGION"], "us-east-1")

    def test_empty_placeholders_rejected(self):
        with self.assertRaises(ValueError):
            validate_environment({})

    def test_readiness_must_be_explicit(self):
        self.env["TF_DEPLOYMENT_READY"] = "false"
        with self.assertRaises(ValueError):
            validate_environment(self.env)

    def test_session_token_required(self):
        self.env.pop("AWS_SESSION_TOKEN")
        with self.assertRaises(ValueError):
            validate_environment(self.env)

    def test_ssh_world_open_rejected(self):
        self.env["TF_ALLOWED_SSH_CIDR"] = "0.0.0.0/0"
        with self.assertRaises(ValueError):
            validate_environment(self.env)

    def test_ipv6_rejected(self):
        self.env["TF_ALLOWED_SSH_CIDR"] = "2001:db8::1/128"
        with self.assertRaises(ValueError):
            validate_environment(self.env)

    def test_region_zone_mismatch_rejected(self):
        self.env["AWS_REGION"] = "us-west-2"
        with self.assertRaises(ValueError):
            validate_environment(self.env)

    def test_unknown_state_strategy_rejected(self):
        self.env["TF_STATE_STRATEGY"] = ""
        with self.assertRaises(ValueError):
            validate_environment(self.env)

    def test_oidc_does_not_need_session_secrets(self):
        self.env["AWS_AUTH_MODE"] = "oidc"
        self.env["AWS_ROLE_ARN"] = "arn:aws:iam::000000000000:role/example"
        for key in ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN"]:
            self.env.pop(key)
        self.assertEqual(validate_environment(self.env)["AWS_AUTH_MODE"], "oidc")

    def test_role_in_another_account_rejected(self):
        self.env.update(AWS_AUTH_MODE="oidc", AWS_ROLE_ARN="arn:aws:iam::111111111111:role/example")
        with self.assertRaises(ValueError):
            validate_environment(self.env)


class StateGuardTests(unittest.TestCase):
    def test_existing_state_cannot_be_empty(self):
        with self.assertRaises(ValueError):
            validate_addresses([], "existing")

    def test_expected_state_accepts_data_source(self):
        self.assertEqual(validate_addresses(EXPECTED | {"module.ec2.data.aws_ami.amazon_linux_2023"}, "existing"), 15)

    def test_unrelated_resources_rejected(self):
        with self.assertRaises(ValueError):
            validate_addresses(EXPECTED | {"aws_instance.unrelated"}, "existing")

    def test_explicit_new_environment_can_start_empty(self):
        self.assertEqual(validate_addresses([], "new"), 0)

    def test_new_environment_can_be_updated_after_first_apply(self):
        self.assertEqual(validate_addresses(EXPECTED, "new"), 15)


class SecurityGateTests(unittest.TestCase):
    def setUp(self):
        required = REQUIRED["workload"][1]
        self.report = {
            "check_type": "terraform", "summary": {"resource_count": 15, "failed": 0, "parsing_errors": 0},
            "results": {"passed_checks": [{"resource": r} for r in required], "failed_checks": [], "skipped_checks": []},
        }

    def test_complete_report_accepted(self):
        self.assertEqual(validate_report(self.report, "workload", [], 0)["failed"], 0)

    def test_scanner_failure_rejected_even_if_report_looks_clean(self):
        with self.assertRaises(ValueError):
            validate_report(self.report, "workload", [], 2)

    def test_security_finding_blocks_gate(self):
        self.report["results"]["failed_checks"] = [{"check_id": "CKV_AWS_24"}]
        with self.assertRaises(ValueError):
            validate_report(self.report, "workload", [], 0)

    def test_parsing_error_blocks_gate(self):
        self.report["summary"]["parsing_errors"] = 1
        with self.assertRaises(ValueError):
            validate_report(self.report, "workload", [], 0)

    def test_empty_report_blocks_gate(self):
        with self.assertRaises(ValueError):
            validate_report({}, "workload", [], 0)

    def test_partial_scan_blocks_gate(self):
        self.report["summary"]["resource_count"] = 2
        with self.assertRaises(ValueError):
            validate_report(self.report, "workload", [], 0)

    def test_missing_ec2_module_blocks_gate(self):
        self.report["results"]["passed_checks"] = [r for r in self.report["results"]["passed_checks"]
                                                   if r["resource"] != "aws_instance.private_ec2"]
        with self.assertRaises(ValueError):
            validate_report(self.report, "workload", [], 0)

    def test_undocumented_suppression_blocks_gate(self):
        self.report["results"]["skipped_checks"] = [{"check_id": "CKV_AWS_88", "resource": "aws_instance.public_ec2",
                                                     "check_result": {"suppress_comment": "skip"}}]
        with self.assertRaises(ValueError):
            validate_report(self.report, "workload", [], 0)

    def test_resource_scoped_documented_exception_accepted(self):
        self.report["results"]["skipped_checks"] = [{"check_id": "CKV_AWS_88", "resource": "module.ec2.aws_instance.public_ec2",
                                                     "check_result": {"suppress_comment": "EX-003 required Bastion"}}]
        exception = {"id": "EX-003", "check_id": "CKV_AWS_88", "resource": "aws_instance.public_ec2",
                     "reason": "Bastion", "mitigation": "SSH /32"}
        validate_report(self.report, "workload", [exception], 0)
        wrong_resource = copy.deepcopy(exception)
        wrong_resource["resource"] = "aws_instance.private_ec2"
        with self.assertRaises(ValueError):
            validate_report(self.report, "workload", [wrong_resource], 0)


if __name__ == "__main__":
    unittest.main()
