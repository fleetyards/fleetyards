# frozen_string_literal: true

# == Schema Information
#
# Table name: hardpoints
#
#  id              :uuid             not null, primary key
#  category        :string
#  component_class :string
#  default_empty   :boolean          default(FALSE)
#  deleted_at      :datetime
#  details         :string
#  hardpoint_type  :string
#  mounts          :integer
#  quantity        :integer
#  rsi_key         :string
#  size            :string
#  created_at      :datetime
#  updated_at      :datetime
#  component_id    :uuid
#  model_id        :uuid
#
# Indexes
#
#  index_hardpoints_on_component_id  (component_id)
#  index_hardpoints_on_model_id      (model_id)
#
class Hardpoint < ApplicationRecord
  belongs_to :model
  belongs_to :component, optional: true

  validates :model_id, presence: true

  def self.undeleted
    where(deleted_at: nil)
  end

  def category_label
    return if category.blank?

    I18n.t("activerecord.attributes.hardpoint.category.#{category}")
  end
end
