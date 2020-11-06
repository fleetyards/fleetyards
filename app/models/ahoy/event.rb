# frozen_string_literal: true

# == Schema Information
#
# Table name: ahoy_events
#
#  id         :bigint           not null, primary key
#  name       :string
#  properties :jsonb
#  time       :datetime
#  user_id    :uuid
#  visit_id   :bigint
#
# Indexes
#
#  index_ahoy_events_on_name_and_time              (name,time)
#  index_ahoy_events_on_properties_jsonb_path_ops  (properties) USING gin
#  index_ahoy_events_on_user_id                    (user_id)
#  index_ahoy_events_on_visit_id                   (visit_id)
#
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
