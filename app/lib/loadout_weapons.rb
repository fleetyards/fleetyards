# frozen_string_literal: true

# The guns a fitting carries, counted by size: what sits in each slot the
# player fits, the stock part where the fitting leaves one in, down through
# mounts and turrets to the guns themselves.
#
# Read off the gun rather than the port, so a slot the fitting empties carries
# nothing and a smaller gun in a larger port counts as the gun it is. A mining
# laser is filed as a gun too, but what it hits is a rock.
class LoadoutWeapons
  def initialize(slots)
    @slots = slots
  end

  # `{"3" => 2, "2" => 4}`, largest first.
  def sizes
    @sizes ||= @slots.fittable_hull
      .each_with_object(Hash.new(0)) { |slot, counts| collect(slot, counts) }
      .sort_by { |size, _| -size.to_i }
      .to_h
  end

  def max_size
    sizes.keys.first&.to_i
  end

  private def collect(slot, counts)
    content = contents(slot)
    counts[content.size.to_s] += 1 if gun?(content)

    @slots.children(slot).each { |child| collect(child, counts) }
  end

  private def contents(slot)
    @slots.fitted(slot.path) || (slot.stock unless slot.module_slot? || @slots.emptied?(slot.path))
  end

  private def gun?(content)
    content.is_a?(Component) &&
      content.component_type == "WeaponGun" &&
      Integer(content.size, exception: false).present? &&
      content.type_data.to_h["mining"].blank?
  end
end
