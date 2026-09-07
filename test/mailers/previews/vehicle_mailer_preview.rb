# frozen_string_literal: true

class VehicleMailerPreview < ActionMailer::Preview
  def on_sale
    VehicleMailer.on_sale(Vehicle.first || sample_vehicle)
  end

  # Previews used to raise "Please Create a Vehicle" against a database with no
  # hangar in it, which is every fresh worktree. A real record is still
  # preferred - it shows the mail with a real ship and its store image - but an
  # unsaved stand-in is enough to render the layout, and the template guards the
  # image with `attached?`, which is false on a new record.
  private def sample_vehicle
    Vehicle.new(
      user: User.new(username: "Commander", email: "commander@example.com"),
      model: Model.new(
        name: "Constellation Andromeda",
        slug: "constellation-andromeda",
        pledge_price: 240,
        manufacturer: Manufacturer.new(name: "Roberts Space Industries")
      )
    )
  end
end
