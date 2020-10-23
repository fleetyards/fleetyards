# frozen_string_literal: true

module Ahoy
  class Event < ApplicationRecord
    include Ahoy::QueryMethods

    self.table_name = 'ahoy_events'

    belongs_to :visit
    belongs_to :user, optional: true

    def self.without_users(user_ids)
      includes(:visit).where.not(ahoy_visits: { user_id: user_ids }).references(:ahoy_visits)
        .or(user_empty)
    end

    def self.user_empty
      includes(:visit).where(ahoy_visits: { user_id: nil }).references(:ahoy_visits)
    end

    def self.one_month
      where(time: 1.month.ago..)
    end
  end
end
