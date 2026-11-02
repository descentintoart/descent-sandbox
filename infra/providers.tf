provider "aws" {
  region  = "us-east-2"
  profile = "art"

  default_tags {
    tags = {
      project = "sandbox"
    }
  }
}

# CloudFront only accepts certificates made in us-east-1.
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = "art"

  default_tags {
    tags = {
      project = "sandbox"
    }
  }
}

# Token comes from the CLOUDFLARE_API_TOKEN environment variable.
provider "cloudflare" {}
