class ReshapeEquipmentForGameFiles < ActiveRecord::Migration[8.1]
  # The table predates the game-file import and holds rows entered by hand
  # through the old admin forms, some of them carrying item_prices. So the enum
  # columns are converted in place with their values mapped across, and the
  # columns the parser cannot fill are left alone rather than dropped.
  ENUMS = {
    equipment_type: %w[
      undersuit armor weapon tool clothing medical weapon_attachment hacking_tool
    ],
    item_type: %w[
      flightsuit light_armor medium_armor heavy_armor magazine battery pistol
      grenade smg rifle shotgun lmg sniper_rifle special_railgun assault_rifle
      weapon_scope utility rocket_launcher grenade_launcher knife backpack
      light_backpack medium_backpack heavy_backpack
    ],
    weapon_class: %w[energy ballistic frag]
  }.freeze

  def up
    add_column :equipment, :sc_key, :string
    add_column :equipment, :sc_ref, :string
    add_column :equipment, :version, :string
    add_column :equipment, :sub_type, :string

    add_index :equipment, :sc_key, unique: true

    # Strings rather than enums so a class CIG adds in a later build loads
    # instead of raising, the way Commodity#commodity_type does.
    ENUMS.each do |column, values|
      change_column :equipment, column, :string, using: to_name(column, values)
    end

    add_index :equipment, :equipment_type
    add_index :equipment, :item_type

    change_column_default :equipment, :hidden, from: true, to: false
  end

  def down
    remove_index :equipment, :sc_key
    remove_index :equipment, :equipment_type
    remove_index :equipment, :item_type

    remove_column :equipment, :sc_key
    remove_column :equipment, :sc_ref
    remove_column :equipment, :version
    remove_column :equipment, :sub_type

    ENUMS.each do |column, values|
      change_column :equipment, column, :integer, using: to_index(column, values)
    end

    change_column_default :equipment, :hidden, from: false, to: true
  end

  # A row holding an integer outside the old enum keeps nothing rather than a
  # name it never had.
  private def to_name(column, values)
    cases = values.each_with_index.map { |name, index| "WHEN #{index} THEN #{quote(name)}" }

    Arel.sql("CASE #{column} #{cases.join(" ")} END")
  end

  # Anything the game files introduced has no old integer to go back to.
  private def to_index(column, values)
    cases = values.each_with_index.map { |name, index| "WHEN #{quote(name)} THEN #{index}" }

    Arel.sql("CASE #{column} #{cases.join(" ")} END")
  end

  private def quote(value)
    ActiveRecord::Base.connection.quote(value)
  end
end
