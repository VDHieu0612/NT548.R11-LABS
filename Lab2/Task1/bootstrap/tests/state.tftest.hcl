mock_provider "aws" {}

variables {
  state_bucket_name = "nt548-example-state-not-created"
}

run "state_bucket_protection" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.state.versioning_configuration[0].status == "Enabled"
    error_message = "State bucket must keep version history."
  }
  assert {
    condition     = aws_s3_bucket_public_access_block.state.block_public_acls && aws_s3_bucket_public_access_block.state.block_public_policy && aws_s3_bucket_public_access_block.state.ignore_public_acls && aws_s3_bucket_public_access_block.state.restrict_public_buckets
    error_message = "All four public access protections must remain enabled."
  }
  assert {
    condition     = aws_s3_bucket.state.force_destroy == false
    error_message = "State bucket must not allow forced deletion of its objects."
  }
}

run "reject_empty_bucket_name" {
  command = plan
  variables {
    state_bucket_name = ""
  }
  expect_failures = [var.state_bucket_name]
}

run "reject_uppercase_bucket_name" {
  command = plan
  variables {
    state_bucket_name = "NT548-Invalid-Bucket"
  }
  expect_failures = [var.state_bucket_name]
}
