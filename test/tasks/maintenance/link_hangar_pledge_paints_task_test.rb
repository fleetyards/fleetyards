# frozen_string_literal: true

require "test_helper"

module Maintenance
  class LinkHangarPledgePaintsTaskTest < ActiveSupport::TestCase
    test "links the paint pledges a sync stored unlinked" do
      paint = create(:model_paint, model: create(:model, name: "Nomad"), name: "Ice Break")
      item = create(:hangar_pledge_item, name: "Nomad IceBreak Livery")

      task = Maintenance::LinkHangarPledgePaintsTask.new
      task.collection.each { |batch| task.process(batch) }

      assert_equal [paint], item.reload.model_paints.to_a
    end
  end
end
