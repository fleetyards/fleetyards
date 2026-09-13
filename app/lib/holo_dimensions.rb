# frozen_string_literal: true

# The bounding box of a holo export, in whatever unit the file is authored in.
#
# glTF carries `min`/`max` on every POSITION accessor as metadata, so the box
# reads out of the JSON without decoding a single vertex. That matters here:
# the exports are Draco-compressed, and decompressing them would mean a native
# dependency for a number that is already written down.
#
# The node transforms have to be applied. A Blender export puts the scene
# rotation on the node as a quaternion -- the Pisces carries one that swaps two
# axes -- so the accessor's box is stated in a frame the ship does not fly in.
# Scale likewise: some exports carry it on the node, others have it baked into
# the vertices, and only the node half is visible here.
#
# Absolute size is only meaningful if the export was not normalised before it
# left Blender. Measured across the 243 holos on production, `raw extent /
# recorded length` ranges from 0.09 to 356, so today's files give proportions
# and nothing else. An unscaled export would give both.
class HoloDimensions
  # The three world-space extents, named by axis rather than by what they mean.
  #
  # glTF is nominally Y-up with -Z forward, but a Blender export carries its own
  # rotation and the Pisces comes out with its length on x -- the same problem
  # `ScData::Loader::ModelsLoader::AXIS_ORDER` exists for, and the same answer:
  # which axis is the length is not derivable from the file.
  #
  # `sorted` is the honest default. A hull is longer than it is wide and wider
  # than it is tall, which holds for everything except a ship rendered with its
  # wings vertical -- the Reliant. Those need naming, not guessing.
  # `exact` is false when a node's rotation does not map axes onto axes. The box
  # is then an upper bound: transforming the eight corners of an axis-aligned box
  # gives the box around the rotated *box*, and the corners in between belong to
  # no vertex. Settling it would need the vertex data, which is Draco-compressed.
  Result = Data.define(:x, :y, :z, :exact) do
    def to_a
      [x, y, z]
    end

    # Largest first: length, beam, height for a hull that sits the usual way up.
    def sorted
      to_a.sort.reverse
    end

    # What the shape says, independent of how the file was scaled. This is the
    # part that survives a normalised export, and the part that can be checked
    # against a render.
    def proportions
      largest = sorted.first
      return [0.0, 0.0, 0.0] if largest.zero?

      sorted.map { |value| (value / largest).round(4) }
    end
  end

  IDENTITY = [
    1.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0,
    0.0, 0.0, 0.0, 1.0
  ].freeze

  # A binary GLB opens with "glTF" and carries its JSON as the first chunk.
  # Four of the holos on production are GLB, so handing the raw bytes to
  # JSON.parse would raise on exactly those.
  GLB_MAGIC = "glTF"

  def self.from_file(path)
    new(parse(File.binread(path))).call
  end

  def self.from_blob(blob)
    blob.open { |file| new(parse(file.read)).call }
  end

  # A GLB header is 12 bytes, then a chunk header of 8. A file that opens with
  # the magic but stops short would otherwise reach `unpack1` or the slice as
  # nil and come back as NoMethodError or TypeError -- neither of which says
  # "this is not readable glTF" to the caller.
  GLB_HEADER_BYTES = 20

  def self.parse(bytes)
    return JSON.parse(bytes) unless bytes[0, 4] == GLB_MAGIC

    raise JSON::ParserError, "GLB is shorter than its header" if bytes.bytesize < GLB_HEADER_BYTES

    length = bytes[12, 4].unpack1("V")
    chunk = bytes[GLB_HEADER_BYTES, length.to_i]

    raise JSON::ParserError, "GLB names a JSON chunk it does not contain" if chunk.nil? || chunk.bytesize < length.to_i

    JSON.parse(chunk)
  end

  def initialize(gltf)
    @gltf = gltf
    @exact = true
  end

  def call
    corners = scene_corners
    return if corners.empty?

    xs, ys, zs = corners.transpose

    Result.new(
      x: (xs.max - xs.min).round(4),
      y: (ys.max - ys.min).round(4),
      z: (zs.max - zs.min).round(4),
      exact: @exact
    )
  end

  private def scene_corners
    scene = @gltf.dig("scenes", @gltf.fetch("scene", 0)) || {}

    Array(scene["nodes"]).flat_map { |index| node_corners(index, IDENTITY) }
  end

  # Depth-first, carrying the accumulated transform down. A node can hold a mesh
  # and children at once, so both are collected rather than one or the other.
  private def node_corners(index, parent_matrix, seen = [])
    return [] if seen.include?(index)

    node = @gltf.dig("nodes", index)
    return [] if node.nil?

    matrix = multiply(parent_matrix, local_matrix(node))
    @exact &&= axis_aligned?(matrix) unless node["mesh"].nil?

    corners = []
    corners += mesh_corners(node["mesh"]).map { |corner| transform(matrix, corner) } if node["mesh"]
    Array(node["children"]).each do |child|
      corners += node_corners(child, matrix, seen + [index])
    end

    corners
  end

  # The eight corners of each primitive's own box, so a rotation cannot be
  # applied to two opposite points and mistaken for the rotated box -- it is the
  # corners in between that end up furthest out.
  private def mesh_corners(mesh_index)
    mesh = @gltf.dig("meshes", mesh_index)
    return [] if mesh.nil?

    Array(mesh["primitives"]).flat_map do |primitive|
      position = primitive.dig("attributes", "POSITION")
      next [] if position.nil?

      accessor = @gltf.dig("accessors", position)
      min = accessor&.dig("min")
      max = accessor&.dig("max")
      next [] unless min.is_a?(Array) && max.is_a?(Array) && min.size == 3 && max.size == 3

      [min[0], max[0]].product([min[1], max[1]], [min[2], max[2]])
    end
  end

  private def local_matrix(node)
    # A node states either a full matrix or a translation/rotation/scale triple,
    # never both.
    return column_major_to_row(node["matrix"]) if node["matrix"].is_a?(Array)

    translation = node["translation"] || [0.0, 0.0, 0.0]
    rotation = node["rotation"] || [0.0, 0.0, 0.0, 1.0]
    scale = node["scale"] || [1.0, 1.0, 1.0]

    multiply(translation_matrix(translation), multiply(rotation_matrix(rotation), scale_matrix(scale)))
  end

  private def column_major_to_row(values)
    (0..3).flat_map { |row| (0..3).map { |column| values[(column * 4) + row].to_f } }
  end

  private def translation_matrix(vector)
    [
      1.0, 0.0, 0.0, vector[0].to_f,
      0.0, 1.0, 0.0, vector[1].to_f,
      0.0, 0.0, 1.0, vector[2].to_f,
      0.0, 0.0, 0.0, 1.0
    ]
  end

  private def scale_matrix(vector)
    [
      vector[0].to_f, 0.0, 0.0, 0.0,
      0.0, vector[1].to_f, 0.0, 0.0,
      0.0, 0.0, vector[2].to_f, 0.0,
      0.0, 0.0, 0.0, 1.0
    ]
  end

  private def rotation_matrix(quaternion)
    x, y, z, w = quaternion.map(&:to_f)

    [
      1 - (2 * ((y * y) + (z * z))), 2 * ((x * y) - (z * w)), 2 * ((x * z) + (y * w)), 0.0,
      2 * ((x * y) + (z * w)), 1 - (2 * ((x * x) + (z * z))), 2 * ((y * z) - (x * w)), 0.0,
      2 * ((x * z) - (y * w)), 2 * ((y * z) + (x * w)), 1 - (2 * ((x * x) + (y * y))), 0.0,
      0.0, 0.0, 0.0, 1.0
    ]
  end

  private def multiply(left, right)
    (0..3).flat_map do |row|
      (0..3).map do |column|
        (0..3).sum { |k| left[(row * 4) + k] * right[(k * 4) + column] }
      end
    end
  end

  # Whether the linear part maps each axis onto an axis, give or take a sign.
  # Then the transformed corners are the real extrema and the box is exact; a
  # rotation at any other angle makes it an upper bound.
  private def axis_aligned?(matrix, epsilon = 1e-6)
    rows = (0..2).map { |row| (0..2).map { |column| matrix[(row * 4) + column].abs } }

    rows.all? { |row| row.count { |value| value > epsilon } == 1 } &&
      (0..2).all? { |column| rows.count { |row| row[column] > epsilon } == 1 }
  end

  private def transform(matrix, point)
    x, y, z = point.map(&:to_f)

    [
      (matrix[0] * x) + (matrix[1] * y) + (matrix[2] * z) + matrix[3],
      (matrix[4] * x) + (matrix[5] * y) + (matrix[6] * z) + matrix[7],
      (matrix[8] * x) + (matrix[9] * y) + (matrix[10] * z) + matrix[11]
    ]
  end
end
