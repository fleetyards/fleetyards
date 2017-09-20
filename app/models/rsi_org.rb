# encoding: utf-8
# frozen_string_literal: true

class RsiOrg < ApplicationRecord
  validates :name, :sid, presence: true
end
