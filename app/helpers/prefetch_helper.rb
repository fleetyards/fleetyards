# frozen_string_literal: true

module PrefetchHelper
  private def add_to_prefetch(key, data)
    @data_prefetch ||= {}
    @data_prefetch[key] = data
  end
end
