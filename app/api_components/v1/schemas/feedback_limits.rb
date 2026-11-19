# frozen_string_literal: true

module V1
  module Schemas
    # The limits the feedback endpoints enforce, as values the generated client
    # can import, so a form counts against the server's number rather than a
    # copy of it. Referenced by nothing, like FeatureFlagName.
    class FeedbackLimits
      include OpenapiRuby::Components::Base

      schema({
        type: :integer,
        enum: [::Feedback::MESSAGE_MAX_LENGTH],
        "x-enumNames": ["MESSAGE_MAX_LENGTH"]
      })
    end
  end
end
