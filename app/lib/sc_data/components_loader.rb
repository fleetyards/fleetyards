# frozen_string_literal: true

module ScData
  class ComponentsLoader < ::ScData::BaseLoader
    def initialize
      super

      self.base_url = "#{base_url}/items"
    end

    def load(data_slug)
      item_response = fetch_remote("#{data_slug.downcase}.json")

      return unless item_response.success?

      parse_json_response(item_response)
    end
  end
end
