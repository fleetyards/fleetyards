# frozen_string_literal: true

# == Schema Information
#
# Table name: model_positions
#
#  id            :uuid             not null, primary key
#  name          :string           not null
#  position      :integer          default(0), not null
#  position_type :integer          not null
#  source        :integer          default("sc_data"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  hardpoint_id  :uuid
#  model_id      :uuid             not null
#
# Indexes
#
#  index_model_positions_on_model_id                   (model_id)
#  index_model_positions_on_model_id_and_hardpoint_id  (model_id,hardpoint_id) UNIQUE WHERE (hardpoint_id IS NOT NULL)
#
# Foreign Keys
#
#  fk_rails_...  (hardpoint_id => hardpoints.id) ON DELETE => nullify
#  fk_rails_...  (model_id => models.id)
#
class ModelPosition < ApplicationRecord
  belongs_to :model
  belongs_to :hardpoint, optional: true

  enum :position_type, {
    pilot: 0, copilot: 1, turret_gunner: 2, engineer: 3,
    gunner: 4, loadmaster: 5, passenger: 6, operator: 7, custom: 99
  }

  enum :source, {sc_data: 0, curated: 1}

  validates :name, presence: true
  validates :position_type, presence: true
  validates :source, presence: true
  validates :hardpoint_id, uniqueness: {scope: :model_id}, allow_nil: true

  def self.ransackable_attributes(auth_object = nil)
    %w[id model_id name position_type source position created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[model hardpoint]
  end

  def self.generate_for_model!(model)
    # Remove old auto-generated positions, keep curated ones
    model.model_positions.sc_data.destroy_all

    positions = []
    sort_order = 0

    # 1. Seat hardpoints (group: :seat, excluding _access)
    seat_hardpoints = collect_seat_hardpoints(model)
    seat_hardpoints.each do |hp|
      next if hp.sc_name&.include?("_access")

      type = infer_position_type(hp)
      positions << {
        name: derive_name(hp),
        position_type: type,
        hardpoint_id: hp.id,
        source: :sc_data,
        position: sort_order
      }
      sort_order += 1
    end

    # 2. Manned turrets without nested seat children
    manned_turret_hardpoints = collect_manned_turret_hardpoints(model)
    manned_turret_hardpoints.each do |hp|
      next if seat_hardpoints.any? { |shp| shp.parent_id == hp.id || shp.sc_name&.include?(hp.sc_name.to_s) }

      positions << {
        name: derive_name_for_turret(hp),
        position_type: :turret_gunner,
        hardpoint_id: hp.id,
        source: :sc_data,
        position: sort_order
      }
      sort_order += 1
    end

    # 3. Loadmaster (if max_crew > 1 AND model has cargogrid hardpoint)
    if model.max_crew.to_i > 1 && model.hardpoints.where(category: :cargogrid).exists?
      positions << {
        name: "Loadmaster",
        position_type: :loadmaster,
        hardpoint_id: nil,
        source: :sc_data,
        position: sort_order
      }
      sort_order += 1
    end

    # Bulk create
    positions.each do |attrs|
      model.model_positions.create!(attrs)
    end

    # 4. Gap detection
    auto_count = model.model_positions.sc_data.count
    curated_count = model.model_positions.curated.count
    total = auto_count + curated_count
    needs_curation = total < model.max_crew.to_i

    model.update_column(:positions_need_curation, needs_curation) if model.positions_need_curation != needs_curation
  end

  def self.collect_seat_hardpoints(model)
    model.hardpoints.includes(:component).where(group: :seat).select do |hp|
      hp.sc_name.present? && !hp.sc_name.include?("_access")
    end
  end

  def self.collect_manned_turret_hardpoints(model)
    model.hardpoints.includes(:component).where.not(component: nil).select do |hp|
      hp.component&.item_type == "manned_turrets" ||
        (hp.component&.name == "Manned Turret" && hp.component&.component_type == "TurretBase")
    end
  end

  def self.infer_position_type(hardpoint)
    sc_name = hardpoint.sc_name.to_s

    return :pilot if sc_name.include?("_pilot")
    return :copilot if sc_name.include?("_copilot")
    return :engineer if sc_name.include?("engineer_console") || sc_name.start_with?("hardpoint_engineering")
    return :turret_gunner if sc_name.include?("turret_console")
    return :operator if sc_name.include?("_seat_")

    :operator
  end

  def self.derive_name(hardpoint)
    sc_name = hardpoint.sc_name.to_s

    return "Pilot" if sc_name.include?("_pilot")
    return "Copilot" if sc_name.include?("_copilot")

    if sc_name.include?("engineer_console")
      return sc_name.sub(/.*?engineer_console/, "Engineer Console")
          .sub(/^_/, "").tr("_", " ").strip.titleize
    end

    if sc_name.include?("turret_console")
      return sc_name.sub(/.*turret_console/, "Turret Console")
          .sub(/^_/, "").tr("_", " ").strip.titleize
    end

    if sc_name.start_with?("hardpoint_engineering")
      return sc_name.sub(/hardpoint_engineering(screen)?_?/, "")
          .tr("_", " ").strip.titleize.presence || "Engineer"
    end

    sc_name.sub(/^hardpoint_(seat_)?/, "").tr("_", " ").strip.titleize
  end

  def self.derive_name_for_turret(hardpoint)
    sc_name = hardpoint.sc_name.to_s

    if sc_name.start_with?("turret_")
      return sc_name.sub("turret_", "Turret ").tr("_", " ").strip.titleize
    end

    sc_name.sub(/^hardpoint_/, "").tr("_", " ").strip.titleize
  end
end
