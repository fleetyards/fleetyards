# frozen_string_literal: true

# The guns a fitting carries, counted by size, read off a `FittingTree`: the
# gun in each slot rather than the port, so a slot the fitting empties carries
# nothing and a smaller gun in a larger port counts as the gun it is. A mining
# laser is filed as a gun too, but what it hits is a rock.
class LoadoutWeapons
  def initialize(tree)
    @tree = tree
  end

  # `{"3" => 2, "2" => 4}`, largest first.
  def sizes
    @sizes ||= collect(@tree, Hash.new(0))
      .sort_by { |size, _| -size.to_i }
      .to_h
  end

  def max_size
    sizes.keys.first&.to_i
  end

  private def collect(nodes, counts)
    nodes.each do |node|
      component = node["component"]
      counts[Integer(component["size"]).to_s] += 1 if gun?(component)

      collect(Array(node["hardpoints"]), counts)
    end

    counts
  end

  private def gun?(component)
    component.present? &&
      component["type"] == "WeaponGun" &&
      Integer(component["size"], exception: false).present? &&
      component.dig("type_data", "mining").blank?
  end
end
