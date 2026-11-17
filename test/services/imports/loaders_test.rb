# frozen_string_literal: true

require "test_helper"

module Imports
  class LoadersTest < ActiveSupport::TestCase
    test "every loader the page offers starts a job" do
      (Imports::Loaders::KEYS - [Imports::Loaders::SHIP_MATRIX_ALL]).each do |key|
        Sidekiq::Worker.clear_all

        Imports::Loaders.new(key, admin_user_id: SecureRandom.uuid).enqueue

        assert_equal 1, Sidekiq::Worker.jobs.size, "#{key} enqueued #{Sidekiq::Worker.jobs.size} jobs"
      end
    end

    test "loading the whole ship matrix starts the rest once the matrix is in" do
      Sidekiq::Worker.clear_all

      Imports::Loaders.new(Imports::Loaders::SHIP_MATRIX_ALL, admin_user_id: SecureRandom.uuid).enqueue

      assert_equal 1, ::Loaders::ModelsJob.jobs.size
      assert_equal Imports::Loaders::SHIP_MATRIX - ["ship_matrix"], ::Loaders::ModelsJob.jobs.first["args"].last
    end

    test "reloading the views compares every listing, whatever its digest" do
      Sidekiq::Worker.clear_all

      Imports::Loaders.new("ship_views", admin_user_id: nil).enqueue
      Imports::Loaders.new("item_views", admin_user_id: nil).enqueue

      assert_equal [nil, false, true], ::ScData::ShipViewsImportJob.jobs.first["args"]
      assert_equal [nil, nil, true], ::ScData::ItemViewsImportJob.jobs.first["args"]
    end

    test "an unknown environment is an error, not the default build" do
      assert_raises(ArgumentError) do
        Imports::Loaders.new("sc_data", admin_user_id: nil, environment: "ptuu").enqueue
      end
    end

    test "an unknown loader is an error, not a silent no-op" do
      assert_raises(ArgumentError) { Imports::Loaders.new("everything", admin_user_id: nil).enqueue }
    end
  end
end
