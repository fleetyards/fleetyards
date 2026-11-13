# frozen_string_literal: true

require "test_helper"

class PaintsFromGameFilesTest < ActiveSupport::TestCase
  setup do
    ModelPaint.delete_all
    Component.where(category: "paints").delete_all
  end

  private def ship(name, tag, sc_key: nil)
    model = create(:model, name:, sc_key:)
    create(:hardpoint, parent: model, source: :game_files, sc_name: "hardpoint_paint", port_tags: [tag], required_tags: [tag])
    model
  end

  private def livery(name, tag)
    create(:component, category: "paints", name:, tags: [tag], required_tags: [tag])
  end

  private def create_paints
    PaintsFromGameFiles.new.run
  end

  test "#run creates a paint RSI has not listed, linked to its livery" do
    galaxy = ship("Galaxy", "Paint_Galaxy")
    component = livery("Galaxy Starwalker Livery", "Paint_Galaxy")

    create_paints

    paint = galaxy.paints.sole
    assert_equal "Starwalker", paint.name
    assert_equal component, paint.component
    assert_not paint.hidden
  end

  # The name says "Galaxy", but the tags are what the game fits by.
  test "#run puts a livery only on the ships whose paint port takes it" do
    galaxy = ship("Galaxy", "Paint_Galaxy")
    other = ship("Galaxy Lookalike", "Paint_Other")
    livery("Galaxy Starwalker Livery", "Paint_Galaxy")

    create_paints

    assert_equal ["Starwalker"], galaxy.paints.pluck(:name)
    assert_empty other.paints
  end

  test "#run gives every variant sharing the port tag the livery" do
    tractor = ship("MPUV Tractor", "Paint_MPUV")
    cargo = ship("MPUV Cargo", "Paint_MPUV")
    livery("MPUV Hazard Livery", "Paint_MPUV")

    create_paints

    assert_equal ["Hazard"], tractor.paints.pluck(:name)
    assert_equal ["Hazard"], cargo.paints.pluck(:name)
  end

  test "#run leaves a ship that already has the paint alone" do
    galaxy = ship("Galaxy", "Paint_Galaxy")
    create(:model_paint, model: galaxy, name: "Protector")
    livery("Galaxy Protector Livery", "Paint_Galaxy")

    create_paints

    assert_equal ["Protector"], galaxy.paints.pluck(:name)
  end

  test "#run reads a store name the game spells with a year or a camo as the same paint" do
    model = ship("400i", "Paint_400i")
    create(:model_paint, model:, name: "Auspicious Red Dog")
    create(:model_paint, model:, name: "Frostbite")
    livery("400i 2954 Auspicious Red Dog Livery", "Paint_400i")
    livery("400i Frostbite Camo Livery", "Paint_400i")

    create_paints

    assert_equal ["Auspicious Red Dog", "Frostbite"], model.paints.order(:name).pluck(:name)
  end

  test "#run reads a store name that goes on past the game's as the same paint" do
    model = ship("C2 Hercules", "Paint_Starlifter", sc_key: "crus_starlifter_c2")
    create(:model_paint, model:, name: "Draco Gold")
    create(:model_paint, model:, name: "Dracones")
    livery("Hercules Starlifter Draco Livery", "Paint_Starlifter")
    livery("Hercules Starlifter Dracon Livery", "Paint_Starlifter")

    create_paints

    assert_equal ["Dracon", "Dracones", "Draco Gold"].sort, model.paints.pluck(:name).sort
  end

  test "#run puts a Best in Show year where the store does" do
    model = ship("F8C Lightning", "Paint_F8")
    livery("F8C Lightning 2954 Best in Show Livery", "Paint_F8")

    create_paints

    assert_equal ["Best in Show 2954"], model.paints.pluck(:name)
  end

  test "#run reads either order of a Best in Show year as the same paint" do
    model = ship("F8C Lightning", "Paint_F8")
    create(:model_paint, model:, name: "2954 Best in Show")
    livery("F8C Lightning 2954 Best in Show Livery", "Paint_F8")

    create_paints

    assert_equal ["2954 Best in Show"], model.paints.pluck(:name)
  end

  test "#run strips the ship the way the game names it" do
    pisces = ship("C8R Pisces", "Paint_Pisces")
    hercules = ship("C2 Hercules", "Paint_Starlifter", sc_key: "crus_starlifter_c2")
    hundred = ship("100i", "Paint_100")
    livery("C8 Pisces Kepler Livery", "Paint_Pisces")
    livery("Hercules Starlifter Draco Livery", "Paint_Starlifter")
    livery("100 Series Foundation Fest Livery", "Paint_100")

    create_paints

    assert_equal ["Kepler"], pisces.paints.pluck(:name)
    assert_equal ["Draco"], hercules.paints.pluck(:name)
    assert_equal ["Foundation Festival"], hundred.paints.pluck(:name)
  end

  test "#run guesses no name for a livery that does not open with the ship" do
    galaxy = ship("Galaxy", "Paint_Galaxy")
    livery("Starwalker Livery", "Paint_Galaxy")

    create_paints

    assert_empty galaxy.paints
  end

  test "#run fits nothing to a livery asking for no tag" do
    galaxy = ship("Galaxy", "Paint_Galaxy")
    create(:component, category: "paints", name: "Galaxy Starwalker Livery", tags: [], required_tags: [])

    create_paints

    assert_empty galaxy.paints
  end

  test "#run creates nothing from a livery the build dropped" do
    galaxy = ship("Galaxy", "Paint_Galaxy")
    create(:component, :without_build, category: "paints", name: "Galaxy Starwalker Livery",
      tags: ["Paint_Galaxy"], required_tags: ["Paint_Galaxy"])

    create_paints

    assert_empty galaxy.paints
  end

  test "#run is idempotent" do
    galaxy = ship("Galaxy", "Paint_Galaxy")
    livery("Galaxy Starwalker Livery", "Paint_Galaxy")

    create_paints
    create_paints

    assert_equal 1, galaxy.paints.count
  end
end
