module ScData
  module Loader
    class ManufacturersLoader < ::ScData::Loader::BaseLoader
      def all
        load_items("manufacturers").each do |manufacturer_data|
          name = manufacturer_data["name"]

          # Matched on the slug the name would produce rather than on the name
          # itself, because the slug is what the rest of the site identifies a
          # manufacturer by -- so two names that reach the same one are the same
          # manufacturer as far as anything downstream can tell. An exact repeat
          # slugs the same way, and so do the variants the export mixes in:
          # "Basilisk " and "GYSON INC." would have missed a by-name lookup and
          # minted a second row that collides with the first.
          slug = Manufacturer.slug_for(name)

          manufacturer = Manufacturer.find_by(sc_ref: manufacturer_data["ref"])
          manufacturer = Manufacturer.find_by(code: manufacturer_data["code"], sc_ref: nil) if manufacturer.blank?
          manufacturer = Manufacturer.find_by(slug:, sc_ref: nil) if manufacturer.blank? && slug.present?

          # Last resort, and the one that stops the table growing a second row
          # for a manufacturer it already has: the lookups above only match a
          # row that has no sc_ref yet, so once every row carries one, a record
          # arriving under a new ref used to be created afresh. The export ships
          # several codes per company -- ROO and SASU are both Sakura Sun -- so
          # a slug that is already taken means the same manufacturer, and the
          # extra ref is dropped rather than duplicated.
          manufacturer = Manufacturer.find_by(slug:) if manufacturer.blank? && slug.present?

          if manufacturer.present?
            # The description and the code are left alone once set, because a
            # curated one is better than the game's. The icon has no curated
            # counterpart -- it is a path into the export -- so it follows it,
            # but is never blanked: the codes that share a manufacturer do not
            # all name a logo -- ROO has none where SASU has Sakura Sun's -- so
            # following the export unconditionally would drop the picture
            # depending on which record was loaded last.
            update_params = {}
            update_params[:icon] = manufacturer_data["icon"] if manufacturer_data["icon"].present?

            # Only claimed while free. A row matched on slug can already hold a
            # different ref -- the export gives Sakura Sun both ROO and SASU --
            # and overwriting would leave the two codes trading the column on
            # every import.
            if manufacturer.sc_ref.blank? && manufacturer_data["ref"].present?
              update_params[:sc_ref] = manufacturer_data["ref"]
            end

            if manufacturer.description.blank? && manufacturer_data["description"].present?
              update_params[:description] = manufacturer_data["description"]
            end

            if manufacturer.code.blank? && manufacturer_data["code"].present?
              update_params[:code] = manufacturer_data["code"]
            end

            manufacturer.update!(update_params)

            attach_icon(manufacturer, :logo, manufacturer_data["icon"])

            manufacturer
          elsif name.present?
            created = Manufacturer.create!(
              sc_ref: manufacturer_data["ref"],
              name:,
              code: manufacturer_data["code"],
              description: manufacturer_data["description"],
              icon: manufacturer_data["icon"]
            )

            attach_icon(created, :logo, manufacturer_data["icon"])

            created
          end
        end
      end
    end
  end
end
