# frozen_string_literal: true

require "test_helper"

module Imports
  class LoadersTest < ActiveSupport::TestCase
    test "every loader the page offers starts a job" do
      Imports::Loaders::KEYS.each do |key|
        Sidekiq::Worker.clear_all

        Imports::Loaders.new(key, admin_user_id: SecureRandom.uuid).enqueue

        assert_equal 1, Sidekiq::Worker.jobs.size, "#{key} enqueued #{Sidekiq::Worker.jobs.size} jobs"
      end
    end

    test "an unknown loader is an error, not a silent no-op" do
      assert_raises(ArgumentError) { Imports::Loaders.new("everything", admin_user_id: nil).enqueue }
    end
  end
end
