# frozen_string_literal: true

module Discord
  module Commands
    # The caller's own hangar, privately.
    #
    # Deliberately not `/hangar` with the username filled in: that command
    # exists to show a *stranger's* hangar and enforces `public_hangar?` plus the
    # per-ship `public` flag. For the owner both layers fall away, and reusing
    # them would silently omit exactly the ships someone is most likely checking
    # on -- the ones they never made public.
    class MyHangar < Base
      include LinkedAccount
      include VehicleCounts

      def call
        user = linked_user
        return message(content: account_not_linked) if user.nil?

        # `visible` drops the duplicate loaner rows the loaner setup marks
        # hidden; nothing a user can edit writes that flag, so this is about not
        # counting the same loaner twice rather than about privacy.
        counts = model_counts(user.vehicles.purchased.visible)
        return message(content: I18n.t("discord.commands.my_hangar.empty", url: url_for_path("/hangar"))) if counts.empty?

        message(content: content_for(counts))
      end

      private def content_for(counts)
        [
          I18n.t("discord.commands.my_hangar.heading",
            url: url_for_path("/hangar"),
            count: counts.values.sum,
            models: counts.size),
          count_lines(counts).join("\n"),
          (I18n.t("discord.commands.my_hangar.more", count: omitted_count(counts)) if omitted_count(counts).positive?)
        ].compact.join("\n")
      end
    end
  end
end
