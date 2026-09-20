# frozen_string_literal: true

require "test_helper"

# The component facets are labelled server-side -- `Component.category_filters`
# calls `I18n.t` and hands the result to the API -- so a key only English has is
# a German visitor reading "Shieldgenerator" in a German filter list. Nothing
# catches that at runtime: the lookup falls back to `titleize`, which answers
# every locale with a plausible-looking English word rather than raising.
#
# Read off the files rather than through `I18n.t` on purpose. Going through I18n
# would resolve a missing key against the English fallback and pass, which is
# precisely the gap this is here to find.
class FilterLocaleTest < ActiveSupport::TestCase
  LOCALES = %w[en de es fr it zh-CN zh-TW].freeze

  FACET_GROUPS = %w[category class sub_type].freeze

  FACET_GROUPS.each do |group|
    test "every locale labels the same component #{group} values" do
      LOCALES.each do |locale|
        assert_equal(
          facet_items("en", group).keys.sort,
          facet_items(locale, group).keys.sort,
          "#{locale} does not label the same component #{group} values as en"
        )
      end
    end

    test "no component #{group} label is blank" do
      LOCALES.each do |locale|
        blank = facet_items(locale, group).select { |_key, label| label.blank? }

        assert_empty blank, "#{locale} has blank component #{group} labels: #{blank.keys.join(", ")}"
      end
    end
  end

  private def facet_items(locale, group)
    YAML.load_file(Rails.root.join("config/locales/#{locale}/filter.yml"))
      .fetch(locale).fetch("filter").fetch("component").fetch(group).fetch("items")
  end
end
