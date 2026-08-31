# frozen_string_literal: true

module Discord
  module Commands
    # Resolving a ship name is shared by /ship, /loaner and /compare, and all
    # three have to resolve it the *same* way as the website -- a bot that finds
    # a different ship than the ship list for the same words is a bug report
    # nobody can reproduce.
    module ModelLookup
      MAX_CANDIDATES = 5

      # `search_cont` is the site's own matcher: a ransack alias over name, slug
      # and manufacturer slug (`Model#ransack_alias :search`).
      #
      # `visible.active` is the public catalogue scope from ModelsController --
      # without it the bot answers with unreleased and hidden models the website
      # never shows.
      private def find_models(query)
        scope = Model.visible.active.includes(:manufacturer)

        exact = scope.where("lower(name) = :q OR lower(slug) = :q", q: query.downcase).limit(1).to_a
        return exact if exact.any?

        scope.ransack(search_cont: query).result.ordered_by_name.limit(MAX_CANDIDATES + 1).to_a
      end

      # One match answers; several list rather than guess.
      private def resolve_model(query)
        candidates = find_models(query)

        return [nil, message(content: I18n.t("discord.commands.ship.not_found", query: query))] if candidates.empty?
        return [candidates.first, nil] if candidates.one?

        [nil, candidate_list(query, candidates)]
      end

      private def candidate_list(query, candidates)
        shown = candidates.first(MAX_CANDIDATES)
        lines = shown.map { |model| "• [#{model.name}](#{model_page_url(model)})" }

        content = [
          I18n.t("discord.commands.ship.ambiguous", query: query, count: shown.size),
          lines.join("\n"),
          (I18n.t("discord.commands.ship.more") if candidates.size > MAX_CANDIDATES)
        ].compact.join("\n")

        message(content: content)
      end

      private def model_page_url(model)
        url_for_path("/ships/#{model.slug}")
      end
    end
  end
end
