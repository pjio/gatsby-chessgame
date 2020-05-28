terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "pjio"

    workspaces {
      name = "chessgame"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "chessgame.xubaso.com"
  acl    = "public-read"
  region = "eu-central-1"

  website {
    index_document = "index.html"
  }
}

locals {
  s3_origin_id  = "s3_gatsby"
  api_origin_id = "api_serverless"

  # The api gateway was created by serverless and therefore is a hardcoded url here
  api_gateway  = "i0850prku1.execute-api.eu-central-1.amazonaws.com"
  api_stage    = "/dev"
}

resource "aws_cloudfront_distribution" "cf_distribution" {
  origin {
    domain_name = aws_s3_bucket.s3_bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
  }

  origin {
    domain_name = local.api_gateway
    origin_path = local.api_stage
    origin_id   = local.api_origin_id

    # Note to myself: The presence of custom_origin_config specifies the type of the origin
    custom_origin_config {
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_protocol_policy = "https-only"
      http_port              = "80"
      https_port             = "443"
    }
  }

  wait_for_deployment = false
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Created with terraform"
  default_root_object = "index.html"

  aliases = ["xubaso.com"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    max_ttl                = 86400
    default_ttl            = 0
    compress               = true
  }

  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.api_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    max_ttl                = 86400
    default_ttl            = 0
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    # Hardcoded arn of the manually added letsencrypt certificate
    acm_certificate_arn = "arn:aws:acm:us-east-1:984630510682:certificate/a48ecc45-ce34-4d9b-bc85-7f6428881331"
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }

  custom_error_response {
    error_caching_min_ttl = 300
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
  }
}

resource "aws_route53_zone" "r53_zone" {
    comment = "Created with terraform"
    name    = "xubaso.com."
    tags    = {}
}

# Note to myself: Ensure manually that the created NS entrys match with the name servers in "Registered Domains"
resource "aws_route53_record" "r53_zone" {
  name    = ""
  type    = "A"
  zone_id = aws_route53_zone.r53_zone.zone_id

  alias {
    name                   = aws_cloudfront_distribution.cf_distribution.domain_name
    evaluate_target_health = false
    zone_id                = aws_cloudfront_distribution.cf_distribution.hosted_zone_id
  }
}

resource "aws_route53_record" "letsencrypt" {
  name    = ""
  type    = "TXT"
  zone_id = aws_route53_zone.r53_zone.zone_id
  ttl     = 300
  records = ["abcdefghijklmnopqrstuvwxyz"]
}
