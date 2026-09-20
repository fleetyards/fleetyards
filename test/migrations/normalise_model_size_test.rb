# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20260920110000_normalise_model_size.rb")

# The column is validated now, so every row that starts out wrong has to be
# written past the model to get there -- which is how it got wrong in the first
# place: the loader's `update_all`-shaped copy of the RSI matrix.
class NormaliseModelSizeTest < ActiveSupport::TestCase
  # Raw SQL, because normalisation is part of the attribute's type: it reaches
  # `update_column` and `update_all` as well as the writer. Nothing going
  # through ActiveRecord can produce the rows this migration is here to fix.
  def model_with_size(value, **attributes)
    model = create(:model, size: nil, **attributes)
    Model.connection.exec_update(
      "UPDATE models SET size = $1 WHERE id = $2", "test", [value, model.id]
    )
    model
  end

  def normalise
    NormaliseModelSize.new.up
  end

  test "a ground vehicle with no size becomes one" do
    ursa = create(:model, size: nil, ground: true)

    normalise

    assert_equal "vehicle", ursa.reload.size
  end

  test "a ship with no size is left alone" do
    raptor = create(:model, size: nil, ground: false)

    normalise

    assert_nil raptor.reload.size
  end

  test "an empty size is cleared rather than called a vehicle" do
    beacon = model_with_size("", ground: true)

    normalise

    assert_nil beacon.reload.size
  end

  test "the matrix's capitalisation is folded into the class it meant" do
    reclaimer = model_with_size("Capital")
    stingray = model_with_size("Small")

    normalise

    assert_equal "capital", reclaimer.reload.size
    assert_equal "small", stingray.reload.size
  end

  test "a word the catalogue does not know is reported, not guessed at" do
    oddity = model_with_size("enormous")

    normalise

    assert_equal "enormous", oddity.reload.size
  end
end
