# frozen_string_literal: true

module Cleanup
  class UserVisitsJob < ::Cleanup::BaseJob
    def perform(user_id)
      visit_ids = Ahoy::Visit.where(user_id: user_id).pluck(:id)
      Ahoy::Event.where(visit_id: visit_ids).delete_all
      Ahoy::Visit.where(id: visit_ids).delete_all
      Ahoy::Event.where(user_id: user_id).delete_all
    end
  end
end
