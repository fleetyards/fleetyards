# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    data[:accept_language] = request.headers["Accept-Language"]
    super
  end
end
# rubocop:enable Style/ClassAndModuleChildren

Ahoy.mask_ips = true
Ahoy.cookies = :none
Ahoy.api = true
Ahoy.geocode = false
Ahoy.user_agent_parser = :device_detector

# Analytics run on legitimate interest, so an objection has to stop the data
# being recorded rather than only hiding it from the admin stats. Signed-in
# users object through their account setting; anonymous visitors through Global
# Privacy Control, which is the only signal they can send without an account.
Ahoy.exclude_method = lambda do |controller, request|
  next true if request&.headers&.[]("Sec-GPC") == "1"
  next false if controller.blank?

  Ahoy.user_method.call(controller)&.tracking == false
end
