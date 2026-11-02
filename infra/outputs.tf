output "api_endpoint" {
  value = aws_apigatewayv2_api.ulid.api_endpoint
}

output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}

output "distribution_id" {
  value = aws_cloudfront_distribution.site.id
}

output "site_url" {
  value = "https://${var.site_domain}/ulid/"
}
