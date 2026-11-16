# frozen_string_literal: true

# Where each cargo grid of a ship or module sits, as its hull export says:
# the grid's centre in metres and its turn as a quaternion, in the hull holo's
# frame (glTF, y up), and its size along its own axes -- the values the
# loadout preview serves its grids with.
#
# The cargo grid tool lays holds out on a floor, so it can only draw a grid
# that stands upright and is turned by a quarter about the vertical. A parent
# with any other grid is placed not at all, since one laid out half by the
# export and half by the tool would overlap.
class CargoGridPlacements
  # Radians a grid's turn may stray from a quarter and still count as one.
  TOLERANCE = 0.02

  def self.call(grids) = new(grids).call

  def initialize(grids)
    @grids = Array(grids)
  end

  # {hold name => {"position" => [x, y, z], "rotation" => [x, y, z, w], "size" => [x, y, z]}}
  def call
    placements = @grids.map { |grid| placement(grid) }
    return {} if placements.empty? || placements.any?(&:nil?)

    # A grid on a nested port answers to its own name too, unless a grid at
    # the top carries that name: those come last, so theirs stands.
    names = placements.sort_by { |grid, _| nested_name(grid) ? 0 : 1 }.to_h { |grid, placed| [grid["name"], placed] }
    placements.each { |grid, placed| names[nested_name(grid)] = placed if nested_name(grid) }
    names
  end

  private def placement(grid)
    return unless grid.is_a?(Hash) && grid["name"].is_a?(String)

    position = grid["position"]
    rotation = grid["rotation"]
    return unless numbers?(position, 3) && numbers?(rotation, 4)
    return unless upright_quarter?(*rotation)

    size = grid["size"]
    [grid, {"position" => position, "rotation" => rotation, "size" => (size if numbers?(size, 3))}]
  end

  # Tilted when the quaternion turns about more than the vertical; otherwise
  # its turn about the vertical has to land on a quarter.
  private def upright_quarter?(qx, qy, qz, qw)
    return false if qx.abs > TOLERANCE || qz.abs > TOLERANCE

    turn = 2 * Math.atan2(qy, qw)
    quarter = Math::PI / 2

    (turn - (turn / quarter).round * quarter).abs <= TOLERANCE
  end

  private def numbers?(value, size)
    value.is_a?(Array) && value.size == size && value.all?(Numeric)
  end

  # A grid on a port of a fitted part is loaded as a hold named with the
  # part's port in front, as `hardpoint_lift-cargo_grid`; one deeper in the
  # ship's own loadout keeps its port's name alone. The export does not say
  # which, so a nested grid answers to both.
  private def nested_name(grid)
    parent = grid["parentPort"]
    "#{parent}-#{grid["name"]}" if parent.is_a?(String) && parent.present?
  end
end
