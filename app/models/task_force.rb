# frozen_string_literal: true

class TaskForce < ApplicationRecord
  belongs_to :vehicle
  belongs_to :hangar_group
end
