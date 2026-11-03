# frozen_string_literal: true

require "digest"
require "zlib"

module Overlay
  # Every component, equipment piece and ship of one game channel, in a single
  # gzipped file, plus the manifest that names it. The overlay downloads the
  # pair instead of walking the detail endpoints, which would take ~9,000
  # requests.
  #
  # Each record is rendered through the same partial its API detail page uses,
  # and `stats` is that payload with its descriptive keys taken out. That keeps
  # the export in step with the site: a field added to a serializer shows up
  # here without anyone touching this file.
  #
  # The bytes are deterministic -- items sorted by kind and slug, keys sorted,
  # no timestamp in the gzip header -- so an unchanged catalogue hashes the same
  # and the publisher can skip the upload.
  class Export
    SCHEMA = 1

    # Dropped from `stats` at the top level of each payload: what names,
    # describes or sells an item rather than measuring it. Whatever the
    # serializer adds later stays in.
    COMMON_META_KEYS = %w[
      id name slug description manufacturer media availability storeImage
      hidden retired createdAt updatedAt links
    ].freeze

    META_KEYS = {
      "component" => COMMON_META_KEYS + %w[
        scKey scRef category type subType grade size tags requiredTags catalogued
      ],
      "equipment" => COMMON_META_KEYS + %w[
        equipmentType itemType subType grade size
      ],
      "model" => COMMON_META_KEYS + %w[
        scIdentifier erkulIdentifier inGame classification adiMap foci fociLabels
        hasImages hasModules hasPaints hasUpgrades hasVideos lastUpdatedAt
        loaners holoToScale onSale playerOwnable ingameOnly pledgePrice price
        productionNote productionStatus rsiId rsiName rsiSlug brochure holo
        carriedBy
      ]
    }.freeze

    # Dropped at any depth: record ids, links and per-upload identifiers. The
    # last two would also change the hash without the data changing.
    NESTED_META_KEYS = %w[id signedId media storeImage description createdAt updatedAt availability links].freeze

    # Each kind is pictured as the site search pictures it, by the first of these
    # `media` entries it has.
    IMAGE_KEYS = {"component" => "component", "equipment" => "equipment", "model" => "ship"}.to_h do |kind, search_type|
      [kind, ::Catalogue::Search::IMAGES.fetch(search_type).map { |name| name.to_s.camelize(:lower) }]
    end.freeze

    Result = Data.define(:manifest, :items_gzip, :file_name) do
      def sha256 = manifest[:sha256]
    end

    def self.channels
      ::ScData::Source.configured.map(&:environment)
    end

    attr_reader :channel

    def initialize(channel)
      @channel = channel.to_s
    end

    def source
      @source ||= begin
        configured = ::ScData::Source.find(channel)
        raise ArgumentError, "no sc_data source configured for #{channel.inspect}" if configured.nil?

        configured.served
      end
    end

    def build
      items = ::ScData::Source.with(source) do
        I18n.with_locale(:en) { components + equipment + models }
      end

      items.sort_by! { |item| [item["kind"], item["slug"].to_s, item["id"].to_s] }

      json = JSON.generate(deep_sort({"schema" => SCHEMA, "items" => items}))
      gzip = gzip(json)
      sha256 = Digest::SHA256.hexdigest(gzip)
      file_name = "items.#{sha256.first(16)}.json.gz"

      manifest = {
        schema: SCHEMA,
        channel:,
        gameVersion: source.version,
        generatedAt: Time.current.utc.iso8601,
        file: file_name,
        sha256:,
        count: items.size
      }

      Result.new(manifest:, items_gzip: gzip, file_name:)
    end

    private def components
      Component.with_facts(true, source)
        .catalogued
        .where(Component.fact_sql(:hidden).eq(false))
        .where(Component.fact_sql(:category).not_eq("paints").or(Component.fact_sql(:category).eq(nil)))
        .includes(:manufacturer, ItemViews::DISPLAY_IMAGE_PRELOAD)
        .find_each.map do |component|
          payload = render("api/v1/components/component", component:, extended: true)

          item("component", payload,
            category: payload["category"],
            type: payload["type"],
            sub_type: payload["subType"],
            size: payload["size"],
            grade: payload["gradeLabel"].presence || payload["grade"],
            url: "#{FRONTEND_ENDPOINT}/components/#{component.slug}")
        end
    end

    private def equipment
      Equipment.visible(true, source)
        .includes(:manufacturer, ItemViews::DISPLAY_IMAGE_PRELOAD)
        .find_each.map do |equipment|
          payload = render("api/v1/equipment/equipment", equipment:, extended: true)

          item("equipment", payload,
            category: payload["equipmentType"],
            type: payload["itemType"],
            type_label: payload["itemTypeLabel"].presence || payload["equipmentTypeLabel"],
            sub_type: payload["subType"],
            size: payload["size"],
            grade: payload["grade"],
            url: "#{FRONTEND_ENDPOINT}/equipment/#{equipment.slug}")
        end
    end

    private def models
      Model.visible.active
        .includes(*Model.rendered_associations, *Model.attachment_preloads)
        .find_each.map do |model|
          payload = render("api/v1/models/model", model:, extended: true)

          item("model", payload,
            sc_key: payload["scIdentifier"],
            category: payload["classification"],
            type_label: payload["classificationLabel"],
            size: payload.dig("metrics", "size"),
            url: "#{FRONTEND_ENDPOINT}/ships/#{model.slug}")
        end
    end

    private def item(kind, payload, sc_key: payload["scKey"], category: nil, type: nil, type_label: nil, sub_type: nil, size: nil, grade: nil, url: nil)
      manufacturer = payload["manufacturer"]
      image = IMAGE_KEYS.fetch(kind).map { |key| payload.dig("media", key) }.find { |file| file?(file) }

      {
        "kind" => kind,
        "id" => payload["id"],
        "slug" => payload["slug"],
        "scKey" => sc_key,
        "name" => payload["name"],
        "manufacturer" => manufacturer && clean(manufacturer.slice("name", "code")),
        "category" => category,
        "type" => type,
        "typeLabel" => type_label,
        "subType" => sub_type,
        "size" => size&.to_s,
        "grade" => grade,
        "image" => image_url(image),
        "thumb" => thumb_url(image),
        "url" => url,
        "stats" => stats(kind, payload)
      }.reject { |_key, value| blank?(value) }
    end

    # Labels are matched against the whole payload before the meta keys go, so
    # `gradeLabel` leaves along with the `grade` it formats.
    private def stats(kind, payload)
      labels = payload.keys.select { |key| key.end_with?("Label") && payload.key?(key.delete_suffix("Label")) }

      clean(payload.except(*META_KEYS.fetch(kind), *labels)) || {}
    end

    # Nulls, empty strings and the containers they leave behind go, and so does
    # a `fooLabel` beside the `foo` it formats (or a `label` beside a `value`) --
    # the overlay renders units itself, and the label is the same number twice.
    private def clean(value)
      case value
      when Hash
        cleaned = value.each_with_object({}) do |(key, nested), result|
          next if NESTED_META_KEYS.include?(key)
          next if key.end_with?("Label") && value.key?(key.delete_suffix("Label"))
          next if key == "label" && value.key?("value")

          nested = clean(nested)
          result[key] = nested unless blank?(nested)
        end
        cleaned.presence
      when Array
        value.filter_map { |nested| clean(nested) }.presence
      else
        value
      end
    end

    private def blank?(value)
      value.nil? || value == "" || (value.respond_to?(:empty?) && value.empty?)
    end

    private def file?(file)
      file.is_a?(Hash) && file["url"].present?
    end

    private def image_url(file)
      return unless file?(file)

      file["mediumUrl"].presence || file["smallUrl"].presence || file["url"]
    end

    # The overlay lists dozens of results at once, too many to load at 1,000 px.
    private def thumb_url(file)
      return unless file?(file)

      file["smallUrl"].presence || file["mediumUrl"].presence || file["url"]
    end

    private def render(partial, **locals)
      JSON.parse(
        ApplicationController.renderer.render(partial:, locals:, formats: [:json], handlers: [:jbuilder])
      )
    end

    # Hardpoints are read without an order, so Postgres is free to hand them
    # back differently between runs; every other array is stored in order.
    UNORDERED_ARRAYS = %w[hardpoints].freeze

    private def deep_sort(value)
      case value
      when Hash
        value.keys.sort.to_h do |key|
          nested = deep_sort(value[key])
          nested = nested.sort_by { |entry| JSON.generate(entry) } if UNORDERED_ARRAYS.include?(key) && nested.is_a?(Array)

          [key, nested]
        end
      when Array then value.map { |nested| deep_sort(nested) }
      else value
      end
    end

    # Zlib stamps the current time into the header when mtime is left at 0,
    # which would give an unchanged catalogue a new hash on every run.
    private def gzip(json)
      io = StringIO.new("".b)
      writer = Zlib::GzipWriter.new(io, Zlib::BEST_COMPRESSION)
      writer.mtime = 1
      writer.write(json)
      writer.close
      io.string
    end
  end
end
