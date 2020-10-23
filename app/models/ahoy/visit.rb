# frozen_string_literal: true

module Ahoy
  class Visit < ApplicationRecord
    self.table_name = 'ahoy_visits'

    has_many :events, class_name: 'Ahoy::Event', dependent: :nullify
    belongs_to :user, optional: true

    def self.without_users(user_ids)
      where.not(user_id: user_ids).or(where(user_id: nil))
    end

    def self.one_month
      where(started_at: 1.month.ago..)
    end

    def self.one_year
      where(started_at: 1.year.ago..)
    end
  end
end
