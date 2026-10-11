# frozen_string_literal: true

require "test_helper"

class PerPageStepsTest < ActiveSupport::TestCase
  # The admin lists that size a page from the request rather than through
  # `per_page`, so a scan for `per_page(...)` cannot find them.
  SIZED_FROM_PARAMS = %w[
    CargoHold Dock DockAddition DockCapacity Hardpoint Image Import ItemPrice
    ModelLoaner ModelModule ModelPosition ModelSnubCraft Video
  ].freeze

  def self.paginated
    Rails.application.eager_load!

    from_controllers = Rails.root.glob("app/controllers/**/*.rb").flat_map do |path|
      File.read(path).scan(/per_page\((?:::)?([A-Z][\w:]*)\)/).flatten
    end
    declared = ApplicationRecord.descendants.select { |klass| klass.instance_variable_get(:@_default_per_page) }

    ((from_controllers + SIZED_FROM_PARAMS).map(&:constantize) + declared).uniq
  end

  # The card grid shows 1, 2, 3, 4 or 6 columns; a size that 12 does not
  # divide leaves a short last row at one of them.
  test "every shared size fills whole grid rows" do
    PageSizes::STEPS.each { |size| assert_equal 0, size % 12, "#{size} is no multiple of 12" }
  end

  # The frontend drops a saved or linked size off this set before requesting
  # it, so the two lists have to agree.
  test "the frontend knows the shared sizes" do
    source = Rails.root.join("app/frontend/shared/composables/usePagination.ts").read
    sizes = source[/const PAGE_SIZES = \[([^\]]*)\]/, 1].scan(/"(\w+)"/).flatten

    assert_equal PageSizes::STEPS.map(&:to_s) + ["all"], sizes
  end

  paginated.each do |list|
    # Kaminari's own default is 25, and any size off the shared set leaves a
    # short last row on some width of the card grid.
    test "#{list.name} pages by a shared size" do
      assert list.instance_variable_get(:@_default_per_page),
        "#{list.name} is paginated but falls back to Kaminari's default"
      assert_includes PageSizes::STEPS, list.default_per_page
    end

    next unless list.per_page_steps

    test "#{list.name} offers its default page size" do
      assert_includes list.per_page_steps, list.default_per_page
    end

    # `per_page` answers a size above the maximum with a 400, so a step past it
    # is a dropdown entry that breaks the list.
    test "#{list.name} offers no size above its maximum" do
      assert_operator list.per_page_steps.grep(Integer).max, :<=, list.max_per_page
    end

    # `up_to` reads the maximum when the steps are declared, so a
    # `max_paginates_per` after them would cap the steps at the global maximum.
    test "#{list.name} offers every shared size up to its maximum" do
      expected = PageSizes.up_to(list.max_per_page)
      expected += [:all] if list.per_page_steps.include?(:all)

      assert_equal expected, list.per_page_steps
    end

    test "#{list.name} offers only the shared page sizes" do
      assert_empty list.per_page_steps.grep(Integer) - PageSizes::STEPS
    end
  end
end
