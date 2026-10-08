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
        "blueprint" => "nameCont",
        "location" => "nameCont"
      }.freeze

      # What is left of a name when the detail after it runs long.
      MIN_NAME_LENGTH = 10

      PAGES = {
        "component" => "/catalogue/components",
        "equipment" => "/catalogue/equipment",
        "commodity" => "/catalogue/commodities",
        "blueprint" => "/catalogue/blueprints",
        "location" => "/locations"
      }.freeze

      # A catalogue whose filtered list lives apart from its entry pages: the
      # locations index is the starmap, the places list is beside it.
      LIST_PAGES = {
        "location" => "/locations/places"
      }.freeze

      # One shape for a name the resolver offers and for one item of a shared
      # name, so both rank and list the same way.
      Candidate = Data.define(:prefix, :name, :slug, :value, :detail)

      # A command offering one catalogue leaves its type off: every choice
      # would carry it, and it spends the 100 characters the detail telling two
      # entries apart needs.
      def self.choices(query, within:)
        candidates(query, within:).map do |candidate|
          rest = [listed_type(candidate.prefix, within), candidate.detail].compact
          {name: choice_name(candidate.name, rest), value: candidate.value}
        end
      end

      # The game key at the end is all that tells two carriers of a name apart,
      # so the name is what gets cut -- and past a stub of it, the front of the
      # detail.
      def self.choice_name(name, rest)
        max = Discord::MessageLength::CHOICE_MAX
        suffix = rest.map { |part| " · #{part}" }.join
        room = max - [MIN_NAME_LENGTH, Discord::MessageLength.of(name)].min
        suffix = "…#{Discord::MessageLength.truncate(suffix.reverse, room - 1).reverse}" unless Discord::MessageLength.fits?(suffix, room)

        room = max - Discord::MessageLength.of(suffix)
        Discord::MessageLength.truncate(name, room, omission: "…") + suffix
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

      # The type beside an entry, which a command offering one catalogue
      # leaves off.
      def self.listed_type(prefix, within)
        type_label(prefix) unless within.one?
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

        candidates = CatalogueLookup.candidates(query, within:)
        carriers = CatalogueVariants.carriers(query, within:)
        # Per catalogue, as the suggestions count them, so a name they offered
        # entry by entry is listed the same way when typed out. What else
        # matches is listed below it rather than hidden by it.
        if carriers.values.any? { |count| count > CatalogueVariants::MAX_CARRIERS }
          name = ::Catalogue::TokenResolver.parse(query).last
          others = candidates.reject { |candidate| carriers.key?(candidate.prefix) && candidate.name.casecmp?(name) }
          return [nil, entry_too_common(query, carriers, strings, within, others)]
        end

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
      # buried with them. A command offering one catalogue names the page by
      # the name rather than by a type every line would share.
      private def entry_too_common(query, carriers, strings, within, others)
        name = ::Catalogue::TokenResolver.parse(query).last
        lines = carriers.flat_map do |prefix, count|
          if count > CatalogueVariants::MAX_CARRIERS
            url = url_for_path("#{LIST_PAGES.fetch(prefix) { PAGES.fetch(prefix) }}/?#{{NAME_FILTERS.fetch(prefix) => name}.to_query}")
            ["• [#{CatalogueLookup.listed_type(prefix, within) || Markdown.escape(name)}](#{url}) · #{count}"]
          else
            CatalogueVariants.variants_named(prefix, name).map do |variant|
              candidate_line(Candidate.new(prefix:, name: variant.name, slug: variant.slug, value: variant.value, detail: variant.detail), within)
            end
          end
        end
        shown = others.first(MAX_CANDIDATES)

        fit_message(I18n.t("discord.commands.#{strings}.too_common", query: Markdown.escape(query)),
          lines + shown.map { |candidate| candidate_line(candidate, within) },
          more: I18n.t("discord.commands.#{strings}.more"), hidden: others.size - shown.size)
      end

      private def entry_candidate_list(query, candidates, strings, within)
        shown = candidates.first(MAX_CANDIDATES)

        fit_message(I18n.t("discord.commands.#{strings}.ambiguous", query: Markdown.escape(query)),
          shown.map { |candidate| candidate_line(candidate, within) },
          more: I18n.t("discord.commands.#{strings}.more"), hidden: candidates.size - shown.size)
      end

      # Long names and their links can run a list past what a message holds,
      # so whole lines are dropped from the end until it fits -- never cut in
      # the middle of a link -- and the `more` line says some were left out.
      private def fit_message(heading, lines, more:, hidden: 0)
        content = ->(shown) do
          [heading, *shown, (more if hidden.positive? || shown.size < lines.size)].compact.join("\n")
        end
        shown = lines.dup
        shown.pop while shown.size > 1 && !MessageLength.fits?(content.call(shown))

        message(content: MessageLength.truncate(content.call(shown)))
      end

      private def candidate_line(candidate, within)
        ["• #{entry_link(candidate.name, candidate.prefix, candidate.slug)}", CatalogueLookup.listed_type(candidate.prefix, within), Markdown.escape(candidate.detail.to_s).presence]
          .compact.join(" · ")
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
