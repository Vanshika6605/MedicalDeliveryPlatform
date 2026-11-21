output "app_url" {
  description = "Demo application URL."
  value       = "http://${aws_instance.mediflow.public_ip}"
}

output "instance_id" {
  description = "EC2 instance identifier for AWS Systems Manager."
  value       = aws_instance.mediflow.id
}

output "source_revision" {
  description = "Git revision used during bootstrap."
  value       = var.source_revision
}
