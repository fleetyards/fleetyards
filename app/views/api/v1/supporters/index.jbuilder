# frozen_string_literal: true

json.supporters @supporters do |contribution|
  profile_username = contribution.public_profile_username

  json.display_name contribution.public_name.strip
  json.username profile_username if profile_username.present?
end

json.anonymous_count @anonymous_count
