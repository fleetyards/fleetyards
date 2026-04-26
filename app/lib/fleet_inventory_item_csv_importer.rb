# frozen_string_literal: true

class FleetInventoryItemCsvImporter
  VALID_CATEGORIES = %w[commodity component weapon equipment ammunition consumable other].freeze
  VALID_UNITS = %w[scu units].freeze

  attr_reader :fleet_inventory, :file, :user, :imported, :errors

  def initialize(fleet_inventory, file, user)
    @fleet_inventory = fleet_inventory
    @file = file
    @user = user
    @imported = 0
    @errors = []
  end

  def call
    rows = parse_csv

    return {imported: 0, errors: @errors} if rows.blank?

    ActiveRecord::Base.transaction do
      rows.each_with_index do |row, index|
        import_row(row, index + 2) # +2 for header row + 1-based indexing
      end
    end

    {imported: @imported, errors: @errors}
  rescue CSV::MalformedCSVError => e
    @errors << {row: 0, message: "Invalid CSV format: #{e.message}"}
    {imported: 0, errors: @errors}
  end

  private

  def parse_csv
    content = file.read.force_encoding("UTF-8")
    CSV.parse(content, headers: true, skip_blanks: true)
  rescue => e
    @errors << {row: 0, message: "Could not parse CSV: #{e.message}"}
    nil
  end

  def import_row(row, row_number)
    name = row["name"]&.strip
    if name.blank?
      @errors << {row: row_number, message: "Name is required"}
      return
    end

    category = row["category"]&.strip&.downcase || "commodity"
    unless VALID_CATEGORIES.include?(category)
      @errors << {row: row_number, message: "Invalid category: #{category}"}
      return
    end

    unit = row["unit"]&.strip&.downcase || "scu"
    unless VALID_UNITS.include?(unit)
      @errors << {row: row_number, message: "Invalid unit: #{unit}"}
      return
    end

    quantity = row["quantity"]&.strip&.to_f || 0

    item = fleet_inventory.fleet_inventory_items.new(
      name: name,
      category: category,
      quantity: quantity,
      unit: unit,
      notes: row["notes"]&.strip,
      added_by: user.id
    )

    if item.save
      @imported += 1
    else
      @errors << {row: row_number, message: item.errors.full_messages.join(", ")}
    end
  end
end
