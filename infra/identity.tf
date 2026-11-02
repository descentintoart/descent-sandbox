# Read-only checks that Terraform can reach AWS and Cloudflare.

data "aws_caller_identity" "current" {}

output "aws_identity" {
  value = data.aws_caller_identity.current.arn
}

data "cloudflare_dns_records" "mx" {
  zone_id = var.cloudflare_zone_id
  type    = "MX"
}

output "mx_records" {
  value = [for r in data.cloudflare_dns_records.mx.result : r.content]
}
