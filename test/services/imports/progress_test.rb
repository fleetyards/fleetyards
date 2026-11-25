# frozen_string_literal: true

require "test_helper"

module Imports
  class ProgressTest < ActiveSupport::TestCase
    setup do
      @import = Imports::ScData::AllImport.create!(version: "4.10.3-live.1")
      @import.start!
      @progress = Imports::Progress.new(@import, steps: 11)
    end

    def stored
      @import.reload.progress
    end

    test "#step records where the import is" do
      @progress.step("items", total: 40)

      assert_equal({"step" => "items", "step_number" => 1, "steps" => 11, "done" => 0, "total" => 40}, stored)
      assert_not_nil @import.progressed_at
    end

    test "#step counts on from the step before it and starts its own count" do
      @progress.step("fetch_tree", total: 1)
      @progress.advance
      @progress.step("items")

      assert_equal 2, stored["step_number"]
      assert_equal 0, stored["done"]
      assert_nil stored["total"]
    end

    test "#advance writes only as often as a person looks" do
      @progress.step("items", total: 40)
      3.times { @progress.advance }

      assert_equal 0, stored["done"]

      @progress.stubs(:monotonic).returns(Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10)
      @progress.advance

      assert_equal 4, stored["done"]
    end

    test "#advance writes the last record of a step at once" do
      @progress.step("items", total: 2)
      2.times { @progress.advance }

      assert_equal 2, stored["done"]
    end

    test "#advance can be called from the threads of a transfer" do
      @progress.step("fetch_tree", total: 200)
      Array.new(4) { Thread.new { 50.times { @progress.advance } } }.each(&:join)

      assert_equal 200, stored["done"]
    end

    test "a write is sent to admins without notifying them" do
      admin_user = create(:admin_user, resource_access: [:imports])
      sent = []
      ImportsChannel.stubs(:broadcast_to).with { |to, payload| sent << payload if to == admin_user }

      assert_no_difference -> { AdminNotification.count } do
        @progress.step("items", total: 40)
      end

      assert_equal "items", sent.last.dig("progress", "step")
      assert_equal 40, sent.last.dig("progress", "total")
    end

    test "a run an admin cleared meanwhile is left alone" do
      Import.find(@import.id).cleanup!
      ImportsChannel.expects(:broadcast_to).never

      @progress.step("items", total: 40)

      assert_nil stored
      assert_equal "failed", @import.aasm_state
    end

    test "a write that fails does not fail the import" do
      @import.stubs(:update_columns).raises(ActiveRecord::StatementInvalid, "no")

      assert_nothing_raised { @progress.step("items", total: 40) }
    end

    test "every loader of a full load is a step the schema knows" do
      steps = ::ScData::Loader::BaseLoader.loaders.map { |loader| loader.name.demodulize.delete_suffix("Loader").underscore }

      assert_empty ["fetch_tree", *steps] - Imports::Progress::STEPS
    end
  end
end
