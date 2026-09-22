# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"
require "support/hangar_import_fixtures"
require "support/sc_data_contract_tree"

module ScData
  module Contract
    # The manufacturer questions that are about the export rather than the
    # loader: how many companies the tree still resolves, and whether the
    # de-duplication holds across all of them rather than across the seven the
    # fixture tree carries. See test/support/sc_data_contract_tree.rb.
    class ManufacturersContractTest < ActiveSupport::TestCase
      include HangarImportFixtures
      include ScDataContractTree

      setup do
        require_real_tree

        clean_loader_tables
      end

      test "the export still carries the manufacturers catalogue" do
        initial = Manufacturer.count

        real_tree_loader(::ScData::Loader::ManufacturersLoader).all

        assert_operator Manufacturer.count - initial, :>=, 95

        codes = Manufacturer.pluck(:code)
        assert_equal codes.uniq.size, codes.size

        # The export ships several codes per company and the by-code and by-name
        # lookups only match a row without a ref, so a second code used to create
        # a second row -- four of them ended up called "Aegis Dynamics". Across
        # the whole export rather than the fixture's one pair.
        assert_empty Manufacturer.where.not(name: nil).group(:name).having("count(*) > 1").count

        # The slug is the stricter of the two: names that differ only in case or
        # punctuation pass a by-name check and still collide here.
        assert_empty Manufacturer.where.not(slug: nil).group(:slug).having("count(*) > 1").count

        assert_operator Manufacturer.where.not(icon_path: nil).count, :>=, 100
      end

      test "reuses existing entries with matrix data" do
        pledge_response_stub = File.read("test/fixtures/rsi/300i_pledge_page.html")
        matrix_response_stub = File.read("test/fixtures/rsi/matrix.json")
        rsi_models_loader = ::Rsi::ModelsLoader.new

        Timecop.freeze("2017-01-01 14:00:00")

        stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/pledge/ships/.*/.*})
          .to_return(status: 200, body: pledge_response_stub)

        stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/ship-matrix/index.*})
          .to_return(status: 200, body: matrix_response_stub)

        stub_request(:post, %r{\Ahttps://robertsspaceindustries.com/graphql})
          .to_return(status: 200, body: [{data: {store: {search: {resources: []}}}}].to_json, headers: {"Content-Type" => "application/json"})

        assert_difference -> { Manufacturer.count }, 19 do
          rsi_models_loader.all
        end

        # Counts the real parsed tree, so it moves when the parser's reach does.
        # 93 until CC's Conversions started resolving: its name is declared
        # `manufacturer_NameCCC,P`, which an exact lookup never matched, and the
        # loader only creates a row for a record that has a name.
        assert_difference -> { Manufacturer.count }, 94 do
          real_tree_loader(::ScData::Loader::ManufacturersLoader).all
        end

        codes = Manufacturer.pluck(:code)
        assert_equal codes.uniq.size, codes.size
      ensure
        Timecop.return
      end
    end
  end
end
