terraform {
  # bucket, key and region are supplied by backend.hcl, never credentials.
  backend "s3" {
    encrypt      = true
    use_lockfile = true
  }
}
