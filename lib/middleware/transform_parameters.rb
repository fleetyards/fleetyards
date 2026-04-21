module Middleware
  class TransformParameters
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      request.request_parameters.deep_transform_keys! do |key|
        decamelize(key)
      end
      request.query_parameters.deep_transform_keys! do |key|
        decamelize(key)
      end

      @app.call(env)
    rescue ActionController::BadRequest => e
      if e.message.include?("EmptyContentError")
        [400, {"content-type" => "application/json"}, ['{"code":"bad_request","message":"Invalid request parameters"}']]
      else
        raise
      end
    end

    private def decamelize(camel_cased_word)
      camel_cased_word
        .encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
        .split(/(?=[A-Z])/).join("_").downcase
    end
  end
end
