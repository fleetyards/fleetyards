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
  end

  private def decamelize(camel_cased_word)
    camel_cased_word.split(/(?=[A-Z])/).join("_").downcase
  end
end
