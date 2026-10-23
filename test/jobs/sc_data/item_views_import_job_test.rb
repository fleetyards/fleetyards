# frozen_string_literal: true

require "test_helper"
require "aws-sdk-s3"

module ScData
  class ItemViewsImportJobTest < ActiveJob::TestCase
    SETTINGS = {
      endpoint: "https://example.invalid",
      access_key_id: "key",
      secret_access_key: "secret",
      bucket: "fltyrd-sc"
    }.freeze

    PNG = Rails.root.join("test/fixtures/files/test.png").binread
    HOLO = Rails.root.join("test/fixtures/holo/plain.gltf").binread

    setup do
      @component = create(:component, sc_key: "pwr_acom_s01_standby")
      @equipment = create(:equipment, sc_key: "behr_rifle_ballistic_01")
      @objects = {}
      @index = {}
      @client = Aws::S3::Client.new(stub_responses: true)
      @client.stub_responses(:get_object, ->(context) {
        body = @objects[context.params[:key].delete_prefix("item-views/")]
        body ? {body:} : "NoSuchKey"
      })

      store = ::ScData::ItemViewsStore.new(client: @client, settings: SETTINGS)
      ::ScData::ItemViewsStore.stubs(:configured?).returns(true)
      ::ScData::ItemViewsStore.stubs(:new).returns(store)
    end

    private def publish(sc_key, files, digest: "listing-1")
      @index[sc_key] = {scKey: sc_key, files: digest, updatedAt: "2026-10-23T00:00:00Z"}
      @objects["index.json"] = {items: @index}.to_json
      @objects["#{sc_key}/files.json"] = {
        files: files.to_h { |name, content| [name, {md5: Digest::MD5.hexdigest(content), size: content.bytesize}] }
      }.to_json
      files.each { |name, content| @objects["#{sc_key}/#{name}"] = content }
    end

    private def fetched
      @client.api_requests
        .select { |request| request[:operation_name] == :get_object }
        .map { |request| File.basename(request[:params][:key]) }
    end

    private def perform(*)
      ::ScData::ItemViewsImportJob.new.perform(*)
      @component.reload
      @equipment.reload
    end

    test "attaches a component's renders by its game-file key" do
      publish(@component.sc_key, {"angled.png" => PNG, "angled_rear.png" => PNG, "holo.gltf" => HOLO})

      perform

      assert @component.angled_view.attached?
      assert @component.angled_rear_view.attached?
      assert @component.holo.attached?
      assert_equal "listing-1", @component.item_views_digest
      assert_equal Digest::MD5.hexdigest(PNG), @component.item_view_md5s["angled_view"]
    end

    test "attaches equipment's renders by its game-file key" do
      publish(@equipment.sc_key, {"top.png" => PNG, "starboard.png" => PNG})

      perform

      assert @equipment.top_view.attached?
      assert @equipment.starboard_view.attached?
    end

    test "skips a name for a field an item does not have" do
      publish(@component.sc_key, {"top_colored.png" => PNG, "extended_front.png" => PNG, "front.png" => PNG})

      perform

      assert @component.front_view.attached?
      assert_equal ["index.json", "files.json", "front.png"], fetched
    end

    test "skips an item whose listing has not changed" do
      @component.update!(item_views_digest: "listing-1")
      publish(@component.sc_key, {"top.png" => PNG})

      perform

      assert_not @component.top_view.attached?
    end

    test "skips a game-file key no item has and carries on" do
      publish("no_such_item", {"top.png" => PNG})
      publish(@component.sc_key, {"top.png" => PNG})

      perform

      assert @component.top_view.attached?
    end

    test "keeps a view uploaded by hand over an imported render" do
      @component.top_view.attach(io: StringIO.new("by hand"), filename: "top.png")
      @component.update!(item_view_md5s: {"top_view" => Digest::MD5.hexdigest(PNG)})
      blob = @component.top_view.blob
      publish(@component.sc_key, {"top.png" => PNG})

      perform

      assert_equal blob, @component.top_view.blob
    end

    test "syncs one item even when its listing has not changed" do
      @equipment.update!(item_views_digest: "listing-1")
      publish(@equipment.sc_key, {"top.png" => PNG})

      perform("Equipment", @equipment.id)

      assert @equipment.top_view.attached?
    end

    test "syncs only the given item" do
      publish(@component.sc_key, {"top.png" => PNG})
      publish(@equipment.sc_key, {"top.png" => PNG})

      perform("Equipment", @equipment.id)

      assert @equipment.top_view.attached?
      assert_not @component.top_view.attached?
    end

    test "syncs nothing for a record type that is not an item" do
      publish(@component.sc_key, {"top.png" => PNG})

      perform("Model", @component.id)

      assert_not @component.top_view.attached?
    end

    test "does nothing without a bucket" do
      ::ScData::ItemViewsStore.stubs(:configured?).returns(false)
      ::ScData::ItemViewsStore.expects(:new).never

      perform
    end
  end
end
