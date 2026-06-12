# frozen_string_literal: true

namespace :test_fixtures do
  desc "Regenerate Minitest fixtures (manufacturers + models) by running Rsi::ModelsLoader once. Must be run with RAILS_ENV=test."
  task generate_loader: :environment do
    abort "Refusing to run outside RAILS_ENV=test (current: #{Rails.env})" unless Rails.env.test?

    require "webmock"

    WebMock.enable!
    WebMock.disable_net_connect!(allow_localhost: true)

    matrix_body = File.read(Rails.root.join("test/fixtures/rsi/matrix.json"))
    pledge_store_data = JSON.parse(File.read(Rails.root.join("test/fixtures/rsi/pledge_store.json")))

    WebMock.stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/ship-matrix/index.*})
      .to_return(status: 200, body: matrix_body)
    WebMock.stub_request(:post, %r{\Ahttps://robertsspaceindustries.com/graphql})
      .to_return do |request|
        body = JSON.parse(request.body)
        chassis_id = body.first.dig("variables", "query", "ships", "chassisId", 0)
        resources = pledge_store_data[chassis_id.to_s] || []
        {status: 200, body: [{data: {store: {search: {resources: resources}}}}].to_json, headers: {"Content-Type" => "application/json"}}
      end

    [Vehicle, ModelSnubCraft, Image, Video, Hardpoint, ModelPaint, Model, Manufacturer].each(&:delete_all)

    Rsi::ModelsLoader.new.all
    load Rails.root.join("db/seeds/01_manual_models.rb")

    fixtures_dir = Rails.root.join("test/fixtures/loader")
    FileUtils.mkdir_p(fixtures_dir)

    TestFixtures.dump_manufacturers(fixtures_dir.join("manufacturers.yml"))
    TestFixtures.dump_models(fixtures_dir.join("models.yml"))
    TestFixtures.dump_model_paints(fixtures_dir.join("model_paints.yml"))
    TestFixtures.dump_snub_crafts(fixtures_dir.join("model_snub_crafts.yml"))

    puts "Wrote fixtures:"
    puts "  manufacturers: #{Manufacturer.count}"
    puts "  models: #{Model.count}"
    puts "  model_paints: #{ModelPaint.count}"
    puts "  model_snub_crafts: #{ModelSnubCraft.count}"
  end
end

module TestFixtures
  module_function

  def fixture_key(prefix, slug, id)
    base = slug.presence || id
    "#{prefix}_#{base.to_s.tr("-", "_").gsub(/[^a-z0-9_]/i, "_").downcase}"
  end

  # Strip:
  # - id (Rails computes a stable ID from the fixture name)
  # - timestamps (Rails fills them)
  # - nil columns (default in schema)
  # Resulting YAML loads through stdlib YAML.safe_load and FK refs via
  # `manufacturer: <fixture_name>` resolve through the same identify() hash.
  def clean_attrs(attrs)
    attrs.except("id", "created_at", "updated_at").compact.transform_values { |v| primitive(v) }
  end

  def primitive(value)
    case value
    when ActiveSupport::TimeWithZone, Time, DateTime then value.utc.iso8601
    when Date then value.iso8601
    when BigDecimal then value.to_s("F")
    else value
    end
  end

  def dump_manufacturers(path)
    data = Manufacturer.order(:code).each_with_object({}) do |mfr, h|
      h[fixture_key("mfr", mfr.code, mfr.id)] = clean_attrs(mfr.attributes)
    end
    File.write(path, data.to_yaml(line_width: -1))
  end

  def dump_models(path)
    manufacturer_keys = Manufacturer.all.each_with_object({}) do |m, h|
      h[m.id] = fixture_key("mfr", m.code, m.id)
    end

    data = Model.order(:slug, :id).each_with_object({}) do |model, h|
      attrs = clean_attrs(model.attributes)
      attrs["manufacturer"] = manufacturer_keys[attrs.delete("manufacturer_id")]
      h[fixture_key("model", model.slug, model.id)] = attrs
    end
    File.write(path, data.to_yaml(line_width: -1))
  end

  def dump_model_paints(path)
    model_keys = Model.all.each_with_object({}) do |m, h|
      h[m.id] = fixture_key("model", m.slug, m.id)
    end

    data = ModelPaint.order(:slug, :id).each_with_object({}) do |paint, h|
      attrs = clean_attrs(paint.attributes)
      attrs["model"] = model_keys[attrs.delete("model_id")]
      h[fixture_key("paint", paint.slug, paint.id)] = attrs
    end
    File.write(path, data.to_yaml(line_width: -1))
  end

  def dump_snub_crafts(path)
    model_keys = Model.all.each_with_object({}) do |m, h|
      h[m.id] = fixture_key("model", m.slug, m.id)
    end

    data = ModelSnubCraft.order(:id).each_with_object({}) do |sc, h|
      attrs = clean_attrs(sc.attributes)
      attrs["model"] = model_keys[attrs.delete("model_id")]
      attrs["snub_craft"] = model_keys[attrs.delete("snub_craft_id")]
      h[fixture_key("snub", sc.id, sc.id)] = attrs
    end
    File.write(path, data.to_yaml(line_width: -1))
  end
end
