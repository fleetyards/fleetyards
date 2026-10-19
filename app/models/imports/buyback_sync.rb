# frozen_string_literal: true

module Imports
  # A record of one buy-back list sync. The sync itself runs inside the request,
  # so the import is written around it rather than handed to a job: it starts,
  # holds what was read, and ends with what the sync did.
  class BuybackSync < ::Import
    belongs_to :user

    def self.record!(user, items)
      import = create!(user:, input: items.map { |item| item.to_h.deep_transform_keys(&:to_s) })
      import.start!

      sync = ::BuybackPledges::Sync.new(user, items)
      result = sync.run

      import.update!(output: result.merge(added_names: sync.added_names, removed_names: sync.removed_names))
      import.finish!

      [import, result]
    rescue => error
      import&.update_columns(info: error.class.name.demodulize.underscore.humanize) if import&.persisted?
      import&.fail! if import&.may_fail?
      raise
    end

    def result_details
      {
        imported: Array(output&.dig("added_names")),
        deleted: Array(output&.dig("removed_names"))
      }.reject { |_key, names| names.empty? }
    end

    # What the sync read, for the next one to measure itself against.
    def read_summary
      items = Array(input)

      {
        finished_at:,
        pages: items.filter_map { |item| item["page"].presence&.to_i }.max,
        total: items.map { |item| item["id"].to_s }.uniq.size
      }
    end

    def notify_admin
      # a user's own sync is no admin news
    end
  end
end
