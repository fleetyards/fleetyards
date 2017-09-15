# encoding: utf-8
# frozen_string_literal: true

class RsiAffiliation < ApplicationRecord
  belongs_to :user
  belongs_to :rsi_org

  before_save :update_main_org

  def update_main_org
    return unless main?

    RsiAffiliation.where(user_id: user_id).where(main: true).find_each do |affiliation|
      affiliation.main = false
      affiliation.save
    end
  end
end
