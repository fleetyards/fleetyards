# frozen_string_literal: true

module V1
  module Schemas
    # Every contribution linked to the signed-in account. Unpaginated on
    # purpose: this is one person's own donation history, which is a handful of
    # rows and is read as a whole to pick one.
    class MySupporterContributionsList
      include OpenapiRuby::Components::Base

      schema({
        type: :array,
        items: ::V1::Schemas::MySupporterContribution
      })
    end
  end
end
