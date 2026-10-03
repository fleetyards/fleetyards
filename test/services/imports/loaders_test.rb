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

    test "loading the whole ship matrix starts each of its loads" do
      Sidekiq::Worker.clear_all

      Imports::Loaders.new(Imports::Loaders::SHIP_MATRIX_ALL, admin_user_id: SecureRandom.uuid).enqueue

      assert_equal Imports::Loaders::SHIP_MATRIX.size, Sidekiq::Worker.jobs.size
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
