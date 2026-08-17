# frozen_string_literal: true

require "test_helper"

module Models
  class ManualRecordsTest < ActiveSupport::TestCase
    test ".call creates every manual model and its manufacturer" do
      ::Models::ManualRecords.call

      ::Models::ManualRecords::MODELS.each do |definition|
        model = Model.find_by(name: definition[:name])

        assert_not_nil model, "#{definition[:name]} was not created"
        assert_equal definition[:manufacturer], model.manufacturer.name
      end
    end

    test ".call carries the attributes each definition names" do
      ::Models::ManualRecords.call

      raptor = Model.find_by(name: "Raptor")
      executive = Model.find_by(name: "600i Executive-Edition")

      assert_predicate raptor, :hidden?
      assert_equal "600i Executive Edition", executive.rsi_name
      assert_equal "exploration", executive.classification
      assert_equal "large", executive.size
    end

    test ".call links an edition to its base model" do
      ::Models::ManualRecords.call

      assert_equal Model.find_by(name: "600i Explorer").id,
        Model.find_by(name: "600i Executive-Edition").base_model_id
      assert_equal Model.find_by(name: "Dragonfly Black").id,
        Model.find_by(name: "Dragonfly Starkitten Edition").base_model_id
    end

    test ".call runs twice without duplicating anything" do
      ::Models::ManualRecords.call

      assert_no_difference [-> { Model.count }, -> { Manufacturer.count }] do
        ::Models::ManualRecords.call
      end
    end

    # The maintenance task hands definitions over one at a time, and nothing
    # promises the base model comes first.
    test ".upsert_model creates the base model when it is not there yet" do
      definition = ::Models::ManualRecords::MODELS.find { |model| model[:name] == "600i Executive-Edition" }

      ::Models::ManualRecords.upsert_model(definition)

      assert_not_nil Model.find_by(name: "600i Explorer")
      assert_equal Model.find_by(name: "600i Explorer").id,
        Model.find_by(name: "600i Executive-Edition").base_model_id
    end

    # A model somebody corrected by hand must survive a re-run.
    test ".upsert_model leaves an existing model alone" do
      existing = create(:model, name: "Raptor", hidden: false)
      definition = ::Models::ManualRecords::MODELS.find { |model| model[:name] == "Raptor" }

      ::Models::ManualRecords.upsert_model(definition)

      assert_not_predicate existing.reload, :hidden?
    end

    test ".upsert_manufacturer reuses a manufacturer that is already there" do
      existing = create(:manufacturer, name: "Origin Jumpworks", code: "ORIG")

      assert_no_difference -> { Manufacturer.count } do
        assert_equal existing, ::Models::ManualRecords.upsert_manufacturer("Origin Jumpworks")
      end
    end

    test ".upsert_manufacturer refuses a name it has no definition for" do
      assert_raises(ArgumentError) { ::Models::ManualRecords.upsert_manufacturer("Nobody") }
    end

    # Guards the data, not the mechanism: a definition naming an attribute that
    # is not in ATTRIBUTES would be dropped on the floor.
    test "every definition names only attributes the upsert assigns" do
      known = ::Models::ManualRecords::ATTRIBUTES + %i[name manufacturer base_model]

      ::Models::ManualRecords::MODELS.each do |definition|
        assert_empty definition.keys - known,
          "#{definition[:name]} names attributes the upsert ignores"
      end
    end

    test "every definition names a manufacturer that has a definition" do
      names = ::Models::ManualRecords::MANUFACTURERS.map { |manufacturer| manufacturer[:name] }

      ::Models::ManualRecords::MODELS.each do |definition|
        assert_includes names, definition[:manufacturer]
      end
    end
  end
end
