module Rsi
  class ManufacturersLoader < ::Rsi::BaseLoader
    def one(manufacturer_data)
      manufacturer = find(manufacturer_data) || create(manufacturer_data)

      # A matrix run calls this once per ship, and the same nineteen
      # manufacturers come round again on every one of them. Without the guard
      # each logo would be fetched a couple of hundred times a sync, since
      # deciding against writing one needs the file in hand.
      return manufacturer unless synced.add?(manufacturer.id)

      manufacturer.update!(update_params(manufacturer, manufacturer_data))

      # Only where an admin has not put their own picture there. The flag is
      # what separates the two, because the attachment alone cannot: a checksum
      # that differs from RSI's file means either that RSI reworked the artwork
      # or that somebody overrode it, and guessing wrong in either direction
      # loses work.
      if fetch_images? && !manufacturer.logo_overridden?
        attach_image_from_url(manufacturer, :logo, logo_url(manufacturer_data))
      end

      manufacturer
    end

    private def synced
      @synced ||= Set.new
    end

    private def find(manufacturer_data)
      manufacturer = Manufacturer.find_by(rsi_id: manufacturer_data["id"])
      manufacturer = Manufacturer.find_by(code: manufacturer_data["code"], rsi_id: nil) if manufacturer.blank?
      manufacturer = Manufacturer.find_by(name: manufacturer_data["name"], rsi_id: nil) if manufacturer.blank?

      manufacturer
    end

    private def create(manufacturer_data)
      Manufacturer.create!(
        name: manufacturer_data["name"],
        rsi_id: manufacturer_data["id"],
        code: manufacturer_data["code"],
        known_for: manufacturer_data["known_for"].presence,
        description: manufacturer_data["description"].presence
      )
    end

    # `rsi_id` is the identity this loader matches on, so it follows the matrix.
    # The rest is filled only where the record has nothing, matching what the
    # sc_data loader does with the same columns: these are editable in admin,
    # and this runs for every ship on every sync rather than only when a model
    # is created, so overwriting would revert a correction on the next pass --
    # and with `nil` wherever the matrix carries no value.
    private def update_params(manufacturer, manufacturer_data)
      params = {rsi_id: manufacturer_data["id"]}

      %w[name code known_for description].each do |attr|
        next if manufacturer.send(attr).present? || manufacturer_data[attr].blank?

        params[attr.to_sym] = manufacturer_data[attr]
      end

      params
    end

    private def logo_url(manufacturer_data)
      media = manufacturer_data["media"]

      return if media.blank?

      media_url(media[0]["source_url"])
    end
  end
end
