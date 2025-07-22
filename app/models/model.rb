# frozen_string_literal: true

# == Schema Information
#
# Table name: models
#
#  id                         :uuid             not null, primary key
#  active                     :boolean          default(TRUE)
#  angled_view                :string
#  angled_view_colored        :string
#  angled_view_colored_height :integer
#  angled_view_colored_width  :integer
#  angled_view_height         :integer
#  angled_view_width          :integer
#  beam                       :decimal(15, 2)   default(0.0), not null
#  brochure                   :string
#  cargo                      :decimal(15, 2)
#  cargo_holds                :string
#  classification             :string(255)
#  description                :text
#  dock_size                  :integer
#  erkul_identifier           :string
#  fleetchart_image           :string
#  fleetchart_image_height    :integer
#  fleetchart_image_width     :integer
#  fleetchart_offset_length   :decimal(15, 2)
#  focus                      :string(255)
#  front_view                 :string
#  front_view_colored         :string
#  front_view_colored_height  :integer
#  front_view_colored_width   :integer
#  front_view_height          :integer
#  front_view_width           :integer
#  fuel_consumption           :decimal(15, 2)
#  ground                     :boolean          default(FALSE)
#  ground_acceleration        :decimal(15, 2)
#  ground_decceleration       :decimal(15, 2)
#  ground_max_speed           :decimal(15, 2)
#  ground_reverse_speed       :decimal(15, 2)
#  height                     :decimal(15, 2)   default(0.0), not null
#  hidden                     :boolean          default(TRUE)
#  holo                       :string
#  holo_colored               :boolean          default(FALSE)
#  hydrogen_fuel_tank_size    :decimal(15, 2)
#  hydrogen_fuel_tanks        :string
#  images_count               :integer          default(0)
#  last_updated_at            :datetime
#  length                     :decimal(15, 2)   default(0.0), not null
#  loaners_count              :integer          default(0), not null
#  mass                       :decimal(15, 2)   default(0.0), not null
#  max_crew                   :integer
#  max_speed                  :decimal(15, 2)
#  max_speed_acceleration     :decimal(15, 2)
#  max_speed_decceleration    :decimal(15, 2)
#  min_crew                   :integer
#  model_paints_count         :integer          default(0)
#  module_hardpoints_count    :integer          default(0)
#  name                       :string(255)
#  notified                   :boolean          default(FALSE)
#  on_sale                    :boolean          default(FALSE)
#  pitch                      :decimal(15, 2)
#  pitch_boosted              :decimal(15, 2)
#  pledge_price               :decimal(15, 2)
#  price                      :decimal(15, 2)
#  production_note            :string(255)
#  production_status          :string(255)
#  quantum_fuel_tank_size     :decimal(15, 2)
#  quantum_fuel_tanks         :string
#  reverse_speed_boosted      :decimal(15, 2)
#  roll                       :decimal(15, 2)
#  roll_boosted               :decimal(15, 2)
#  rsi_beam                   :decimal(15, 2)   default(0.0), not null
#  rsi_cargo                  :decimal(15, 2)
#  rsi_classification         :string
#  rsi_ctm_url                :string
#  rsi_description            :text
#  rsi_focus                  :string
#  rsi_height                 :decimal(15, 2)   default(0.0), not null
#  rsi_length                 :decimal(15, 2)   default(0.0), not null
#  rsi_mass                   :decimal(15, 2)   default(0.0), not null
#  rsi_max_crew               :integer
#  rsi_max_speed              :decimal(15, 2)
#  rsi_min_crew               :integer
#  rsi_name                   :string
#  rsi_pitch                  :decimal(15, 2)
#  rsi_pledge_slug            :string
#  rsi_pledge_value           :integer
#  rsi_roll                   :decimal(15, 2)
#  rsi_scm_speed              :decimal(15, 2)
#  rsi_size                   :string
#  rsi_slug                   :string
#  rsi_store_image            :string
#  rsi_store_image_height     :integer
#  rsi_store_image_width      :integer
#  rsi_store_url              :string
#  rsi_yaw                    :decimal(15, 2)
#  sales_page_url             :string
#  sc_beam                    :decimal(15, 2)
#  sc_height                  :decimal(15, 2)
#  sc_identifier              :string
#  sc_length                  :decimal(15, 2)
#  scm_speed                  :decimal(15, 2)
#  scm_speed_acceleration     :decimal(15, 2)
#  scm_speed_boosted          :decimal(15, 2)
#  scm_speed_decceleration    :decimal(15, 2)
#  side_view                  :string
#  side_view_colored          :string
#  side_view_colored_height   :integer
#  side_view_colored_width    :integer
#  side_view_height           :integer
#  side_view_width            :integer
#  size                       :string
#  slug                       :string(255)
#  store_image                :string(255)
#  store_image_height         :integer
#  store_image_width          :integer
#  store_images_updated_at    :datetime
#  store_url                  :string(255)
#  top_view                   :string
#  top_view_colored           :string
#  top_view_colored_height    :integer
#  top_view_colored_width     :integer
#  top_view_height            :integer
#  top_view_width             :integer
#  upgrade_kits_count         :integer          default(0)
#  videos_count               :integer          default(0)
#  yaw                        :decimal(15, 2)
#  yaw_boosted                :decimal(15, 2)
#  created_at                 :datetime
#  updated_at                 :datetime
#  base_model_id              :uuid
#  manufacturer_id            :uuid
#  rsi_chassis_id             :integer
#  rsi_id                     :integer
#
# Indexes
#
#  index_models_on_base_model_id  (base_model_id)
#
class Model < ApplicationRecord
  include ActionView::Helpers::NumberHelper
  include RoutingConcern

  attr_accessor :update_reason, :update_reason_description, :author_id

  has_paper_trail on: %i[update], only: %i[
    classification production_status production_note focus pledge_price length beam height mass
    cargo size min_crew max_crew scm_speed max_speed ground_max_speed ground_reverse_speed
    ground_acceleration ground_decceleration scm_speed_acceleration scm_speed_decceleration
    max_speed_acceleration max_speed_decceleration pitch yaw roll brochure price store_image
    store_url hydrogen_fuel_tank_size quantum_fuel_tank_size cargo_holds hydrogen_fuel_tanks
    quantum_fuel_tanks holo sales_page_url top_view side_view angled_view front_view
    angled_view_colored side_view_colored top_view_colored front_view_colored
  ], meta: {
    author_id: :author_id,
    reason: :update_reason,
    reason_description: :update_reason_description
  }

  paginates_per 30
  max_paginates_per 240
  per_page_steps [15, 30, 60, 120, 240]

  searchkick searchable: %i[name manufacturer_name manufacturer_code],
    word_start: %i[name manufacturer_name]

  def search_data
    {
      name:,
      manufacturer_name: manufacturer.name,
      manufacturer_code: manufacturer.code
    }
  end

  def should_index?
    active && !hidden
  end

  belongs_to :manufacturer, optional: true

  has_one :addition,
    class_name: "ModelAddition",
    dependent: :destroy,
    inverse_of: :model

  delegate :net_cargo, to: :addition, allow_nil: true
  delegate :height, :length, :cargo, :max_crew, :min_crew,
    :scm_speed, :afterburner_speed, :mass, :beam, :price, to: :addition, allow_nil: true, prefix: true

  accepts_nested_attributes_for :addition, allow_destroy: true

  has_many :hardpoints, as: :parent, dependent: :destroy, autosave: true
  has_many :components, through: :hardpoints

  has_many :model_hardpoints,
    dependent: :destroy,
    autosave: true
  has_many :hardpoint_components, through: :model_hardpoints
  has_many :vehicles, dependent: :destroy

  has_many :model_prices, dependent: :destroy

  has_many :module_hardpoints, dependent: :destroy
  has_many :modules,
    through: :module_hardpoints,
    source: :model_module

  has_many :module_packages,
    class_name: "ModelModulePackage",
    dependent: :destroy

  has_many :model_loaners,
    -> { where(hidden: false) },
    dependent: :destroy,
    inverse_of: :model
  has_many :loaners,
    through: :model_loaners,
    source: :loaner_model

  has_many :upgrade_kits, dependent: :destroy
  has_many :upgrades,
    through: :upgrade_kits,
    source: :model_upgrade

  has_many :paints,
    class_name: "ModelPaint",
    dependent: :destroy,
    inverse_of: :model

  has_many :images,
    as: :gallery,
    dependent: :destroy,
    inverse_of: :gallery

  has_many :videos,
    dependent: :destroy

  has_many :model_snub_crafts,
    dependent: :destroy,
    inverse_of: :model

  has_many :snub_crafts,
    through: :model_snub_crafts,
    source: :snub_craft

  has_many :item_prices, as: :item, dependent: :destroy

  has_many :docks, dependent: :destroy

  enum :dock_size,
    Dock.ship_sizes.keys.map(&:to_sym)

  serialize :cargo_holds, coder: YAML
  serialize :quantum_fuel_tanks, coder: YAML
  serialize :hydrogen_fuel_tanks, coder: YAML

  accepts_nested_attributes_for :videos, allow_destroy: true
  accepts_nested_attributes_for :docks, allow_destroy: true

  mount_uploader :store_image, StoreImageUploader
  mount_uploader :rsi_store_image, StoreImageUploader
  mount_uploader :fleetchart_image, FleetchartImageUploader
  mount_uploader :top_view, FleetchartImageUploader
  mount_uploader :side_view, FleetchartImageUploader
  mount_uploader :front_view, FleetchartImageUploader
  mount_uploader :angled_view, FleetchartImageUploader
  mount_uploader :top_view_colored, FleetchartImageUploader
  mount_uploader :side_view_colored, FleetchartImageUploader
  mount_uploader :front_view_colored, FleetchartImageUploader
  mount_uploader :angled_view_colored, FleetchartImageUploader
  mount_uploader :brochure, BrochureUploader
  mount_uploader :holo, HoloUploader

  has_one_attached :new_store_image
  has_one_attached :new_rsi_store_image
  has_one_attached :new_fleetchart_image
  has_one_attached :new_top_view
  has_one_attached :new_side_view
  has_one_attached :new_front_view
  has_one_attached :new_angled_view
  has_one_attached :new_top_view_colored
  has_one_attached :new_side_view_colored
  has_one_attached :new_front_view_colored
  has_one_attached :new_angled_view_colored
  has_one_attached :new_brochure
  has_one_attached :new_holo

  before_save :update_slugs

  before_save :update_from_hardpoints
  before_create :set_last_updated_at

  after_save :send_on_sale_notification, if: :saved_change_to_on_sale?
  after_save :broadcast_update
  after_save :send_new_model_notification

  validates :name, presence: true, uniqueness: true

  DEFAULT_SORTING_PARAMS = "name asc"
  ALLOWED_SORTING_PARAMS = [
    "name asc", "name desc", "createdAt asc", "createdAt desc", "length asc", "length desc",
    "beam asc", "beam desc", "height asc", "height desc", "mass asc", "mass desc", "cargo asc",
    "cargo desc", "manufacturerName asc", "manufacturerName desc", "pledgePrice asc",
    "pledgePrice desc", "price asc", "price desc", "scmSpeed asc", "scmSpeed desc", "maxSpeed asc",
    "maxSpeed desc", "groundMaxSpeed asc", "groundMaxSpeed desc", "productionStatus asc",
    "productionStatus desc", "focus asc", "focus desc", "rsiId asc", "rsiId desc"
  ]

  ransack_alias :manufacturer, :manufacturer_slug
  ransack_alias :search, :name_or_slug_or_manufacturer_slug

  def self.ransackable_attributes(auth_object = nil)
    [
      "active", "angled_view", "angled_view_colored", "angled_view_colored_height",
      "angled_view_colored_width", "angled_view_height", "angled_view_width", "base_model_id",
      "beam", "brochure", "cargo", "cargo_holds", "classification", "created_at", "description",
      "dock_size", "erkul_identifier", "fleetchart_image", "fleetchart_image_height",
      "fleetchart_image_width", "fleetchart_offset_length", "focus", "front_view",
      "front_view_colored", "front_view_colored_height", "front_view_colored_width",
      "front_view_height", "front_view_width", "ground", "ground_acceleration",
      "ground_decceleration", "ground_max_speed", "ground_reverse_speed", "height", "hidden",
      "holo", "holo_colored", "hydrogen_fuel_tank_size", "hydrogen_fuel_tanks", "id", "id_value",
      "images_count", "last_updated_at", "length", "loaners_count",
      "manufacturer", "manufacturer_id", "mass", "max_crew", "max_speed", "max_speed_acceleration",
      "max_speed_decceleration", "min_crew", "model_paints_count", "module_hardpoints_count",
      "name", "notified", "on_sale", "pitch", "pledge_price", "price", "production_note",
      "production_status", "quantum_fuel_tank_size", "quantum_fuel_tanks", "roll", "rsi_beam",
      "rsi_cargo", "rsi_chassis_id", "rsi_classification", "rsi_description", "rsi_focus",
      "rsi_height", "rsi_id", "rsi_length", "rsi_mass", "rsi_max_crew", "rsi_max_speed",
      "rsi_min_crew", "rsi_name", "rsi_pitch", "rsi_roll", "rsi_scm_speed", "rsi_size", "rsi_slug",
      "rsi_store_image", "rsi_store_url", "rsi_yaw", "sales_page_url", "sc_beam", "sc_height",
      "sc_identifier", "sc_length", "scm_speed", "scm_speed_acceleration",
      "scm_speed_decceleration", "search", "side_view", "side_view_colored",
      "side_view_colored_height", "side_view_colored_width", "side_view_height", "side_view_width",
      "size", "slug", "store_image", "store_images_updated_at", "store_url", "top_view",
      "top_view_colored", "top_view_colored_height", "top_view_colored_width", "top_view_height",
      "top_view_width", "updated_at", "upgrade_kits_count", "videos_count", "yaw"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    [
      "addition", "components", "docks", "images", "loaners", "manufacturer", "model_hardpoints",
      "model_prices", "model_loaners", "model_snub_crafts", "module_hardpoints", "module_packages",
      "modules", "paints", "snub_crafts", "upgrade_kits", "upgrades", "vehicles",
      "versions", "videos"
    ]
  end

  def self.ordered_by_name
    order(name: :asc)
  end

  PRODUCTION_STATUSES = ["in-concept", "in-production", "flight-ready"]

  def self.production_status_filters
    PRODUCTION_STATUSES.map do |item|
      Filter.new(
        category: "productionStatus",
        label: item.humanize,
        value: item
      )
    end
  end

  def self.classification_filters
    Model.classifications.map do |item|
      Filter.new(
        category: "classification",
        label: item.humanize,
        value: item
      )
    end
  end

  def self.dock_size_filters
    Model.dock_sizes.map do |key, item|
      Filter.new(
        category: "dock_size",
        label: key.humanize,
        value: item
      )
    end
  end

  def self.classifications
    Model.visible.active.order(classification: :asc).all.map(&:classification).compact_blank.compact.uniq
  end

  def self.focus_filters
    Model.visible.active.all.map(&:focus).compact_blank.compact.uniq.map do |item|
      Filter.new(
        category: "focus",
        label: item.humanize,
        value: item
      )
    end
  end

  def self.size_filters
    %w[vehicle snub small medium large extra_large capital].map do |item|
      Filter.new(
        category: "size",
        label: item.humanize,
        value: item
      )
    end
  end

  def self.year(year)
    where("created_at <= ? AND created_at >= ?", "#{year}-12-31", "#{year}-01-01")
  end

  def self.visible
    where(hidden: false)
  end

  def self.active
    where(active: true)
  end

  def self.with_dock
    includes(:docks).where.not(docks: {model_id: nil})
  end

  def update_from_hardpoints
    set_cargo_from_hardpoints
    set_quantum_fuel_from_hardpoints
    set_hydrogen_fuel_from_hardpoints
  end

  def set_cargo_from_hardpoints
    return if cargo_holds.blank? || (cargo.present? && !cargo_holds_change_to_be_saved)

    self.cargo = cargo_holds.sum do |cargo_hold|
      cargo_hold.dig("dimensions", "scu")&.to_f || 0
    end
  end

  def set_quantum_fuel_from_hardpoints
    return if quantum_fuel_tanks.blank? || (quantum_fuel_tank_size.present? && !quantum_fuel_tanks_change_to_be_saved)

    self.quantum_fuel_tank_size = quantum_fuel_tanks.sum do |item|
      item["capacity"]
    end
  end

  def set_hydrogen_fuel_from_hardpoints
    return if hydrogen_fuel_tanks.blank? || (hydrogen_fuel_tank_size.present? && !hydrogen_fuel_tanks_change_to_be_saved)

    self.hydrogen_fuel_tank_size = hydrogen_fuel_tanks.sum do |item|
      item["capacity"]
    end
  end

  def set_fuel_consumption_from_hardpoints
    thrusters = hardpoints.includes(:component).where(group: :thruster).filter_map do |hardpoint|
      next if hardpoint.component.blank?

      hardpoint.component.type_data
    end

    self.fuel_consumption = thrusters.sum do |thruster|
      thruster.dig("fuel_burn_rate_per10_k_newton").to_f || 0
    end
  end

  def rsi_store_url
    "#{Rails.configuration.rsi.endpoint}#{store_url}"
  end

  def rsi_sales_page_url
    return if sales_page_url.blank?

    "#{Rails.configuration.rsi.endpoint}#{sales_page_url}"
  end

  def sold_at
    item_prices.sell.order(price: :asc).uniq(&:location)
  end

  def bought_at
    item_prices.buy.order(price: :asc).uniq(&:location)
  end

  def rental_at
    item_prices.rental.order(price: :asc).uniq(&:location)
  end

  def dock_counts
    docks.to_a.group_by(&:ship_size).map do |size, docks_by_size|
      docks_by_size.group_by(&:dock_type).map do |dock_type, docks_by_type|
        DockCount.new(dock_size: size, dock_type:, dock_type_label: docks_by_type.first.dock_type_label, dock_count: docks_by_type.size)
      end
    end.flatten
  end

  def variants
    if base_model_id.present?
      Model.where(base_model_id:).where.not(id:).where.not(base_model_id: nil)
    else
      Model.where(rsi_chassis_id:).where.not(id:).where.not(rsi_chassis_id: nil)
    end
  end

  def in_hangar(user)
    return if user.blank?

    user.models.exists?(id)
  end

  def random_image
    images.enabled.background.order(Arel.sql("RANDOM()")).first
  end

  def cargo_label
    return if cargo.blank? || cargo.zero?

    number = number_with_precision(
      cargo,
      precision: 2,
      strip_insignificant_zeros: true
    )

    [number, "SCU"].join(" ")
  end

  def length_label
    return if length.blank? || length.zero?

    number = number_with_precision(
      length,
      precision: 2,
      strip_insignificant_zeros: true
    )

    [number, "m"].join(" ")
  end

  def beam_label
    return if beam.blank? || beam.zero?

    number = number_with_precision(
      beam,
      precision: 2,
      strip_insignificant_zeros: true
    )

    [number, "m"].join(" ")
  end

  def height_label
    return if height.blank? || height.zero?

    number = number_with_precision(
      height,
      precision: 2,
      strip_insignificant_zeros: true
    )

    [number, "m"].join(" ")
  end

  def price_label
    return if price.blank? || price.zero?

    number = number_with_precision(
      price,
      precision: 2,
      strip_insignificant_zeros: true
    )

    [number, "aUEC"].join(" ")
  end

  def pledge_price_label
    return if pledge_price.blank? || pledge_price.zero?

    number_to_currency(
      pledge_price,
      precision: 2,
      strip_insignificant_zeros: true
    )
  end

  def to_json(*_args)
    to_jbuilder_json
  end

  def url
    api_v1_model_url(slug:)
  end

  def frontend_url
    frontend_model_url(slug:)
  end

  private def broadcast_update
    ActionCable.server.broadcast("models", to_json)
  end

  private def send_new_model_notification
    return if notified? || hidden? || rsi_id.blank?

    Notifications::NewModelJob.perform_async(id)

    ActionCable.server.broadcast("new_model", to_json)
  end

  private def send_on_sale_notification
    return unless on_sale?
    return if created_at > 24.hours.ago

    Notifications::ModelOnSaleJob.perform_async(id)

    ActionCable.server.broadcast("on_sale", to_json)
  end

  private def update_slugs
    super
    self.rsi_slug = generate_slug(rsi_name)
  end

  private def set_last_updated_at
    return if last_updated_at.present?

    self.last_updated_at = Time.zone.now
  end
end
