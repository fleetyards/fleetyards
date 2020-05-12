# frozen_string_literal: true

require 'csv'

class Vehicle < ApplicationRecord
  paginates_per 30

  scope :visible, -> { where(hidden: false) }

  belongs_to :model
  belongs_to :model_skin, optional: true
  belongs_to :user

  has_many :task_forces, dependent: :destroy
  has_many :hangar_groups, through: :task_forces

  has_many :vehicle_modules, dependent: :destroy
  has_many :model_modules, through: :vehicle_modules

  has_many :vehicle_upgrades, dependent: :destroy
  has_many :model_upgrades, through: :vehicle_upgrades

  validates :model_id, presence: true

  NULL_ATTRS = %w[name].freeze
  before_save :nil_if_blank
  after_save :set_flagship
  after_commit :broadcast_update
  after_destroy :remove_loaners
  after_create :add_loaners
  after_touch :clear_association_cache

  ransack_alias :name, :name_or_model_name_or_model_slug
  ransack_alias :on_sale, :model_on_sale
  ransack_alias :length, :model_length
  ransack_alias :price, :model_price
  ransack_alias :pledge_price, :model_pledge_price
  ransack_alias :manufacturer, :model_manufacturer_slug
  ransack_alias :classification, :model_classification
  ransack_alias :focus, :model_focus
  ransack_alias :size, :model_size
  ransack_alias :production_status, :model_production_status
  ransack_alias :hangar_groups, :hangar_groups_slug

  def add_loaners
    return if loaner?

    model.loaners.each do |model_loaner|
      create_loaner(model_loaner)
    end
  end

  def remove_loaners
    return if loaner?

    Vehicle.where(loaner: true, vehicle_id: id, user_id: user_id).destroy_all

    Vehicle.where(loaner: true, user_id: user_id).find_each do |loaner_vehicle|
      loaner_vehicle.update(
        hidden: Vehicle.where(loaner: true, model_id: loaner_vehicle.model_id, user_id: user_id, hidden: false).where.not(id: loaner_vehicle.id).exists?
      )
    end
  end

  def create_loaner(model_loaner)
    Vehicle.create(
      loaner: true,
      model_id: model_loaner.id,
      user_id: user_id,
      vehicle_id: id,
      public: false,
      purchased: true,
      hidden: Vehicle.exists?(loaner: true, model_id: model_loaner.id, user_id: user_id)
    )
  end

  def broadcast_update
    return if loaner?

    HangarChannel.broadcast_to(user, to_json)
  end

  def self.purchased
    where(purchased: true)
  end

  def self.public
    purchased.where(purchased: true, public: true)
  end

  def self.to_csv
    attributes = [
      { key: 'name', value: 'name' },
      { key: 'model', value: 'model_name' },
      { key: 'modelSlug', value: 'model_slug' },
      { key: 'manufacturer', value: 'model_manufacturer' },
      { key: 'purchased', value: 'purchased' },
      { key: 'saleNotify', value: 'sale_notify' },
      { key: 'flagship', value: 'flagship' },
      { key: 'nameVisible', value: 'name_visible' },
      { key: 'public', value: 'public' }
    ]

    CSV.generate(headers: true) do |csv|
      csv << attributes.map { |item| item[:key] }

      all.find_each do |vehicle|
        csv << attributes.map { |attr| vehicle.send(attr[:value]) }
      end
    end
  end

  def model_manufacturer
    model.manufacturer.name
  end

  def set_flagship
    return unless flagship?

    # rubocop:disable Rails/SkipsModelValidations
    Vehicle.where(user_id: user_id, flagship: true)
           .where.not(id: id)
           .update_all(flagship: false)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def to_json(*_args)
    to_jbuilder_json
  end

  protected def nil_if_blank
    NULL_ATTRS.each { |attr| self[attr] = nil if self[attr].blank? }
  end
end
