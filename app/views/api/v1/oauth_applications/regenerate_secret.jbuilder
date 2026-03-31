# frozen_string_literal: true

json.partial!("api/v1/oauth_applications/base", application: @application)
json.secret @application.secret
