require "api_validation_error"

Rails.application.configure do
  unless ENV.fetch("SKIP_COMMITTEE", false)
    config.middleware.use(
      Committee::Middleware::RequestValidation,
      schema_path: "swagger/v1/schema.yaml",
      error_class: ::ApiValidationError,
      strict_reference_validation: true,
      prefix: URI.parse(API_ENDPOINT).path
    )
    config.middleware.use(
      Committee::Middleware::RequestValidation,
      schema_path: "swagger/admin/v1/schema.yaml",
      error_class: ::ApiValidationError,
      strict_reference_validation: true,
      prefix: URI.parse(ADMIN_API_ENDPOINT).path
    )
  end
end
