# frozen_string_literal: true

require "test_helper"

module ScData
  module Parser
    class MissionLocationsTest < ActiveSupport::TestCase
      TAG_IDS = {
        missions: "00000000-0000-4000-8000-000000000001",
        location_type: "00000000-0000-4000-8000-000000000002",
        setting: "00000000-0000-4000-8000-000000000003",
        surface: "00000000-0000-4000-8000-000000000004",
        space: "00000000-0000-4000-8000-000000000005",
        outpost: "00000000-0000-4000-8000-000000000006",
        stanton1: "00000000-0000-4000-8000-000000000007",
        placement: "00000000-0000-4000-8000-000000000008",
        mercenary: "00000000-0000-4000-8000-000000000009"
      }.freeze

      TEMPLATE_REF = "10000000-0000-4000-8000-000000000001"

      setup do
        @locations = []
      end

      test "a location tagged Surface makes the contract surface" do
        location(TAG_IDS[:surface], TAG_IDS[:stanton1])

        assert_equal "surface", classify(search(TAG_IDS[:stanton1]))[:location_kind]
      end

      test "a location tagged Space makes the contract space" do
        location(TAG_IDS[:space], TAG_IDS[:stanton1])

        assert_equal "space", classify(search(TAG_IDS[:stanton1]))[:location_kind]
      end

      test "a search that can match both kinds is mixed" do
        location(TAG_IDS[:surface], TAG_IDS[:stanton1])
        location(TAG_IDS[:space], TAG_IDS[:stanton1])

        assert_equal "mixed", classify(search(TAG_IDS[:stanton1]))[:location_kind]
      end

      test "a search naming the setting says the kind without a pool" do
        location(TAG_IDS[:surface], TAG_IDS[:stanton1])

        assert_equal "space", classify(search(TAG_IDS[:space]))[:location_kind]
      end

      test "a location without a setting tag falls back to its location type" do
        location(TAG_IDS[:outpost], TAG_IDS[:stanton1])

        assert_equal "surface", classify(search(TAG_IDS[:stanton1]))[:location_kind]
      end

      test "a placement tag no location carries does not empty the pool" do
        location(TAG_IDS[:space], TAG_IDS[:stanton1])

        assert_equal "space", classify(search(TAG_IDS[:stanton1], TAG_IDS[:placement]))[:location_kind]
      end

      test "a kind the rest of the search can't reach does not count" do
        location(TAG_IDS[:space], TAG_IDS[:mercenary])
        location(TAG_IDS[:surface], TAG_IDS[:stanton1])

        # Either setting, but only where the mercenary tag is: that is space alone.
        slots = {
          "MissionLocation_BP" => {
            "MissionPropertyValue_Location" => {
              "matchConditions" => {
                "DataSetMatchCondition_TagSearch" => [
                  condition([TAG_IDS[:surface]], [TAG_IDS[:space]]),
                  condition([TAG_IDS[:mercenary]])
                ]
              }
            }
          }
        }

        assert_equal "space", classify(slots)[:location_kind]
      end

      test "a term naming a kind keeps an unmatched placement search to that kind" do
        location(TAG_IDS[:surface], TAG_IDS[:stanton1])
        location(TAG_IDS[:space], TAG_IDS[:stanton1])

        assert_equal "space", classify(search(TAG_IDS[:stanton1], TAG_IDS[:space]))[:location_kind]
      end

      test "a pool with a location we can't classify is mixed, not the known kind" do
        location(TAG_IDS[:surface], TAG_IDS[:stanton1])
        location(TAG_IDS[:stanton1])

        result = classify(search(TAG_IDS[:stanton1]))

        assert_equal "mixed", result[:location_kind]
        assert result[:needs_landing]
      end

      test "a slot the game fills at run time says nothing about the others" do
        location(TAG_IDS[:space], TAG_IDS[:stanton1])
        slots = search(TAG_IDS[:stanton1]).merge("DropOff" => {"MissionPropertyValue_Location" => {}})

        assert_equal "space", classify(slots)[:location_kind]
      end

      test "a disabled location is not part of any pool" do
        location(TAG_IDS[:surface], TAG_IDS[:stanton1], disabled: true)
        location(TAG_IDS[:space], TAG_IDS[:stanton1])

        assert_equal "space", classify(search(TAG_IDS[:stanton1]))[:location_kind]
      end

      test "a contract without a location slot is unknown" do
        result = classify({"Speed" => {"MissionPropertyValue_Float" => {"value" => "1"}}})

        assert_equal({location_kind: "unknown", needs_landing: false}, result)
      end

      test "a surface delivery needs landing" do
        location(TAG_IDS[:surface], TAG_IDS[:stanton1])

        result = classify(search(TAG_IDS[:stanton1]).merge("Item1" => {"MissionPropertyValue_MissionItem" => {}}))

        assert result[:needs_landing]
      end

      test "ship combat at a surface target needs no landing" do
        location(TAG_IDS[:surface], TAG_IDS[:mercenary])

        result = classify(search(TAG_IDS[:mercenary]).merge("Ships" => {"MissionPropertyValue_ShipSpawnDescriptions" => {}}))

        assert_equal "surface", result[:location_kind]
        assert_not result[:needs_landing]
      end

      test "ship combat that also puts a pilot on foot needs landing" do
        location(TAG_IDS[:surface], TAG_IDS[:mercenary])

        result = classify(search(TAG_IDS[:mercenary]).merge(
          "Ships" => {"MissionPropertyValue_ShipSpawnDescriptions" => {}},
          "Guards" => {"MissionPropertyValue_NPCSpawnDescriptions" => {}}
        ))

        assert result[:needs_landing]
      end

      test "a mixed contract that is not ship combat may need landing" do
        location(TAG_IDS[:surface], TAG_IDS[:stanton1])
        location(TAG_IDS[:space], TAG_IDS[:stanton1])

        assert classify(search(TAG_IDS[:stanton1]))[:needs_landing]
      end

      test "the contract's own slot replaces the template's" do
        location(TAG_IDS[:surface], TAG_IDS[:stanton1])
        location(TAG_IDS[:space], TAG_IDS[:mercenary])
        template = {"MissionLocation_BP" => search(TAG_IDS[:stanton1])["MissionLocation_BP"]}

        result = classify(search(TAG_IDS[:mercenary]), template:)

        assert_equal "space", result[:location_kind]
      end

      private def classify(slots, template: nil)
        contract = {"template" => TEMPLATE_REF, "paramOverrides" => {"propertyOverrides" => properties(slots)}}
        templates = template ? [{key: "Template", values: {"__ref" => TEMPLATE_REF, "contractProperties" => properties(template)}}] : []

        ScData::Parser::MissionLocations.new(loader(templates)).classify(contract, nil)
      end

      private def search(*tags)
        {
          "MissionLocation_BP" => {
            "MissionPropertyValue_Location" => {
              "matchConditions" => {
                "DataSetMatchCondition_TagSearch" => {
                  "tagType" => "General",
                  "tagSearch" => {"TagSearchTerm" => {"positiveTags" => {"Reference" => tags.map { |id| {"value" => id} }}}}
                }
              }
            }
          }
        }
      end

      private def condition(*terms)
        {
          "tagType" => "General",
          "tagSearch" => {
            "TagSearchTerm" => terms.map { |tags| {"positiveTags" => {"Reference" => tags.map { |id| {"value" => id} }}} }
          }
        }
      end

      private def properties(slots)
        {"MissionProperty" => slots.map { |name, value| {"missionVariableName" => name, "value" => value} }}
      end

      private def location(*tags, disabled: false)
        @locations << {
          key: "Location#{@locations.size}",
          values: {
            "locationData" => {
              "disabled" => disabled ? "1" : "0",
              "generalTags" => {"tags" => {"Reference" => tags.map { |id| {"value" => id} }}}
            }
          }
        }
      end

      private def loader(templates)
        tree = [{key: "Records", values: tag_records}]

        lambda do |path|
          case path
          when MissionLocations::TAGS_PATH then tree
          when MissionLocations::LOCATIONS_PATH then @locations
          when MissionLocations::TEMPLATES_PATH then templates
          else []
          end
        end
      end

      # Missions/LocationType/{LocationSetting/{Surface,Space},Outpost},
      # plus a system tag and a mercenary tag under LocationType.
      private def tag_records
        children = {
          missions: [:location_type],
          location_type: [:setting, :outpost, :stanton1, :mercenary],
          setting: [:surface, :space]
        }
        names = {
          missions: "Missions", location_type: "LocationType", setting: "LocationSetting",
          surface: "Surface", space: "Space", outpost: "Outpost", stanton1: "Stanton1",
          placement: "RegionA", mercenary: "MercenaryMissionLocation"
        }

        names.to_h do |key, name|
          record = {"__ref" => TAG_IDS[key], "tagName" => name}
          kids = children[key]
          record["children"] = {"Reference" => kids.map { |kid| {"value" => TAG_IDS[kid]} }} if kids

          ["Tag.#{TAG_IDS[key]}", record]
        end
      end
    end
  end
end
