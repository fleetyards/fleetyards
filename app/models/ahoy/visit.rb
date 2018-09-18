# frozen_string_literal: true

module Ahoy
  class Visit < ApplicationRecord
    self.table_name = 'ahoy_visits'

    has_many :events, class_name: 'Ahoy::Event', dependent: :nullify
    belongs_to :user, optional: true
  end
end
