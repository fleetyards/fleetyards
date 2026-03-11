# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScData::Loader::ItemsLoader do
  let(:loader) { described_class.new }

  describe "#all" do
    it "loads data from game files" do
      expect { loader.all }.to change { Component.where.not(version: nil).count }.by(6527)
    end
  end
end
