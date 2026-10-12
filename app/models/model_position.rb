# frozen_string_literal: true

class ModelPosition < ApplicationRecord
  paginates_per 24

  belongs_to :model
  belongs_to :hardpoint, optional: true

  has_many :mission_slots, dependent: :nullify
  has_many :fleet_event_slots, dependent: :nullify

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

  # The positions a build carries. A generated position is in the build its seat
  # is in, the way the seat itself is -- so live and ptu each see their own,
  # while the rows, which slots point at, are shared. The loadmaster has no
  # seat and shows wherever it exists.
  scope :in_build, ->(source = ::ScData::Source.current.served_for(HardpointBuild)) {
    where(hardpoint_id: nil).or(where(hardpoint_id: Hardpoint.in_build(source).select(:id)))
  }

  # Writes what the build in force says. A position only another build still
  # carries is that build's to keep, so a load adds and updates but never
  # removes on another environment's behalf.
  def self.generate_for_model!(model)
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

    # 3. Loadmaster (if crew > 1 AND model has cargogrid hardpoint)
    if model.crew.to_i > 1 && model.hardpoints.in_build.where(category: :cargogrid).exists?
      positions << {
        name: "Loadmaster",
        position_type: :loadmaster,
        hardpoint_id: nil,
        source: :sc_data,
        position: sort_order
      }
      sort_order += 1
    end

    # Updated in place rather than recreated: slots reference these ids, and a
    # seat an admin already curated is theirs.
    curated_hardpoint_ids = model.model_positions.curated.where.not(hardpoint_id: nil).pluck(:hardpoint_id)
    existing = model.model_positions.sc_data.index_by { |position| generated_key(position) }

    positions.uniq { |attrs| generated_key(attrs) }.each do |attrs|
      next if curated_hardpoint_ids.include?(attrs[:hardpoint_id])

      position = existing.delete(generated_key(attrs)) || model.model_positions.new
      position.update!(attrs)
    end

    existing.each_value { |position| position.destroy! if stale?(model, position) }

    # 4. Gap detection, against what readers get by default.
    total = model.model_positions.in_build(::ScData::Source.default.served_for(HardpointBuild)).count
    needs_curation = total < model.crew.to_i

    model.update_column(:positions_need_curation, needs_curation) if model.positions_need_curation != needs_curation
  end

  # A seat by its port; the loadmaster, which has none, by its type.
  def self.generated_key(position)
    position[:hardpoint_id] || position[:position_type].to_s
  end

  # A seat this build has and did not make a position of, or one no build
  # carries any more. A seat only another build has stays for that build.
  def self.stale?(model, position)
    if position.hardpoint_id.nil?
      return model.crew.to_i <= 1 ||
          !model.hardpoints.where(category: :cargogrid).where(id: HardpointBuild.select(:hardpoint_id)).exists?
    end

    Hardpoint.in_build.exists?(position.hardpoint_id) ||
      !HardpointBuild.exists?(hardpoint_id: position.hardpoint_id)
  end
  private_class_method :generated_key, :stale?

  # `in_build` on all three collectors: a slot the build dropped keeps its row
  # now that the loadout is retired rather than destroyed, and its columns still
  # hold whatever the last load to touch it wrote. Without this, a ship keeps
  # generating positions for a seat it no longer has.
  #
  # The filters stay on the columns rather than the build row because the two are
  # dual-written and agree for any slot still in the build. They have to become
  # joins to the build when the columns go.
  def self.collect_seat_hardpoints(model)
    model.hardpoints.in_build.includes(:component).where(group: :seat).select do |hp|
      hp.sc_name.present? && !hp.sc_name.include?("_access")
    end
  end

  def self.collect_manned_turret_hardpoints(model)
    model.hardpoints.in_build.includes(:component).where.not(component: nil).select do |hp|
      hp.component&.name == "Manned Turret" && hp.component&.component_type == "TurretBase"
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
