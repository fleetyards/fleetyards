# frozen_string_literal: true

module Discord
  module Commands
    # Resolving an item name is shared by /item and /where, and both have to
    # resolve it the same way -- and the way the site does. Names go through the
    # same resolver as an inline `[*Name*]` in a text, and a suggestion's value
    # is that token, so a picked one always resolves. A name several items
    # share, which no token can name, is offered per item by ItemVariants.
    module ItemLookup
      MAX_CANDIDATES = 5

      # The filter each catalogue page narrows its list by a name with.
      NAME_FILTERS = {
        "component" => "nameCont",
        "equipment" => "nameOrSlugCont",
        "commodity" => "nameCont",
        "blueprint" => "nameCont"
      }.freeze

      PAGES = {
        "component" => "components",
        "equipment" => "equipment",
        "commodity" => "commodities",
        "blueprint" => "blueprints"
      }.freeze

      # One shape for a name the resolver offers and for one item of a shared
      # name, so both rank and list the same way.
      Candidate = Data.define(:prefix, :name, :slug, :value, :detail)

      def self.choices(query, within:)
        candidates(query, within:).map do |candidate|
          {name: [candidate.name, type_label(candidate.prefix), candidate.detail].compact.join(" · "), value: candidate.value}
        end
      end

      # Names that start with the query first, then shorter ones, as the
      # resolver ranks its own.
      def self.candidates(query, within:)
        unique = ::Catalogue::TokenResolver.new.search(query, within:).map do |match|
          Candidate.new(prefix: prefix_for(match), name: match.name, slug: match.slug, value: match.token, detail: nil)
        end
        shared = ItemVariants.search(query, within:).map do |variant|
          Candidate.new(prefix: variant.prefix, name: variant.name, slug: variant.slug, value: variant.value, detail: variant.detail)
        end

        lowered = ::Catalogue::TokenResolver.parse(query).last.downcase
        (unique + shared).sort_by do |candidate|
          [candidate.name.downcase.start_with?(lowered) ? 0 : 1, candidate.name.length, candidate.name.downcase, candidate.detail.to_s]
        end
      end

      def self.prefix_for(match)
        ::Catalogue::TokenResolver::CATALOGUES.key(match.type.constantize)
      end

      def self.type_label(prefix)
        I18n.t("discord.commands.item.types.#{prefix}")
      end

      # The picked variant, the token, then what the suggestions would offer
      # for a name typed by hand. One match answers `[prefix, record]`; anything
      # else answers `[nil, message]` -- a list rather than a guess, or a miss.
      private def resolve_item(query, within:)
        variant = ItemVariants.find(query, within:)
        return [variant.prefix, variant.record] if variant

        exact = ::Catalogue::TokenResolver.new.resolve([query], within:)
        return listed_item(query, ItemLookup.prefix_for(exact.first), exact.first.slug) if exact.one?

        carriers = ItemVariants.carriers(query, within:)
        # Per catalogue, as the suggestions count them, so a name they offered
        # item by item is listed the same way when typed out.
        return [nil, item_too_common(query, carriers)] if carriers.values.any? { |count| count > ItemVariants::MAX_CARRIERS }

        candidates = ItemLookup.candidates(query, within:)
        return [nil, item_not_found(query)] if candidates.empty?
        return listed_item(query, candidates.first.prefix, candidates.first.slug) if candidates.one?

        [nil, item_candidate_list(query, candidates)]
      end

      private def listed_item(query, prefix, slug)
        record = ::Catalogue::TokenResolver.listed(prefix)
          .find_by(ItemVariants.model(prefix).table_name => {slug:})
        return [nil, item_not_found(query)] if record.nil?

        [prefix, record]
      end

      private def item_not_found(query)
        message(content: I18n.t("discord.commands.item.not_found", query: Markdown.escape(query)))
      end

      # Too many items to list or offer, so the catalogue pages narrowed to
      # the name stand in for them. A catalogue with only a few of them still
      # lists each, so the one component among six pieces of equipment is not
      # buried with them.
      private def item_too_common(query, carriers)
        name = ::Catalogue::TokenResolver.parse(query).last
        lines = carriers.flat_map do |prefix, count|
          if count > ItemVariants::MAX_CARRIERS
            url = url_for_path("/catalogue/#{PAGES.fetch(prefix)}/?#{{NAME_FILTERS.fetch(prefix) => name}.to_query}")
            ["• [#{ItemLookup.type_label(prefix)}](#{url}) · #{count}"]
          else
            ItemVariants.named(prefix, name).map do |record|
              "• #{item_link(record.name, prefix, record.slug)} · #{ItemLookup.type_label(prefix)}"
            end
          end
        end

        message(content: [I18n.t("discord.commands.item.too_common", query: Markdown.escape(query)), *lines].join("\n"))
      end

      private def item_candidate_list(query, candidates)
        lines = candidates.first(MAX_CANDIDATES).map do |candidate|
          ["• #{item_link(candidate.name, candidate.prefix, candidate.slug)}", ItemLookup.type_label(candidate.prefix), candidate.detail]
            .compact.join(" · ")
        end

        content = [
          I18n.t("discord.commands.item.ambiguous", query: Markdown.escape(query)),
          lines.join("\n"),
          (I18n.t("discord.commands.item.more") if candidates.size > MAX_CANDIDATES)
        ].compact.join("\n")

        message(content: content)
      end

      private def item_link(name, prefix, slug)
        "[#{Markdown.escape(name)}](#{item_page_url(prefix, slug)})"
      end

      private def item_page_url(prefix, slug)
        url_for_path("/catalogue/#{PAGES.fetch(prefix)}/#{slug}/")
      end
    end
  end
end
