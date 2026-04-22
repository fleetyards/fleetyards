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
        # Each hold: 2.5x10.0x2.5. Diamond stagger: 2 SCU inset on narrow rows
        # Zero gap within quadrants, 1.25m gap between bottom/top quadrants
        # Positions match sort_by(&:sc_name) ordering (bottom before top, front before rear, left before right)
        # Section 1 — front (y=0)
        {position: 0, x: 2.5, y: 0.0, z: 0.0},               # bottom front left lower (narrow)
        {position: 1, x: 0.0, y: 0.0, z: 2.5},               # bottom front left upper (wide)
        {position: 2, x: 6.25, y: 0.0, z: 0.0},              # bottom front right lower (narrow)
        {position: 3, x: 8.75, y: 0.0, z: 2.5},              # bottom front right upper (wide)
        {position: 8, x: 0.0, y: 0.0, z: 6.25},              # top front left lower (wide)
        {position: 9, x: 2.5, y: 0.0, z: 8.75},              # top front left upper (narrow)
        {position: 10, x: 8.75, y: 0.0, z: 6.25},            # top front right lower (wide)
        {position: 11, x: 6.25, y: 0.0, z: 8.75},            # top front right upper (narrow)
        # Section 2 — rear (y=11.25)
        {position: 4, x: 2.5, y: 11.25, z: 0.0},             # bottom rear left lower (narrow)
        {position: 5, x: 0.0, y: 11.25, z: 2.5},             # bottom rear left upper (wide)
        {position: 6, x: 6.25, y: 11.25, z: 0.0},            # bottom rear right lower (narrow)
        {position: 7, x: 8.75, y: 11.25, z: 2.5},            # bottom rear right upper (wide)
        {position: 12, x: 0.0, y: 11.25, z: 6.25},           # top rear left lower (wide)
        {position: 13, x: 2.5, y: 11.25, z: 8.75},           # top rear left upper (narrow)
        {position: 14, x: 8.75, y: 11.25, z: 6.25},          # top rear right lower (wide)
        {position: 15, x: 6.25, y: 11.25, z: 8.75}           # top rear right upper (narrow)
      ],
      "misc-hull-c" => [
        # Hull-C: 16 holds in + cross pattern, 2 sections (fore/aft)
        # Positions match sort_by(&:sc_name) ordering:
        #   0-7: inner (large) struts 1A,1B,1C,1D,2A,2B,2C,2D
        #   8-15: outer (small) struts 1A,1B,1C,1D,2A,2B,2C,2D
        # Section 1 inner (y=0)
        {position: 0, x: 5.0, y: 0.0, z: 16.25},              # 1A left large
        {position: 1, x: 25.0, y: 0.0, z: 16.25},             # 1B right large
        {position: 2, x: 16.25, y: 0.0, z: 25.0, r: 90},     # 1C top large
        {position: 3, x: 16.25, y: 0.0, z: 5.0, r: 90},      # 1D bottom large
        # Section 2 inner (y=11.25)
        {position: 4, x: 5.0, y: 11.25, z: 16.25},            # 2A left large
        {position: 5, x: 25.0, y: 11.25, z: 16.25},           # 2B right large
        {position: 6, x: 16.25, y: 11.25, z: 25.0, r: 90},   # 2C top large
        {position: 7, x: 16.25, y: 11.25, z: 5.0, r: 90},    # 2D bottom large
        # Section 1 outer (y=0)
        {position: 8, x: 0.0, y: 0.0, z: 16.25},              # 1A left small
        {position: 9, x: 35.0, y: 0.0, z: 16.25},             # 1B right small
        {position: 10, x: 16.25, y: 0.0, z: 35.0, r: 90},    # 1C top small
        {position: 11, x: 16.25, y: 0.0, z: 0.0, r: 90},     # 1D bottom small
        # Section 2 outer (y=11.25)
        {position: 12, x: 0.0, y: 11.25, z: 16.25},           # 2A left small
        {position: 13, x: 35.0, y: 11.25, z: 16.25},          # 2B right small
        {position: 14, x: 16.25, y: 11.25, z: 35.0, r: 90},  # 2C top small
        {position: 15, x: 16.25, y: 11.25, z: 0.0, r: 90}    # 2D bottom small
      ],
      "drak-caterpillar" => [
        # Caterpillar: 4 modules (each: main + ladder + walkway) + nose (2 grids)
        # Positions match sort_by(&:sc_name): module_01(0-2), ..., module_04(9-11), nose(12-13)
        # Module 01
        {position: 0, x: 1.25, y: 1.25, z: 0},
        {position: 1, x: 0.0, y: 1.25, z: 0},
        {position: 2, x: 1.25, y: 0.0, z: 0},
        # Module 02
        {position: 3, x: 1.25, y: 1.25, z: 0},
        {position: 4, x: 0.0, y: 1.25, z: 0},
        {position: 5, x: 1.25, y: 0.0, z: 0},
        # Module 03
        {position: 6, x: 1.25, y: 1.25, z: 0},
        {position: 7, x: 0.0, y: 1.25, z: 0},
        {position: 8, x: 1.25, y: 0.0, z: 0},
        # Module 04
        {position: 9, x: 1.25, y: 1.25, z: 0},
        {position: 10, x: 0.0, y: 1.25, z: 0},
        {position: 11, x: 1.25, y: 0.0, z: 0},
        # Nose: rotation=270 (swaps x↔y), side by side
        {position: 12, x: 2.5, y: 0, z: 0, r: 270},
        {position: 13, x: 0, y: 0, z: 0, r: 270}
      ],
      "anvl-carrack" => [
        # Carrack: 3 pods (front/mid/rear), each with left + mid + right (all rotated 270)
        # Positions match sort_by(&:sc_name): front_left, front_mid, front_right, mid_left, ...
        # Front pod
        {position: 0, x: 0.0, y: -6.25, z: 0.0, r: 270},
        {position: 1, x: 0.0, y: 0, z: 0, r: 270},
        {position: 2, x: 0.0, y: 6.25, z: 0.0, r: 270},
        # Mid pod
        {position: 3, x: 0.0, y: -6.25, z: 0.0, r: 270},
        {position: 4, x: 0.0, y: 0, z: 0, r: 270},
        {position: 5, x: 0.0, y: 6.25, z: 0.0, r: 270},
        # Rear pod
        {position: 6, x: 0.0, y: -6.25, z: 0.0, r: 270},
        {position: 7, x: 0.0, y: 0, z: 0, r: 270},
        {position: 8, x: 0.0, y: 6.25, z: 0.0, r: 270}
      ]
    }.freeze

    MODULE_OFFSET_CONFIGS = {
      "front-cargo-module" => [
        # Retaliator front cargo module: grid_a (side), grid_b (main), grid_c (side)
        # Positions match sort_by(&:sc_name): a=0, b=1, c=2
        {position: 0, x: 0.63, y: -1.5, z: 0.0},
        {position: 1, x: 0, y: 0, z: 0},
        {position: 2, x: 0.63, y: 6.5, z: 0.0}
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
