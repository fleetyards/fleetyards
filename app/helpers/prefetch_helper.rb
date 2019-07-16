# frozen_string_literal: true

module PrefetchHelper
  private def add_to_prefetch(key, data)
    # rubocop:disable Rails/HelperInstanceVariable
    @data_prefetch ||= {}
    @data_prefetch[key] = data
    # rubocop:enable Rails/HelperInstanceVariable
  end
end
