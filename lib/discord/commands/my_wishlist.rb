# frozen_string_literal: true

module Discord
  module Commands
    # The caller's own wishlist, privately.
    #
    # Named `/mywishlist` rather than `/wishlist` on purpose: visibility is fixed
    # per command at the deferred acknowledgement, so one name cannot answer
    # privately about yourself and publicly about someone else. Leaving
    # `/wishlist` free keeps the public lookup that mirrors `/hangar` possible.
    class MyWishlist < Base
      include LinkedAccount
      include VehicleCounts

      def call
        user = linked_user
        return message(content: account_not_linked) if user.nil?

        counts = model_counts(user.vehicles.wanted.visible)
        return message(content: I18n.t("discord.commands.my_wishlist.empty", url: url_for_path("/hangar/wishlist/"))) if counts.empty?

        message(content: content_for(counts))
      end

      private def content_for(counts)
        [
          I18n.t("discord.commands.my_wishlist.heading",
            url: url_for_path("/hangar/wishlist/"),
            count: counts.values.sum,
            models: counts.size),
          count_lines(counts).join("\n"),
          (I18n.t("discord.commands.my_wishlist.more", count: omitted_count(counts)) if omitted_count(counts).positive?)
        ].compact.join("\n")
      end
    end
  end
end
