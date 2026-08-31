# frozen_string_literal: true

require "discord/commands/model_lookup"

module Discord
  module Commands
    class Loaner < Base
      include ModelLookup

      def call
        query = option("name").to_s.strip
        return message(content: I18n.t("discord.commands.loaner.missing_query")) if query.blank?

        model, answer = resolve_model(query)
        return answer if model.nil?

        loaners = model.loaners.visible.active.ordered_by_name.to_a
        return message(content: I18n.t("discord.commands.loaner.none", ship: model.name)) if loaners.empty?

        message(content: content_for(model, loaners), ephemeral: false)
      end

      private def content_for(model, loaners)
        lines = loaners.map { |loaner| "• [#{loaner.name}](#{model_page_url(loaner)})" }

        [
          I18n.t("discord.commands.loaner.heading",
            ship: model.name,
            url: model_page_url(model),
            count: loaners.size),
          lines.join("\n")
        ].join("\n")
      end
    end
  end
end
