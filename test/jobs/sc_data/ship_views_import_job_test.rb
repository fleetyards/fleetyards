# frozen_string_literal: true

require "test_helper"
require "aws-sdk-s3"
require "vips"

module ScData
  class ShipViewsImportJobTest < ActiveJob::TestCase
    SETTINGS = {
      endpoint: "https://example.invalid",
      access_key_id: "key",
      secret_access_key: "secret",
      bucket: "fltyrd-sc"
    }.freeze

    PATH = "crusader/ares-inferno"
    PNG = Rails.root.join("test/fixtures/files/test.png").binread
    HOLO = Rails.root.join("test/fixtures/holo/plain.gltf").binread

    setup do
      Sidekiq::Worker.clear_all

      @model = create(:model)
      @objects = {}
      @client = Aws::S3::Client.new(stub_responses: true)
      @client.stub_responses(:get_object, ->(context) {
        body = @objects[context.params[:key].delete_prefix("ship-views/")]
        body ? {body:} : "NoSuchKey"
      })

      store = ::ScData::ShipViewsStore.new(client: @client, settings: SETTINGS)
      ::ScData::ShipViewsStore.stubs(:configured?).returns(true)
      ::ScData::ShipViewsStore.stubs(:new).returns(store)
    end

    private def publish(files, digest: "listing-1", slug: @model.slug, sc_key: nil)
      @objects["index.json"] = {ships: {PATH => {slug:, scKey: sc_key, files: digest, updatedAt: "2026-10-16T00:00:00Z"}.compact}}.to_json
      @objects["#{PATH}/files.json"] = {
        slug:, path: PATH, concept: false,
        files: files.to_h { |name, content| [name, {md5: Digest::MD5.hexdigest(content), size: content.bytesize}] }
      }.to_json
      files.each { |name, content| @objects["#{PATH}/#{name}"] = content }
    end

    private def fetched
      @client.api_requests
        .select { |request| request[:operation_name] == :get_object }
        .map { |request| request[:params][:key].delete_prefix("ship-views/#{PATH}/") }
    end

    private def perform(*)
      ::ScData::ShipViewsImportJob.new.perform(*)
      @model.reload
    end

    test "attaches each render to its field" do
      publish({"flight_top.png" => PNG, "landed_side_colored.png" => PNG, "landed_holo.gltf" => HOLO})

      perform

      assert @model.top_view.attached?
      assert @model.landed_port_view_colored.attached?
      assert @model.landed_holo.attached?
      assert_equal "flight_top.png", @model.top_view.filename.to_s
      assert_equal "listing-1", @model.ship_views_digest
      assert_equal Digest::MD5.hexdigest(PNG), @model.ship_view_md5s["top_view"]
    end

    test "measures the holos and builds the views' representations without cropping them" do
      publish({"flight_top.png" => PNG, "flight_front.png" => PNG, "flight_holo.gltf" => HOLO})

      perform

      assert_empty TrimAttachmentJob.jobs
      assert_equal ["holo"], MeasureHoloJob.jobs.map { |job| job["args"].second }
      assert_equal [@model.front_view.blob.id, @model.top_view.blob.id].sort,
        PreprocessRepresentationsJob.jobs.map { |job| job["args"].first }.sort
    end

    test "keeps a render with transparent padding as it was published" do
      padded = Vips::Image.black(200, 150, bands: 4).cast(:uchar)
        .insert(Vips::Image.black(100, 40, bands: 3).new_from_image([255, 0, 0]).bandjoin(255).cast(:uchar), 50, 55)
        .write_to_buffer(".png")
      publish({"flight_top.png" => padded})

      perform

      assert_equal Digest::MD5.hexdigest(padded), @model.top_view.blob.checksum.unpack1("m0").unpack1("H*")
      assert_equal [@model.top_view.blob.id], PreprocessRepresentationsJob.jobs.map { |job| job["args"].first }
    end

    test "attaches a render only once its bytes are in storage" do
      publish({"flight_top.png" => PNG})
      ActiveStorage::Blob.any_instance.stubs(:upload_without_unfurling).raises(Aws::S3::Errors::InternalError.new(nil, "down"))
      Appsignal.stubs(:report_error)

      perform

      assert_not @model.top_view.attached?
    end

    test "skips a ship whose listing has not changed" do
      @model.update!(ship_views_digest: "listing-1")
      publish({"flight_top.png" => PNG})

      perform

      assert_not @model.top_view.attached?
      assert_equal ["ship-views/index.json"], @client.api_requests.map { |request| request[:params][:key] }
    end

    test "skips an unknown slug and carries on" do
      publish({"flight_top.png" => PNG}, slug: "no-such-ship")

      assert_nothing_raised { perform }
      assert_not @model.top_view.attached?
    end

    test "finds a model by its RSI slug when ours carries the manufacturer" do
      @model.update_columns(slug: "rsi-arrastra", rsi_slug: "arrastra")
      publish({"flight_top.png" => PNG}, slug: "arrastra")

      perform

      assert @model.top_view.attached?
    end

    test "finds a model by its game-file key before its slug" do
      other = create(:model)
      @model.update_columns(sc_key: "RSI_Arrastra")
      publish({"flight_top.png" => PNG}, slug: other.slug, sc_key: "RSI_Arrastra")

      perform

      assert @model.top_view.attached?
      assert_not other.reload.top_view.attached?
    end

    test "falls back to the slug for a game-file key no model has" do
      publish({"flight_top.png" => PNG}, sc_key: "RSI_Unknown")

      perform

      assert @model.top_view.attached?
    end

    test "matches no model on a game-file key two models share" do
      @model.update_columns(sc_key: "RSI_Arrastra")
      create(:model).update_columns(sc_key: "RSI_Arrastra")
      publish({"flight_top.png" => PNG}, slug: "no-such-ship", sc_key: "RSI_Arrastra")

      perform

      assert_not @model.top_view.attached?
    end

    test "syncs one model listed under its RSI slug" do
      @model.update_columns(slug: "rsi-arrastra", rsi_slug: "arrastra")
      publish({"flight_top.png" => PNG}, slug: "arrastra")

      perform(@model.id)

      assert @model.top_view.attached?
    end

    test "does not fetch a render it imported before" do
      # Cropped since, so its blob no longer carries the listed md5.
      @model.top_view.attach(io: StringIO.new("cropped"), filename: "flight_top.png")
      @model.update!(ship_view_md5s: {"top_view" => Digest::MD5.hexdigest(PNG)})
      blob = @model.top_view.blob
      publish({"flight_top.png" => PNG, "flight_front.png" => PNG})

      perform

      assert_equal ["index.json", "files.json", "flight_front.png"], fetched.map { |key| File.basename(key) }
      assert_equal blob, @model.top_view.blob
      assert @model.front_view.attached?
    end

    # A view uploaded through the admin before the bucket existed is the same
    # file, so the first import leaves it alone.
    test "does not replace an attachment with the same checksum" do
      @model.top_view.attach(io: StringIO.new(PNG), filename: "top.png")
      blob = @model.top_view.blob
      publish({"flight_top.png" => PNG})

      perform

      assert_equal blob, @model.top_view.blob
      assert_equal Digest::MD5.hexdigest(PNG), @model.ship_view_md5s["top_view"]
    end

    test "fetches a render again whose file never reached storage" do
      @model.top_view.attach(io: StringIO.new(PNG), filename: "flight_top.png")
      @model.update!(ship_view_md5s: {"top_view" => Digest::MD5.hexdigest(PNG)})
      @model.top_view.blob.service.delete(@model.top_view.blob.key)
      publish({"flight_top.png" => PNG})

      perform(@model.id)

      assert_includes fetched, "flight_top.png"
      assert_equal PNG, @model.top_view.download
    end

    test "fetches a render again whose checksum matches but whose file is missing" do
      @model.top_view.attach(io: StringIO.new(PNG), filename: "top.png")
      @model.top_view.blob.service.delete(@model.top_view.blob.key)
      publish({"flight_top.png" => PNG})

      perform

      assert_includes fetched, "flight_top.png"
      assert_equal PNG, @model.top_view.download
    end

    test "replaces a render that changed" do
      @model.update!(ship_view_md5s: {"top_view" => "old"}, ship_views_digest: "listing-0")
      @model.top_view.attach(io: StringIO.new("old"), filename: "top.png")
      publish({"flight_top.png" => PNG})

      perform

      assert_equal Digest::MD5.hexdigest(PNG), Digest::MD5.hexdigest(@model.top_view.download)
    end

    test "never detaches a field the listing does not mention" do
      @model.front_view.attach(io: StringIO.new(PNG), filename: "front.png")
      publish({"flight_top.png" => PNG})

      perform

      assert @model.front_view.attached?
    end

    test "keeps the old digest when a render does not match its md5" do
      publish({"flight_top.png" => PNG, "flight_front.png" => PNG})
      @objects["#{PATH}/flight_top.png"] = "truncated"

      perform

      assert_not @model.top_view.attached?
      assert @model.front_view.attached?
      assert_nil @model.ship_views_digest
    end

    test "keeps the rest of a ship when one render cannot be fetched" do
      publish({"flight_top.png" => PNG, "flight_front.png" => PNG})
      @objects.delete("#{PATH}/flight_top.png")
      ::ScData::ShipViewsStore.any_instance.stubs(:sleep)

      perform

      assert_not @model.top_view.attached?
      assert @model.front_view.attached?
      assert_nil @model.ship_views_digest
      assert_nil @model.ship_view_md5s["top_view"]
    end

    test "records nothing when the upload fails" do
      publish({"flight_top.png" => PNG})
      ActiveStorage::Blob.any_instance.stubs(:upload_without_unfurling).raises(Aws::S3::Errors::InternalError.new(nil, "down"))
      Appsignal.expects(:report_error)

      perform

      assert_nil @model.ship_views_digest
      assert_empty @model.ship_view_md5s
    end

    test "attaches a field again after it was detached" do
      publish({"flight_top.png" => PNG})
      perform
      @model.top_view.purge
      @model.update!(ship_views_digest: "listing-0")

      perform

      assert @model.top_view.attached?
    end

    test "skips a model two folders claim" do
      publish({"flight_top.png" => PNG})
      index = JSON.parse(@objects["index.json"])
      index["ships"]["crusader/ares-inferno-concept"] = index["ships"][PATH]
      @objects["index.json"] = index.to_json

      perform

      assert_not @model.top_view.attached?
    end

    test "takes the first name in order when two claim one field" do
      publish({"flight_side.png" => "side", "flight_port.png" => PNG})

      perform

      assert_equal "flight_port.png", @model.port_view.filename.to_s
    end

    test "logs what it attached" do
      publish({"flight_top.png" => PNG})
      Rails.logger.expects(:info).with("[sc_data] ShipViewsImportJob attached #{@model.slug}: top_view")
      Rails.logger.expects(:info).with("[sc_data] ShipViewsImportJob attached 1 renders to 1 models")
      Rails.logger.stubs(:info).with { |message| !message.to_s.start_with?("[sc_data] ShipViewsImportJob") }

      perform
    end

    test "syncs one model even when its listing has not changed" do
      @model.update!(ship_views_digest: "listing-1")
      publish({"flight_top.png" => PNG})

      perform(@model.id)

      assert @model.top_view.attached?
    end

    test "syncs only the given model" do
      other = create(:model)
      publish({"flight_top.png" => PNG}, slug: other.slug)

      perform(@model.id)

      assert_not other.reload.top_view.attached?
      assert_equal ["ship-views/index.json"], @client.api_requests.map { |request| request[:params][:key] }
    end

    test "does nothing without a bucket" do
      ::ScData::ShipViewsStore.stubs(:configured?).returns(false)
      ::ScData::ShipViewsStore.expects(:new).never

      perform
    end

    test "is scheduled" do
      schedule = YAML.safe_load(ERB.new(Rails.root.join("config/sidekiq_schedule.yml").read).result)

      assert_equal "ScData::ShipViewsImportJob", schedule.dig("sc_data_ship_views_import_job", "class")
    end
  end
end
