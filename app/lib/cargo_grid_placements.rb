# frozen_string_literal: true

# Where each cargo grid sits in a ship, as the cargo grid tool places a hold:
# the hold's lowest corner in metres, with x along the hold's length, y across
# it and z up, and a rotation of 270 for a hold turned a quarter about the
# vertical. Read from the ship-view export's grids, which are centres and
# quaternions in the hull holo's frame (glTF, y up).
#
# The tool's unturned hold lies a quarter turn from the export's frame -- the
# Caterpillar's modules, its hand-placed reference, are turned -90 degrees in
# the export and not at all in the tool -- so the whole ship is turned by that
# first.
#
# A grid tilted off the vertical, or turned by anything but a quarter, has no
# placement the tool can draw; the ship then has none at all, since a ship half
# placed by the export and half by the tool's own layout would overlap.
class CargoGridPlacements
  # Radians a grid's turn may stray from a quarter and still count as one.
  TOLERANCE = 0.02

  SHIP_TURN = -Math::PI / 2

  def self.call(grids) = new(grids).call

  def initialize(grids)
    @grids = Array(grids)
  end

  # {hold name => {"offset" => {"x", "y", "z"}, "rotation" => 270 or nil}}
  def call
    placements = @grids.map { |grid| placement(grid) }
    return {} if placements.empty? || placements.any?(&:nil?)

    placements.to_h
  end

  private def placement(grid)
    return unless grid.is_a?(Hash) && grid["name"].is_a?(String)

    dimensions = grid["dimensions"]
    position = grid["position"]
    qx, qy, qz, qw = grid["rotation"]
    return unless [dimensions, position].all? { |value| value.is_a?(Array) && value.size == 3 }
    return if [qx, qy, qz, qw].any?(&:nil?)

    # Tilted: the quaternion turns about more than the vertical.
    return if qx.abs > TOLERANCE || qz.abs > TOLERANCE

    turn = normalize(2 * Math.atan2(qy, qw) + SHIP_TURN)
    quarters = (turn / (Math::PI / 2)).round
    return if (turn - quarters * Math::PI / 2).abs > TOLERANCE

    across = quarters.odd?
    length, width, height = dimensions
    extent = across ? [width, length, height] : [length, width, height]

    # The ship turned by SHIP_TURN about the vertical, then glTF's (x, up, z)
    # read as the tool's (x, y, up).
    x, up, z = position
    sin = Math.sin(SHIP_TURN)
    cos = Math.cos(SHIP_TURN)
    centre = [x * cos + z * sin, -x * sin + z * cos, up]

    offset = %w[x y z].each_with_index.to_h { |axis, index| [axis, (centre[index] - extent[index] / 2.0).round(3)] }

    [hold_name(grid), {"offset" => offset, "rotation" => (across ? 270 : nil)}]
  end

  # The hold a grid on a nested port is loaded as carries its parent port's
  # name in front, as `hardpoint_lift-cargo_grid`.
  private def hold_name(grid)
    parent = grid["parentPort"]
    (parent.is_a?(String) && parent.present?) ? "#{parent}-#{grid["name"]}" : grid["name"]
  end

  private def normalize(angle)
    angle % (2 * Math::PI)
  end
end
