class SetCargoHoldOffsets < ActiveRecord::Migration[7.2]
  def up
    set_hull_a_offsets
    set_hull_c_offsets
    set_caterpillar_offsets
    set_carrack_offsets
  end

  def down
    CargoHold.where.not(offset_x: nil).or(
      CargoHold.where.not(offset_y: nil)
    ).or(
      CargoHold.where.not(offset_z: nil)
    ).update_all(offset_x: nil, offset_y: nil, offset_z: nil, rotation: nil)
  end

  private

  def set_hull_a_offsets
    model = Model.find_by(slug: "hull-a")
    return unless model

    # Hull-A: 4 holds in 2 columns, 2 stacked vertically per column
    # Each hold: 2.5x5.0x2.5 (grid 2x4x2). Offsets in meters.
    # Vertical gap of 1.25m (1 SCU) between stacked holds, spine gap of 3.75m
    offsets = [
      {position: 0, x: 0, y: 0, z: 0},        # left bottom
      {position: 1, x: 0, y: 0, z: 3.75},      # left top (2.5+1.25 gap)
      {position: 2, x: 6.25, y: 0, z: 0},      # right bottom (2.5+3.75 spine)
      {position: 3, x: 6.25, y: 0, z: 3.75}    # right top
    ]

    apply_offsets(model, offsets)
  end

  def set_hull_c_offsets
    model = Model.find_by(slug: "hull-c")
    return unless model

    # Hull-C: 16 holds in + cross pattern, 2 sections (fore/aft). Offsets in meters.
    # Large (10x10x7.5), Small (5x10x7.5). Rotated (r=90): Large 7.5w×10h, Small 7.5w×5h
    # Cross with 1.25m gap at each spine edge:
    # Left arm x=0..15, gap, vert band x=16.25..23.75, gap, right arm x=25..40
    # Bottom arm z=0..15, gap, side band z=16.25..23.75, gap, top arm z=25..40
    offsets = [
      # Section 1 (y=0)
      {position: 7, x: 0, y: 0, z: 16.25},               # left small (outer, x:0..5)
      {position: 0, x: 5, y: 0, z: 16.25},                # left large (inner, x:5..15)
      {position: 1, x: 25, y: 0, z: 16.25},               # right large (inner, x:25..35)
      {position: 8, x: 35, y: 0, z: 16.25},               # right small (outer, x:35..40)
      {position: 10, x: 16.25, y: 0, z: 0, r: 90},       # bottom small (rotated, z:0..5)
      {position: 3, x: 16.25, y: 0, z: 5, r: 90},        # bottom large (rotated, z:5..15)
      {position: 2, x: 16.25, y: 0, z: 25, r: 90},       # top large (rotated, z:25..35)
      {position: 9, x: 16.25, y: 0, z: 35, r: 90},       # top small (rotated, z:35..40)
      # Section 2 (y=11.25, 10+1.25 gap)
      {position: 11, x: 0, y: 11.25, z: 16.25},          # left small (outer)
      {position: 4, x: 5, y: 11.25, z: 16.25},            # left large (inner)
      {position: 5, x: 25, y: 11.25, z: 16.25},           # right large (inner)
      {position: 12, x: 35, y: 11.25, z: 16.25},          # right small (outer)
      {position: 15, x: 16.25, y: 11.25, z: 0, r: 90},   # bottom small (rotated)
      {position: 14, x: 16.25, y: 11.25, z: 5, r: 90},   # bottom large (rotated)
      {position: 6, x: 16.25, y: 11.25, z: 25, r: 90},   # top large (rotated)
      {position: 13, x: 16.25, y: 11.25, z: 35, r: 90}   # top small (rotated)
    ]

    apply_offsets(model, offsets)
  end

  def set_caterpillar_offsets
    model = Model.find_by(slug: "caterpillar")
    return unless model

    # Caterpillar nose: 2 holds, rotation=270 (Z-axis, swaps x↔y)
    # nose (6.25x5.0x3.75) rotated -> 5.0 wide, nose_access (6.25x2.5x2.5) rotated -> 2.5 wide
    # Offsets in meters.
    offsets = [
      {position: 0, x: 0, y: 0, z: 0, r: 270},      # nose main
      {position: 1, x: 5.0, y: 0, z: 0, r: 270}     # nose access (beside main, flush: 0+5.0)
    ]

    apply_offsets(model, offsets)
  end

  def set_carrack_offsets
    model = Model.find_by(slug: "carrack")
    return unless model

    # Carrack: 3 pods (front/mid/rear), each with left(5x5x5) + right(5x5x5) + mid(5x3.75x2.5)
    # Left and right spaced along y, mid between them rotated 270. Offsets in meters.
    offsets = [
      # Front pod
      {position: 0, x: 0, y: 0, z: 0},                  # front left
      {position: 1, x: 0, y: 12.5, z: 0},                # front right
      {position: 2, x: 0, y: 6.25, z: 0, r: 270},        # front mid (between, rotated)
      # Mid pod
      {position: 3, x: 0, y: 0, z: 0},                   # mid left
      {position: 4, x: 0, y: 12.5, z: 0},                 # mid right
      {position: 5, x: 0, y: 6.25, z: 0, r: 270},        # mid mid (between, rotated)
      # Rear pod
      {position: 6, x: 0, y: 0, z: 0},                   # rear left
      {position: 7, x: 0, y: 12.5, z: 0},                 # rear right
      {position: 8, x: 0, y: 6.25, z: 0, r: 270}         # rear mid (between, rotated)
    ]

    apply_offsets(model, offsets)
  end

  def apply_offsets(model, offsets)
    offsets.each do |o|
      hold = model.cargo_holds_db.find_by(position: o[:position])
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
