module ScData
  module Loader
    class ManufacturersLoader < ::ScData::Loader::BaseLoader
      def all
        load_items("manufacturers").each do |manufacturer_data|
          name = manufacturer_data["name"]
          ref = manufacturer_data["ref"]
          code = manufacturer_data["code"]

          # Read here as well as in the parser, because live and ptu share these
          # rows: a tree parsed before the parser learned this would otherwise put
          # the question mark back with its next load.
          icon = manufacturer_data["icon"]
          icon = nil if ::ScData::Parser::ManufacturersParser.placeholder_icon?(icon, code)

          # Matched on the slug the name would produce rather than on the name
          # itself, because the slug is what the rest of the site identifies a
          # manufacturer by -- so two names that reach the same one are the same
          # manufacturer as far as anything downstream can tell. An exact repeat
          # slugs the same way, and so do the variants the export mixes in:
          # "Basilisk " and "GYSON INC." would have missed a by-name lookup and
          # minted a second row that collides with the first.
          slug = Manufacturer.slug_for(name)

          # Guarded because `sc_ref: nil` matches every curated row, and a record
          # would overwrite whichever came first.
          manufacturer = Manufacturer.find_by(sc_ref: ref) if ref.present?
          manufacturer = Manufacturer.find_by(code:, sc_ref: nil) if manufacturer.blank? && code.present?
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
            # curated one is better than the game's. The icon path has no
            # curated counterpart -- it points into the export -- so it follows
            # it, but is never blanked: the codes that share a manufacturer do
            # not all name a logo -- ROO has none where SASU has Sakura Sun's
            # -- so following the export unconditionally would drop the picture
            # depending on which record was loaded last.
            update_params = {}
            update_params[:icon_path] = icon if icon.present?

            # Only claimed while free. A row matched on slug can already hold a
            # different ref -- the export gives Sakura Sun both ROO and SASU --
            # and overwriting would leave the two codes trading the column on
            # every import.
            if manufacturer.sc_ref.blank? && ref.present?
              update_params[:sc_ref] = ref
            end

            if manufacturer.description.blank? && manufacturer_data["description"].present?
              update_params[:description] = manufacturer_data["description"]
            end

            if manufacturer.code.blank? && code.present?
              update_params[:code] = code
            end

            apply(manufacturer, update_params)

            # Onto `icon`, never onto `logo`: the logo is curated -- an admin
            # uploads it, and RSI's own artwork lands there -- and writing the
            # export into it replaced somebody's picture on every load. Its own
            # attachment follows the export freely, so a build that reworks the
            # art still lands.
            #
            # Unless an admin has put their own picture there. The flag is what
            # separates the two, because the attachment alone cannot: a
            # checksum that differs from the parsed file means either that the
            # export changed or that somebody overrode it, and guessing wrong
            # in either direction loses work.
            attach_icon(manufacturer, :icon, icon) unless manufacturer.icon_overridden?

            manufacturer
          elsif name.present?
            created = apply(Manufacturer.new, {
              sc_ref: ref,
              name:,
              code:,
              description: manufacturer_data["description"],
              icon_path: icon
            })

            attach_icon(created, :icon, icon)

            created
          end
        end
      end
    end
  end
end
