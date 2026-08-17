# frozen_string_literal: true

# Contract for controllers that act on a single inventory. The including
# controller says *which* inventory it is; the action bodies live in
# InventoryScoped::ItemActions and InventoryScoped::StockActions and are
# identical whether the holder reached the inventory through their hangar or
# through one of their ships.
module InventoryScoped
  extend ActiveSupport::Concern

  # The inventory a read acts on. Holders that provision lazily may hand back an
  # unsaved record here, so nothing but `provisioned_inventory` may assume an id.
  private def inventory
    raise NotImplementedError, "#{self.class.name} must define #inventory"
  end

  # The inventory a write acts on, brought into existence if it is not there yet.
  private def provisioned_inventory
    inventory
  end

  private def inventory_policy
    raise NotImplementedError, "#{self.class.name} must define #inventory_policy"
  end

  private def inventory_item_policy
    raise NotImplementedError, "#{self.class.name} must define #inventory_item_policy"
  end

  private def validation_error_scope
    raise NotImplementedError, "#{self.class.name} must define #validation_error_scope"
  end
end
