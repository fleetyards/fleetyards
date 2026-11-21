# frozen_string_literal: true

module Imports
  # A record of one import of received blueprints from the game logs. The logs
  # are read in the browser and only the chosen blueprints reach the request,
  # so like the buy-back sync the import is written around the work rather than
  # handed to a job.
  #
  # It only adds: a blueprint missing from the logs says nothing, because the
  # game prunes old logs and a reinstall clears them.
  class BlueprintLogImport < ::Import
    belongs_to :user

    def self.record!(user, slugs, unmatched_names = [])
      release_abandoned!(user.id)

      slugs = Array(slugs).map { |slug| slug.to_s.downcase }.uniq
      unmatched_names = Array(unmatched_names).map(&:to_s).compact_blank.uniq

      import = create!(user:, input: {"slugs" => slugs, "unmatched_names" => unmatched_names})
      import.start!

      begin
        output = import.mark_owned(slugs).merge("missing_names" => unmatched_names)
      rescue => error
        import.update_columns(info: error.class.name.demodulize.underscore.humanize)
        import.fail!
        raise
      end

      import.update!(output:)
      import.finish!

      import
    end

    def mark_owned(slugs)
      blueprints = Blueprint.where(slug: slugs).order(:name).pluck(:id, :name)
      marks = UserBlueprint.where(user_id:, blueprint_id: blueprints.map(&:first)).pluck(:blueprint_id, :wanted).to_h

      held, fresh = blueprints.partition { |id, _name| marks[id] == false }
      promoted, added = fresh.partition { |id, _name| marks[id] == true }

      now = Time.current

      UserBlueprint.transaction do
        UserBlueprint.wanted.where(user_id:, blueprint_id: promoted.map(&:first))
          .update_all(wanted: false, created_at: now, updated_at: now)

        if added.any?
          UserBlueprint.insert_all(
            added.map { |id, _name| {user_id:, blueprint_id: id, wanted: false, created_at: now, updated_at: now} },
            unique_by: %i[user_id blueprint_id]
          )
        end
      end

      {
        "imported_names" => (added + promoted).map(&:last).sort,
        "unchanged_names" => held.map(&:last)
      }
    end

    def imported_count
      Array(output&.dig("imported_names")).size
    end

    def unchanged_count
      Array(output&.dig("unchanged_names")).size
    end

    def result_details
      {
        imported: Array(output&.dig("imported_names")),
        unchanged: Array(output&.dig("unchanged_names")),
        missing: Array(output&.dig("missing_names"))
      }.reject { |_key, names| names.empty? }
    end

    def request_cancel!
      false
    end

    def notify_admin
      # a user's own import is no admin news
    end
  end
end
