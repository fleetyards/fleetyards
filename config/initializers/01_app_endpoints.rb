# frozen_string_literal: true

require "app_endpoint_resolver"

endpoints = AppEndpointResolver.new

FRONTEND_DOMAIN = endpoints.frontend_domain
FRONTEND_ENDPOINT = endpoints.frontend_endpoint

API_DOMAIN = endpoints.api_domain
API_ENDPOINT = endpoints.api_endpoint

ADMIN_DOMAIN = endpoints.admin_domain
ADMIN_ENDPOINT = endpoints.admin_endpoint
ADMIN_API_ENDPOINT = endpoints.admin_api_endpoint

CABLE_ENDPOINT = endpoints.cable_endpoint

DOCS_DOMAIN = endpoints.docs_domain
DOCS_ENDPOINT = endpoints.docs_endpoint
