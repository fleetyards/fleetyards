# frozen_string_literal: true

class HangarGroup < ApplicationRecord
  belongs_to :user

  has_many :task_forces, dependent: :destroy
  has_many :vehicles, through: :task_forces

  validates :user_id, :name, :color, presence: true

  before_save :update_slugs
  after_commit :broadcast_update

  def broadcast_update
    ActionCable.server.broadcast("hangar_#{user.username}", {}.to_json)
  end
end
