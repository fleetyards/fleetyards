# frozen_string_literal: true

require "test_helper"

# `types` is the list of item types a port accepts. It is stored in a string
# column that arrays were written into for years, while the API -- and the
# client generated from it -- have always called it an array of strings.
class HardpointTypesTest < ActiveSupport::TestCase
  setup do
    @model = create(:model)
  end

  private def hardpoint(**attributes)
    Hardpoint.create!(parent: @model, sc_name: "hardpoint_ordnance_bay", source: :game_files, **attributes)
  end

  test "reads an assigned list back as a list" do
    record = hardpoint(types: ["MissileLauncher", "BombLauncher"])

    assert_equal ["MissileLauncher", "BombLauncher"], record.reload.types
  end

  # What every row written before the column was serialised looks like: an
  # array put through `to_s`, which is the same JSON it is read back as. Written
  # through raw SQL because every path Rails offers now casts on the way in.
  test "reads a value written as a bare string back as a list" do
    record = hardpoint
    connection = Hardpoint.connection

    connection.update(<<~SQL.squish)
      UPDATE hardpoints
      SET types = #{connection.quote(["WeaponAttachment"].to_s)}
      WHERE id = #{connection.quote(record.id)}
    SQL

    assert_equal ["WeaponAttachment"], record.reload.types
  end

  test "answers an empty list for a port that declares nothing" do
    assert_equal [], hardpoint.reload.types
  end
end
