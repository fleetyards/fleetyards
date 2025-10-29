# frozen_string_literal: true

require "test_helper"

module ScData
  class ManufacturersLoaderTest < ActiveSupport::TestCase
    let(:loader) { ::ScData::Loader::ManufacturersLoader.new }
    let(:loader) { ::ScData::Loader::ManufacturersLoader.new }

    describe "#all" do
      it "loads data from game files" do
        initial_manufacturer_count = Manufacturer.count

        assert_difference("Manufacturer.count", 92 + initial_manufacturer_count) do
          loader.all
        end

        manufacturer_codes = Manufacturer.pluck(:code)

        assert_equal(manufacturer_codes.size, manufacturer_codes.uniq.size)
      end
    end

    describe "#with_existing_matrix_data" do
      let(:pledge_response_stub) { File.read("test/fixtures/rsi/300i_pledge_page.html") }
      let(:matrix_response_stub) { File.read("test/fixtures/rsi/matrix.json") }

      let(:rsi_models_loader) { ::Rsi::ModelsLoader.new }

      before do
        Timecop.freeze("2017-01-01 14:00:00")

        stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/pledge/ships/.*/.*})
          .to_return(status: 200, body: pledge_response_stub)

        stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/ship-matrix/index.*})
          .to_return(status: 200, body: matrix_response_stub)
      end

      after do
        Timecop.return
      end

      it "reuses existing entries" do
        initial_manufacturer_count = Manufacturer.count

        assert_difference("Manufacturer.count", 5 + initial_manufacturer_count) do
          rsi_models_loader.all
        end

        initial_manufacturer_count += 5

        assert_difference("Manufacturer.count", 78 + initial_manufacturer_count) do
          loader.all
        end

        manufacturer_codes = Manufacturer.pluck(:code)

        assert_equal(manufacturer_codes.size, manufacturer_codes.uniq.size)
      end
    end
  end
end
