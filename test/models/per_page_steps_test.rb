# frozen_string_literal: true

require "test_helper"

class PerPageStepsTest < ActiveSupport::TestCase
  def self.models_with_steps
    Rails.application.eager_load!
    ApplicationRecord.descendants.select(&:per_page_steps)
  end

  # The admin lists that size a page from the request rather than through
  # `per_page`, so a scan for `per_page(...)` cannot find them.
  SIZED_FROM_PARAMS = %w[
    CargoHold Dock DockAddition DockCapacity Hardpoint Image Import ItemPrice
    ModelLoaner ModelModule ModelPosition ModelSnubCraft Video
  ].freeze

  def self.paginated_models
    from_controllers = Rails.root.glob("app/controllers/**/*.rb").flat_map do |path|
      File.read(path).scan(/per_page\((?:::)?([A-Z][\w:]*)\)/).flatten
    end

    (from_controllers + SIZED_FROM_PARAMS).uniq.map(&:constantize).select { |klass| klass < ActiveRecord::Base }
  end

  # Kaminari's own default is 25, which is no shared size and so leaves a short
  # row in a grid.
  paginated_models.each do |model|
    test "#{model.name} declares its own page size" do
      assert model.instance_variable_get(:@_default_per_page),
        "#{model.name} is paginated but falls back to Kaminari's default"
    end
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
