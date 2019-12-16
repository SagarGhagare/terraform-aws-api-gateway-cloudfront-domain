
resource "aws_api_gateway_rest_api" "api" {
  name                     = "${var.environment}-${var.api_name}-api"
  description              = "API for Authentication and Authorization"
  minimum_compression_size = "1000"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_ssm_parameter" "api_id" {
  name      = "/environment/${var.environment}/${var.api_name}_api_id"
  type      = "String"
  value     = "${aws_api_gateway_rest_api.api.id}"
  overwrite = true
}
resource "aws_ssm_parameter" "api_root_resource_id" {
  name      = "/environment/${var.environment}/${var.api_name}_api_root_resource_id"
  type      = "String"
  value     = "${aws_api_gateway_rest_api.api.root_resource_id}"
  overwrite = true
}
resource "aws_ssm_parameter" "api_execution_arn" {
  name      = "/environment/${var.environment}/${var.api_name}_api_execution_arn"
  type      = "String"
  value     = "${aws_api_gateway_rest_api.api.execution_arn}"
  overwrite = true
}

resource "aws_cloudfront_distribution" "api_gateway" {
  origin {
    domain_name = "${aws_api_gateway_rest_api.api.id}.execute-api.${var.region}.amazonaws.com"
    origin_path = "/${var.environment}"
    origin_id   = "api"

    custom_origin_config {
			http_port              = 80
			https_port             = 443
			origin_protocol_policy = "https-only"
			origin_ssl_protocols   = ["TLSv1","TLSv1.1"]
    }
  }

  enabled             = true

  aliases = ["${var.domain_name}"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "api"

    forwarded_values {
      query_string = true
			headers = ["Accept", "Referer", "Authorization", "Content-Type"]
			cookies {
				forward = "all"
			}
    }
		compress = true

		lambda_function_association  {
			event_type = "origin-response"
			lambda_arn = "arn:aws:lambda:us-east-1:${var.account_name}:function:http-header-injector:1"
		}

		target_origin_id = "api"

		viewer_protocol_policy = "https-only"
  }

  price_class = "PriceClass_All"

  viewer_certificate {
		acm_certificate_arn      = "${var.ssl_cert_arn}"
		minimum_protocol_version = "TLSv1.1_2016"
		ssl_support_method       = "sni-only"
  }

	restrictions {
		geo_restriction {
			restriction_type = "none"
		}
	}
}


resource "aws_route53_record" "api_cf_route_53_record" {
  zone_id = "${var.route53_zone_id}"

  name = "${var.domain_name}"
  type = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.api_gateway.domain_name}"
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}
