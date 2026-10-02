# frozen_string_literal: true

module Shops
  # What a shop's things are, finer than their kind: a Casaba Outlet sells
  # clothing, Platinum Bay ship weapons and coolers. "Equipment 78" only
  # repeats what every shop of equipment says.
  #
  # A ship, paint or commodity has no finer kind, so it carries none and the
  # page names it by its kind.
  class Categories
    Category = Struct.new(:item_type, :key, :label, :count)

    def self.for(items)
      items.group_by { |item| [item.class.name, key_of(item)] }
        .map { |(item_type, key), group| Category.new(item_type, key, label_of(group.first, key), group.size) }
        .sort_by { |category| [-category.count, category.label.to_s] }
    end

    def self.key_of(item)
      case item
      when Equipment then item.equipment_type.presence
      when Component then item.category.presence
      end
    end

    def self.label_of(item, key)
      return if key.nil?

      case item
      when Equipment then item.equipment_type_label
      when Component then I18n.t("filter.component.category.items.#{key}", default: key.humanize)
      end
    end
  end
end
