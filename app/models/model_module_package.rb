# frozen_string_literal: true

# == Schema Information
#
# Table name: model_module_packages
#
#  id           :uuid             not null, primary key
#  active       :boolean          default(TRUE)
#  description  :text
#  hidden       :boolean          default(TRUE)
#  name         :string
#  pledge_price :decimal(15, 2)
#  slug         :string
#  store_image  :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  model_id     :uuid
#
class ModelModulePackage < ApplicationRecord
  paginates_per 30

  belongs_to :model, touch: true

  has_many :module_package_items,
           class_name: 'ModelModulePackageItem',
           dependent: :destroy
  has_many :model_modules, through: :module_package_items

  mount_uploader :store_image, StoreImageUploader

  accepts_nested_attributes_for :module_package_items, allow_destroy: true

  before_save :update_slugs

  def self.ordered_by_name
    order(name: :asc)
  end

  def self.visible
    where(hidden: false)
  end

  def self.active
    where(active: true)
  end
end
