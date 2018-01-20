# frozen_string_literal: true

class TaskForce < ApplicationRecord
  belongs_to :hangar_group
  belongs_to :vehicle
end
