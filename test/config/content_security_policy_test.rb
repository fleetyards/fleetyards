# frozen_string_literal: true

require "test_helper"

class ContentSecurityPolicyTest < ActiveSupport::TestCase
  # A sign-in form posts to our own /users/auth/:provider and is answered with a
  # redirect to the provider. Chrome applies form-action to every hop of that
  # chain, so the provider's authorize host has to be in the policy -- and for
  # Patreon, the one provider whose strategy lives in this repo, that host is
  # written in two places. Leaving it out of one of them shipped a button that
  # did nothing and a violation naming a URL the policy plainly allows.
  test "form-action allows the host the Patreon strategy authorizes against" do
    authorize_url = OmniAuth::Strategies::Patreon.default_options.client_options[:authorize_url]

    assert_includes form_action_sources, URI.parse(authorize_url).origin
  end

  private def form_action_sources
    Rails.application.config.content_security_policy.directives.fetch("form-action")
  end
end
