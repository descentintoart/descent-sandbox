provider "aws" {
  region  = "us-east-2"
  profile = "art"

  default_tags {
    tags = {
      project = "sandbox"
    }
  }
}

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