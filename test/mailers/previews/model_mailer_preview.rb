# frozen_string_literal: true

class ModelMailerPreview < ActionMailer::Preview
  def notify_new
    ModelMailer.notify_new("foo@bar.de", Model.first || sample_model)
  end

  # See VehicleMailerPreview for why there is a fallback: a real record shows the
  # mail with a real store image, an unsaved one still renders everything else.
  private def sample_model
    Model.new(
      name: "Constellation Andromeda",
      slug: "constellation-andromeda",
      manufacturer: Manufacturer.new(name: "Roberts Space Industries")
    )
  end
end
