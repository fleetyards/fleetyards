# frozen_string_literal: true

require "rails_helper"

RSpec.describe MetricsJob do
  describe "#perform" do
    it "generates rollup metrics without errors" do
      expect { described_class.new.perform }.not_to raise_error
    end
  end
end
