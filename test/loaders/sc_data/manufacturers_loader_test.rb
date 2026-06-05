# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

module ScData
  module Loader
    class ManufacturersLoaderTest < ActiveSupport::TestCase
      setup do
        @loader = ::ScData::Loader::ManufacturersLoader.new
      end

      test "#all loads data from game files" do
        initial = Manufacturer.count

        @loader.all

        assert_operator Manufacturer.count - initial, :>=, 100

        manufacturer_codes = Manufacturer.pluck(:code)
        assert_equal manufacturer_codes.uniq.size, manufacturer_codes.size
      end

      test "reuses existing entries with matrix data" do
        pledge_response_stub = File.read("spec/fixtures/rsi/300i_pledge_page.html")
        matrix_response_stub = File.read("spec/fixtures/rsi/matrix.json")
        rsi_models_loader = ::Rsi::ModelsLoader.new

        Timecop.freeze("2017-01-01 14:00:00")

        stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/pledge/ships/.*/.*})
          .to_return(status: 200, body: pledge_response_stub)

        stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/ship-matrix/index.*})
          .to_return(status: 200, body: matrix_response_stub)

        stub_request(:post, %r{\Ahttps://robertsspaceindustries.com/graphql})
          .to_return(status: 200, body: [{data: {store: {search: {resources: []}}}}].to_json, headers: {"Content-Type" => "application/json"})

        assert_difference -> { Manufacturer.count }, 18 do
          rsi_models_loader.all
        end

        assert_difference -> { Manufacturer.count }, 97 do
          @loader.all
        end

        manufacturer_codes = Manufacturer.pluck(:code)
        assert_equal manufacturer_codes.uniq.size, manufacturer_codes.size
      ensure
        Timecop.return
      end
    end
  end
end
