# frozen_string_literal: true

require "test_helper"

# Outside test/integration/api/v1 so it adds nothing to the OpenAPI schema.
class PublicHangarHiddenFiltersTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create(:user, public_hangar: true, public_hangar_stats: true)
    @hidden = create(:vehicle, user: @owner, public: true, name: "Secret Cutlass", name_visible: false)
    @shown = create(:vehicle, user: @owner, public: true, name: "Open Freelancer", name_visible: true)
    @private_group = create(:hangar_group, user: @owner, public: false, name: "Raid Wing")
    @public_group = create(:hangar_group, user: @owner, public: true, name: "Haulers")
    @hidden.hangar_groups << @private_group
    @shown.hangar_groups << @public_group
  end

  test "a hidden name matches no name filter or search" do
    %w[nameCont searchCont nameOrDescriptionCont].each do |key|
      assert_empty ids(key => "Secret"), key
    end
    assert_empty ids("nameIn" => ["Secret Cutlass"])
  end

  test "a shown name still matches" do
    assert_equal [@shown.id], ids("nameCont" => "Freelancer")
    assert_equal [@shown.id], ids("searchCont" => "Open")
  end

  test "the search still finds a ship by its model" do
    assert_includes ids("searchCont" => @hidden.model.name), @hidden.id
  end

  test "a private group answers like a group that does not exist" do
    assert_empty ids("hangarGroupsIn" => [@private_group.slug])
    assert_equal ids("hangarGroupsNotIn" => ["no-such-group"]), ids("hangarGroupsNotIn" => [@private_group.slug])
    assert_equal [@shown.id], ids("hangarGroupsIn" => [@public_group.slug])
  end

  test "the stats total does not answer for a hidden name either" do
    get "/api/v1/public/hangars/#{@owner.username}/stats", params: {q: {nameCont: "Secret"}}

    assert_response :success
    assert_equal 0, response.parsed_body["total"]
  end

  test "sorting by name does not order by a hidden one" do
    zulu = create(:vehicle, user: @owner, public: true, name: "Zulu", name_visible: false, model: @shown.model)
    alpha = create(:vehicle, user: @owner, public: true, name: "Alpha", name_visible: false, model: @shown.model)

    get "/api/v1/public/hangars/#{@owner.username}", params: {q: {sorts: ["name asc"]}, perPage: 50}

    order = response.parsed_body["items"].map { |item| item["id"] }
    assert_operator order.index(@shown.id), :<, order.index(zulu.id)
    assert_operator order.index(@shown.id), :<, order.index(alpha.id)
  end

  private def ids(query)
    get "/api/v1/public/hangars/#{@owner.username}", params: {q: query}

    assert_response :success
    response.parsed_body["items"].map { |item| item["id"] }
  end
end
