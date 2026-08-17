# frozen_string_literal: true

require "test_helper"

module ScData
  module Loader
    class BaseLoaderTest < ActiveSupport::TestCase
      setup do
        Commodity.delete_all
        @loader = ::ScData::Loader::BaseLoader.new
        @version = Rails.configuration.sc_data[:version]
      end

      # The row has to stay: a ledger entry made against it still has to
      # resolve. It just stops claiming a build it is no longer part of.
      test "#retire_absent clears the build off rows the run did not load" do
        loaded = create(:commodity, version: @version)
        dropped = create(:commodity, version: @version)

        @loader.retire_absent(Commodity, [loaded.id])

        assert_equal @version, loaded.reload.version
        assert_nil dropped.reload.version
        assert Commodity.exists?(dropped.id), "the row has to stay for existing references"
      end

      # Only the build being loaded is reconciled. What an earlier build shipped
      # is history, and rewriting it would lose the build a row was last seen in.
      test "#retire_absent leaves rows of an earlier build alone" do
        earlier = create(:commodity, version: "3.24.0")

        @loader.retire_absent(Commodity, [create(:commodity, version: @version).id])

        assert_equal "3.24.0", earlier.reload.version
      end

      # `where.not(id: [])` is `1=1`, so without this an export that failed to
      # sync -- or an environment whose tree does not carry the catalogue at all
      # -- would retire every row claiming the current build in one statement.
      test "#retire_absent retires nothing when the run loaded nothing" do
        current = create(:commodity, version: @version)

        @loader.retire_absent(Commodity, [])

        assert_equal @version, current.reload.version
      end
    end
  end
end
