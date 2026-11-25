output "state_bucket_name" {
  description = "Bucket de dien vao backend.hcl/GitHub Variables"
  value       = aws_s3_bucket.state.id
}
