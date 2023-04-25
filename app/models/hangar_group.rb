# frozen_string_literal: true

# == Schema Information
#
# Table name: hangar_groups
#
#  id         :uuid             not null, primary key
#  color      :string
#  name       :string
#  public     :boolean          default(FALSE)
#  slug       :string
#  sort       :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid
#
# Indexes
#
#  hangar_groups_user_id_slug_index         (user_id,slug) UNIQUE
#  index_hangar_groups_on_user_id           (user_id)
#  index_hangar_groups_on_user_id_and_name  (user_id,name) UNIQUE
#
class HangarGroup < ApplicationRecord
  belongs_to :user

  has_many :task_forces, dependent: :destroy
  has_many :vehicles, through: :task_forces

  validates :name, :color, presence: true
  validates :name, uniqueness: {scope: :user_id}

  before_save :update_slugs
  after_save :touch_vehicles
  after_commit :broadcast_update

  def broadcast_update
    HangarChannel.broadcast_to(user, {}.to_json)
  end

  private def touch_vehicles
    # rubocop:disable Rails/SkipsModelValidations
    vehicles.update_all(updated_at: Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
