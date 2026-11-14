
# 1. Cache public static files
resource "aws_cloudfront_cache_policy" "static" {
  name    = "lab2-static-cache"
  comment = "Cache public static files for up to one day"

  min_ttl     = 0
  default_ttl = 86400
  max_ttl     = 31536000

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }

    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

# 2. Disable caching for dynamic API responses
resource "aws_cloudfront_cache_policy" "api_disabled" {
  name    = "lab2-api-cache-disabled"
  comment = "Never cache dynamic API responses"

  min_ttl     = 0
  default_ttl = 0
  max_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }

    enable_accept_encoding_gzip   = false
    enable_accept_encoding_brotli = false
  }
}

# 3. Static content needs minimal information
resource "aws_cloudfront_origin_request_policy" "static" {
  name    = "lab2-static-origin-request"
  comment = "Do not forward viewer-specific values"

  cookies_config {
    cookie_behavior = "none"
  }

  query_strings_config {
    query_string_behavior = "none"
  }

  headers_config {
    header_behavior = "none"
  }
}

# 4. API receives viewer request information,
# but not the public Host header.
resource "aws_cloudfront_origin_request_policy" "api" {
  name    = "lab2-api-origin-request"
  comment = "Forward API information except viewer Host"

  cookies_config {
    cookie_behavior = "all"
  }

  query_strings_config {
    query_string_behavior = "all"
  }

  headers_config {
    header_behavior = "allExcept"

    headers {
      items = ["Host"]
    }
  }
}

# 5. Explicit caching instructions for public static files
resource "aws_cloudfront_response_headers_policy" "static" {
  name    = "lab2-static-response-headers"
  comment = "One-day browser caching for public assets"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      value    = "public, max-age=86400"
      override = true
    }
  }
}
