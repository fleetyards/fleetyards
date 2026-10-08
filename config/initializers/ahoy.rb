# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Ahoy::Store < Ahoy::DatabaseStore
  # A hangar share link's token grants read access to a private hangar, so it
  # must not be kept in the URLs analytics stores.
  SHARE_TOKEN_PATTERN = /([?&]share=)[^&#]*/

  def track_visit(data)
    data[:accept_language] = request.headers["Accept-Language"]
    data[:landing_page] = scrub_share_token(data[:landing_page])
    data[:referrer] = scrub_share_token(data[:referrer])
    super
  end

  # The visit is recorded on the server before any script runs, so only a page
  # view sent from the browser can say whether it runs as the installed app.
  def track_event(data)
    if data[:properties].is_a?(Hash)
      data[:properties] = data[:properties].to_h { |key, value| [key, scrub_share_token(value)] }
    end

    super

    mark_installed if data[:name] == "$view" && installed_view?(data[:properties])
  end

  # Properties arrive as whatever JSON the client posted, not necessarily an object.
  private def installed_view?(properties)
    return false unless properties.is_a?(Hash)

    ActiveModel::Type::Boolean.new.cast(properties.stringify_keys["installed"]) == true
  end

  private def scrub_share_token(value)
    return value unless value.is_a?(String)

    value.gsub(SHARE_TOKEN_PATTERN, "\\1[FILTERED]")
  end

  private def mark_installed
    visit.update_column(:installed, true) if visit && !visit.installed?
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
