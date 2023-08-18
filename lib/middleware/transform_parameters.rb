class TransformParameters
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    if api_request?(request)
      request.request_parameters.deep_transform_keys! do |key|
        decamelize(key)
      end
      request.query_parameters.deep_transform_keys! do |key|
        decamelize(key)
      end
    end

    @app.call(env)
  end

  private def api_request?(request)
    request.path.start_with?("/api")
  end

  private def decamelize(camel_cased_word)
    camel_cased_word.split(/(?=[A-Z])/).join("_").downcase
  end
end
