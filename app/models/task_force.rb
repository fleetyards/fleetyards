# frozen_string_literal: true

class TaskForce < ApplicationRecord
  belongs_to :vehicle, touch: true
  belongs_to :hangar_group, touch: true
end
