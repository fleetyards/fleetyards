require "rswag/specs/request_factory"

Rswag::Specs::RequestFactory.class_eval do
  def build_form_payload(parameters, example)
    # See http://seejohncode.com/2012/04/29/quick-tip-testing-multipart-uploads-with-rspec/
    # Rather than serializing with the appropriate encoding (e.g. multipart/form-data),
    # Rails test infrastructure allows us to send the values directly as a hash
    # PROS: simple to implement, CONS: serialization/deserialization is bypassed in test
    form_data_param = parameters.select { |p| p[:in] == :formData }.first
    form_data_param ? example.send(form_data_param[:name]) : {}
  end
end
