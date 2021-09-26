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
#  index_hangar_groups_on_user_id  (user_id)
#
class HangarGroup < ApplicationRecord
  belongs_to :user

  has_many :task_forces, dependent: :destroy
  has_many :vehicles, through: :task_forces

  validates :user_id, :name, :color, presence: true

  before_save :update_slugs
  after_save :touch_vehicles
  after_commit :broadcast_update
  after_touch :clear_association_cache

  def broadcast_update
    HangarChannel.broadcast_to(user, {}.to_json)
  end

  private def touch_vehicles
    return unless public_changed?

    # rubocop:disable Rails/SkipsModelValidations
    vehicles.update_all(updated_at: Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
