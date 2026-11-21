variable "aws_region" {
  description = "AWS region for the assignment environment."
  type        = string
  default     = "ap-south-1"
}

variable "demo_cidr" {
  description = "Public IPv4 address of the demo viewer, expressed as a /32 CIDR."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.demo_cidr)) && endswith(var.demo_cidr, "/32")
    error_message = "Use a single public IPv4 address in /32 notation."
  }
}

variable "source_revision" {
  description = "Full commit SHA from the MediFlow repository."
  type        = string

  validation {
    condition     = can(regex("^[a-f0-9]{40}$", var.source_revision))
    error_message = "Provide the full 40-character Git commit SHA."
  }
}

variable "instance_type" {
  description = "x86_64 EC2 size for building and running the assignment containers."
  type        = string
  default     = "t3.small"
}
