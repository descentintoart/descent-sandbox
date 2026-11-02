variable "site_domain" {
  description = "Public address of the sandbox site"
  type        = string
  default     = "sandbox.descentintoart.com"
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for descentintoart.com"
  type        = string
}
