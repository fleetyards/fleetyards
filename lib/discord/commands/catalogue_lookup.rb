# frozen_string_literal: true

module Discord
  module Commands
    # Resolving a catalogue name is shared by /item, /where and /location, and
    # all three have to resolve it the same way -- and the way the site does.
    # Names go through the same resolver as an inline `[*Name*]` in a text, and
    # a suggestion's value is that token, so a picked one always resolves. A
    # name several entries share, which no token can name, is offered per entry
    # by CatalogueVariants.
    module CatalogueLookup
      extend ActiveSupport::Concern

      MAX_CANDIDATES = 5

      # The filter each catalogue page narrows its list by a name with.
      NAME_FILTERS = {
        "component" => "nameCont",
        "equipment" => "nameOrSlugCont",
        "commodity" => "nameCont",
        "blueprint" => "nameCont"
      }.freeze

      # Discord's cap on a choice's name.
      CHOICE_LENGTH = 100

      PAGES = {
        "component" => "/catalogue/components",
        "equipment" => "/catalogue/equipment",
        "commodity" => "/catalogue/commodities",
        "blueprint" => "/catalogue/blueprints",
        "location" => "/locations"
      }.freeze

      # One shape for a name the resolver offers and for one item of a shared
      # name, so both rank and list the same way.
      Candidate = Data.define(:prefix, :name, :slug, :value, :detail)

      # A command offering one catalogue leaves its type off: every choice
      # would carry it, and it spends the 100 characters the detail telling two
      # entries apart needs. A name too long for the rest is what gets cut, as
      # the game key at the end is all that tells two carriers apart.
      def self.choices(query, within:)
        candidates(query, within:).map do |candidate|
          rest = [(type_label(candidate.prefix) unless within.one?), candidate.detail].compact
          budget = CHOICE_LENGTH - rest.sum { |part| part.length + 3 }
          name = (budget >= 10) ? candidate.name.truncate(budget) : candidate.name
          {name: [name, *rest].join(" · "), value: candidate.value}
        end
      end

      # Names that start with the query first, then shorter ones, as the
      # resolver ranks its own.
      def self.candidates(query, within:)
        unique = ::Catalogue::TokenResolver.new.search(query, within:).map do |match|
          Candidate.new(prefix: prefix_for(match), name: match.name, slug: match.slug, value: match.token, detail: nil)
        end
        shared = CatalogueVariants.search(query, within:).map do |variant|
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
        I18n.t("discord.commands.types.#{prefix}")
      end

      class_methods do
        def autocomplete(option, value)
          return [] unless option == "name"

          CatalogueLookup.choices(value, within: self::CATALOGUES)
        end
      end

      # The `name` option resolved within the command's catalogues, answering
      # as #resolve_entry does.
      private def lookup_entry(strings: "item")
        query = option("name").to_s.strip
        return [nil, message(content: I18n.t("discord.commands.#{strings}.missing_query"))] if query.blank?

        resolve_entry(query, within: self.class::CATALOGUES, strings:)
      end

      # The picked variant, the token, then what the suggestions would offer
      # for a name typed by hand. One match answers `[prefix, record]`; anything
      # else answers `[nil, message]` -- a list rather than a guess, or a miss.
      # `strings` names the command's own messages: a miss is "no item" in one
      # command and "no place" in another.
      private def resolve_entry(query, within:, strings: "item")
        variant = CatalogueVariants.find(query, within:)
        return [variant.prefix, variant.record] if variant

        exact = ::Catalogue::TokenResolver.new.resolve([exact_token(query, within)], within:)
        return listed_entry(query, CatalogueLookup.prefix_for(exact.first), exact.first.slug, strings) if exact.one?

        carriers = CatalogueVariants.carriers(query, within:)
        # Per catalogue, as the suggestions count them, so a name they offered
        # entry by entry is listed the same way when typed out.
        return [nil, entry_too_common(query, carriers, strings)] if carriers.values.any? { |count| count > CatalogueVariants::MAX_CARRIERS }

        candidates = CatalogueLookup.candidates(query, within:)
        return [nil, entry_not_found(query, strings)] if candidates.empty?
        return listed_entry(query, candidates.first.prefix, candidates.first.slug, strings) if candidates.one?

        [nil, entry_candidate_list(query, candidates, strings, within)]
      end

      # A bare name resolves only in the item catalogues, so a command offering
      # one other catalogue names it for the reader: "Area18" is the place, not
      # a list beside "Area18 Spaceport".
      private def exact_token(query, within)
        prefix, = ::Catalogue::TokenResolver.parse(query)
        (prefix.nil? && within.one?) ? "#{within.first}:#{query}" : query
      end

      private def listed_entry(query, prefix, slug, strings)
        record = ::Catalogue::TokenResolver.listed(prefix)
          .find_by(CatalogueVariants.model(prefix).table_name => {slug:})
        return [nil, entry_not_found(query, strings)] if record.nil?

        [prefix, record]
      end

      private def entry_not_found(query, strings)
        message(content: I18n.t("discord.commands.#{strings}.not_found", query: Markdown.escape(query)))
      end

      # Too many entries to list or offer, so the catalogue pages narrowed to
      # the name stand in for them. A catalogue with only a few of them still
      # lists each, so the one component among six pieces of equipment is not
      # buried with them.
      private def entry_too_common(query, carriers, strings)
        name = ::Catalogue::TokenResolver.parse(query).last
        lines = carriers.flat_map do |prefix, count|
          if count > CatalogueVariants::MAX_CARRIERS
            url = url_for_path("#{PAGES.fetch(prefix)}/?#{{NAME_FILTERS.fetch(prefix) => name}.to_query}")
            ["• [#{CatalogueLookup.type_label(prefix)}](#{url}) · #{count}"]
          else
            CatalogueVariants.named(prefix, name).map do |record|
              "• #{entry_link(record.name, prefix, record.slug)} · #{CatalogueLookup.type_label(prefix)}"
            end
          end
        end

        message(content: [I18n.t("discord.commands.#{strings}.too_common", query: Markdown.escape(query)), *lines].join("\n"))
      end

      # The type is left off where the command offers one catalogue, as in
      # its suggestions.
      private def entry_candidate_list(query, candidates, strings, within)
        lines = candidates.first(MAX_CANDIDATES).map do |candidate|
          type = CatalogueLookup.type_label(candidate.prefix) unless within.one?
          ["• #{entry_link(candidate.name, candidate.prefix, candidate.slug)}", type, Markdown.escape(candidate.detail.to_s).presence]
            .compact.join(" · ")
        end

        content = [
          I18n.t("discord.commands.#{strings}.ambiguous", query: Markdown.escape(query)),
          lines.join("\n"),
          (I18n.t("discord.commands.#{strings}.more") if candidates.size > MAX_CANDIDATES)
        ].compact.join("\n")

        message(content: content)
      end

      private def entry_link(name, prefix, slug)
        "[#{Markdown.escape(name)}](#{entry_page_url(prefix, slug)})"
      end

      private def entry_page_url(prefix, slug)
        url_for_path("#{PAGES.fetch(prefix)}/#{slug}/")
      end
    end
  end
end
