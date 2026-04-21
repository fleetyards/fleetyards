# frozen_string_literal: true

module Maintenance
  class ApplyCargoHoldOffsetsTask < MaintenanceTasks::Task
    OFFSET_CONFIGS = {
      "misc-hull-a" => [
        # Hull-A: 4 holds in 2 columns, 2 stacked vertically per column
        # Each hold: 2.5x5.0x2.5. Vertical gap of 1.25m, spine gap of 3.75m
        {position: 0, x: 0, y: 0, z: 0},
        {position: 1, x: 0, y: 0, z: 3.75},
        {position: 2, x: 6.25, y: 0, z: 0},
        {position: 3, x: 6.25, y: 0, z: 3.75}
      ],
      "misc-hull-b" => [
        # Hull-B: 16 holds in diamond pattern, 2 sections (front/rear)
        # Each hold: 2.5x10.0x2.5. Diamond stagger: 1 SCU inset on narrow rows
        # Gaps: 0.5 SCU within quadrant, 2 SCU vertical / 5 SCU horizontal between quadrants
        # Section 1 — front (y=0)
        {position: 1, x: 0.0, y: 0.0, z: 8.125},             # top front left lower (wide)
        {position: 2, x: 1.25, y: 0.0, z: 11.25},            # top front left upper (narrow)
        {position: 5, x: 1.25, y: 0.0, z: 0.0},              # bottom front left lower (narrow)
        {position: 6, x: 0.0, y: 0.0, z: 3.125},             # bottom front left upper (wide)
        {position: 7, x: 7.5, y: 0.0, z: 0.0},               # bottom front right lower (narrow)
        {position: 8, x: 8.75, y: 0.0, z: 3.125},            # bottom front right upper (wide)
        {position: 12, x: 8.75, y: 0.0, z: 8.125},           # top front right lower (wide)
        {position: 13, x: 7.5, y: 0.0, z: 11.25},            # top front right upper (narrow)
        # Section 2 — rear (y=11.25)
        {position: 0, x: 8.75, y: 11.25, z: 3.125},          # bottom rear right upper (wide)
        {position: 3, x: 0.0, y: 11.25, z: 8.125},           # top rear left lower (wide)
        {position: 4, x: 7.5, y: 11.25, z: 11.25},           # top rear right upper (narrow)
        {position: 9, x: 1.25, y: 11.25, z: 0.0},            # bottom rear left lower (narrow)
        {position: 10, x: 0.0, y: 11.25, z: 3.125},          # bottom rear left upper (wide)
        {position: 11, x: 7.5, y: 11.25, z: 0.0},            # bottom rear right lower (narrow)
        {position: 14, x: 1.25, y: 11.25, z: 11.25},         # top rear left upper (narrow)
        {position: 15, x: 8.75, y: 11.25, z: 8.125}          # top rear right lower (wide)
      ],
      "misc-hull-c" => [
        # Hull-C: 16 holds in + cross pattern, 2 sections (fore/aft)
        # Positions are stable after sort_by(&:sc_name) fix in extract_cargo_holds
        # Section 1 (y=0)
        {position: 0, x: 25.0, y: 0.0, z: 16.25},              # 1B right large
        {position: 1, x: 16.25, y: 0.0, z: 5.0, r: 90},       # 1D bottom large
        {position: 6, x: 0.0, y: 0.0, z: 16.25},               # 1A left small
        {position: 7, x: 35.0, y: 0.0, z: 16.25},              # 1B right small
        {position: 8, x: 16.25, y: 0.0, z: 0.0, r: 90},       # 1D bottom small
        {position: 13, x: 16.25, y: 0.0, z: 25.0, r: 90},     # 1C top large
        {position: 14, x: 5.0, y: 0.0, z: 16.25},              # 1A left large
        {position: 15, x: 16.25, y: 0.0, z: 35.0, r: 90},     # 1C top small
        # Section 2 (y=11.25)
        {position: 2, x: 5.0, y: 11.25, z: 16.25},             # 2A left large
        {position: 3, x: 25.0, y: 11.25, z: 16.25},            # 2B right large
        {position: 4, x: 16.25, y: 11.25, z: 25.0, r: 90},    # 2C top large
        {position: 5, x: 16.25, y: 11.25, z: 5.0, r: 90},     # 2D bottom large
        {position: 9, x: 0.0, y: 11.25, z: 16.25},             # 2A left small
        {position: 10, x: 35.0, y: 11.25, z: 16.25},           # 2B right small
        {position: 11, x: 16.25, y: 11.25, z: 35.0, r: 90},   # 2C top small
        {position: 12, x: 16.25, y: 11.25, z: 0.0, r: 90}     # 2D bottom small
      ],
      "drak-caterpillar" => [
        # Caterpillar nose: rotation=270 (swaps x↔y), side by side
        {position: 0, x: 0, y: 0, z: 0, r: 270},
        {position: 1, x: 5.0, y: 0, z: 0, r: 270}
      ],
      "anvl-carrack" => [
        # Carrack: 3 pods (front/mid/rear), left + right + mid(rotated 270)
        # Front pod
        {position: 0, x: 0, y: 0, z: 0},
        {position: 1, x: 0, y: 12.5, z: 0},
        {position: 8, x: 0, y: 6.25, z: 0, r: 270},
        # Mid pod
        {position: 2, x: 0, y: 0, z: 0},
        {position: 3, x: 0, y: 12.5, z: 0},
        {position: 4, x: 0, y: 6.25, z: 0, r: 270},
        # Rear pod
        {position: 5, x: 0, y: 0, z: 0},
        {position: 6, x: 0, y: 12.5, z: 0},
        {position: 7, x: 0, y: 6.25, z: 0, r: 270}
      ]
    }.freeze

    MODULE_OFFSET_CONFIGS = {
      "front-cargo-module" => [
        # Retaliator front cargo module: main grid + 2 side grids
        {position: 0, x: 0, y: 0, z: 0},
        {position: 1, x: 0.63, y: 6.5, z: 0.0},
        {position: 2, x: 0.63, y: -1.5, z: 0.0}
      ]
    }.freeze

    ALL_SLUGS = (OFFSET_CONFIGS.keys + MODULE_OFFSET_CONFIGS.keys).freeze

    attribute :slug, :string
    validates :slug, inclusion: {in: ALL_SLUGS, message: "must be one of: #{ALL_SLUGS.join(", ")}"}

    no_collection

    def process
      if MODULE_OFFSET_CONFIGS.key?(slug)
        parent = ModelModule.find_by!(slug: slug)
        offsets = MODULE_OFFSET_CONFIGS.fetch(slug)
      else
        parent = Model.find_by!(slug: slug)
        offsets = OFFSET_CONFIGS.fetch(slug)
      end

      offsets.each do |o|
        hold = parent.cargo_holds_db.find_by(position: o[:position])
        next unless hold

        hold.update!(
          offset_x: o[:x],
          offset_y: o[:y],
          offset_z: o[:z],
          rotation: o[:r]
        )
      end
    end
  end
end
