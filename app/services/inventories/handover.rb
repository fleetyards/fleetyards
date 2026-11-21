# frozen_string_literal: true

module Inventories
  # Moves part of a lot from one holder to another inside the same fleet
  # inventory: a withdrawal from the giver's share and a deposit into the
  # taker's, both or neither.
  #
  # Not a transfer. The stock never leaves the inventory, so there is no one to
  # ask and nothing to hold in escrow -- the point is to put funds with
  # whoever is online before the one carrying them logs off.
  class Handover
    include ActiveModel::Model

    attr_reader :quantity, :from_holder_id, :to_holder_id

    def initialize(inventory:, stock_item:, actor:, quantity:, from_holder_id: nil, to_holder_id: nil,
      quality: nil, crafted_blueprint_id: nil, crafted_qualities: nil)
      @inventory = inventory
      @stock_item = stock_item
      @actor = actor
      @quantity = quantity.to_d
      @from_holder_id = from_holder_id.presence
      @to_holder_id = to_holder_id.presence
      @quality = quality
      @crafted_blueprint_id = crafted_blueprint_id.presence
      @crafted_qualities = crafted_qualities.presence
    end

    def call
      if from_holder_id == to_holder_id
        errors.add(:to_holder_id, :same_holder, message: "must be someone other than the current holder")
        return false
      end

      ::ActiveRecord::Base.transaction do
        write(:withdrawal, from_holder_id)
        write(:deposit, to_holder_id)
      end

      errors.empty?
    end

    private def write(entry_type, holder_id)
      entry = @inventory.fleet_inventory_items.new(**lot_attributes, entry_type:, holder_id:,
        quantity:, handover: true, added_by: @actor.id)

      return if entry.save

      errors.merge!(entry.errors)
      raise ::ActiveRecord::Rollback
    end

    private def lot_attributes
      {
        name: @stock_item.name,
        category: @stock_item.category,
        unit: @stock_item.unit,
        quality: @quality,
        crafted_blueprint_id: @crafted_blueprint_id,
        crafted_qualities: @crafted_qualities,
        item_type: source_entry&.item_type,
        item_id: source_entry&.item_id
      }
    end

    # A crafted lot names its own part; anything else borrows the position's
    # catalogue link, the way a transfer line does.
    private def source_entry
      @source_entry ||= if @crafted_blueprint_id
        @inventory.fleet_inventory_items
          .where(fleet_inventory_position_id: @stock_item.position_id, crafted_blueprint_id: @crafted_blueprint_id)
          .where.not(item_id: nil)
          .first
      else
        @stock_item.reference_entry
      end
    end
  end
end
