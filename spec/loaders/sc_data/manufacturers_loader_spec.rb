# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

RSpec.describe ScData::Loader::ManufacturersLoader do
  let(:loader) { described_class.new }

  describe "#all" do
    it "loads data from game files" do
      expect { loader.all }.to change(Manufacturer, :count).by(112)

      manufacturer_codes = Manufacturer.pluck(:code)

      expect(manufacturer_codes.size).to eq(manufacturer_codes.uniq.size)
    end
  end

  describe "with existing matrix data" do
    let(:pledge_response_stub) { File.read("spec/fixtures/rsi/300i_pledge_page.html") }
    let(:matrix_response_stub) { File.read("spec/fixtures/rsi/matrix.json") }
    let(:rsi_models_loader) { ::Rsi::ModelsLoader.new }

    before do
      Timecop.freeze("2017-01-01 14:00:00")

      stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/pledge/ships/.*/.*})
        .to_return(status: 200, body: pledge_response_stub)

      stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/ship-matrix/index.*})
        .to_return(status: 200, body: matrix_response_stub)

      stub_request(:post, %r{\Ahttps://robertsspaceindustries.com/graphql})
        .to_return(status: 200, body: [{data: {store: {search: {resources: []}}}}].to_json, headers: {"Content-Type" => "application/json"})
    end

    after do
      Timecop.return
    end

    it "reuses existing entries" do
      expect { rsi_models_loader.all }.to change(Manufacturer, :count).by(18)

      expect { loader.all }.to change(Manufacturer, :count).by(97)

      manufacturer_codes = Manufacturer.pluck(:code)

      expect(manufacturer_codes.size).to eq(manufacturer_codes.uniq.size)
    end
  end
end
