# frozen_string_literal: true

require "test_helper"

class PerPageStepsTest < ActiveSupport::TestCase
  def self.models_with_steps
    Rails.application.eager_load!
    ApplicationRecord.descendants.select(&:per_page_steps)
  end

  models_with_steps.each do |model|
    test "#{model.name} offers its default page size" do
      assert_includes model.per_page_steps, model.default_per_page
    end

    # `per_page` answers a size above the maximum with a 400, so a step past it
    # is a dropdown entry that breaks the list.
    test "#{model.name} offers no size above its maximum" do
      sizes = model.per_page_steps.grep(Integer)

      assert_operator sizes.max, :<=, model.max_per_page
    end

    # A size off the shared set leaves a short last row on some width of the
    # card grid.
    test "#{model.name} offers only the shared page sizes" do
      assert_empty model.per_page_steps.grep(Integer) - PageSizes::STEPS
    end
  end
end
