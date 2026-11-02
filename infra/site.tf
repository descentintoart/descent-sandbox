resource "aws_s3_bucket" "site" {
  bucket = "sandbox-descentintoart-com"
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_acm_certificate" "site" {
  provider          = aws.us_east_1
  domain_name       = var.site_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  cert_check = tolist(aws_acm_certificate.site.domain_validation_options)[0]
}

resource "cloudflare_dns_record" "cert_validation" {
  zone_id = var.cloudflare_zone_id
  name    = trimsuffix(local.cert_check.resource_record_name, ".")
  type    = "CNAME"
  content = trimsuffix(local.cert_check.resource_record_value, ".")
  ttl     = 60
  proxied = false
}

resource "aws_acm_certificate_validation" "site" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [cloudflare_dns_record.cert_validation.name]
}