# frozen_string_literal: true

module ScData
  # Attaches the renders sc-tools publishes to the item-views bucket to the
  # component or piece of equipment whose game-file key the item is listed
  # under. Filenames follow the ship renders' rules; a name for a field an item
  # does not have -- a coloured, extended or landed view -- is skipped.
  #
  # Renders go live without review, so every run logs what it attached.
  #
  # Given a record, only that item is synced, and its listing is compared render
  # by render even when the digest says nothing changed, so a render detached in
  # the admin comes back. A view uploaded by hand over an imported render is
  # kept: the stored md5s still name the render it replaced.
  class ItemViewsImportJob < ApplicationJob
    include RenderImport

    sidekiq_options queue: "loaders"

    ITEM_CLASSES = %w[Component Equipment].freeze
    FIELDS = ItemViews::ATTACHMENT_NAMES.map(&:to_s).to_set.freeze

    def perform(record_type = nil, record_id = nil)
      return unless ::ScData::ItemViewsStore.configured?

      store = ::ScData::ItemViewsStore.new
      items = store.items

      if record_id
        target = record_type.constantize.find_by(id: record_id) if ITEM_CLASSES.include?(record_type)
        items = target&.sc_key ? items.select { |_path, entry| entry["scKey"] == target.sc_key } : {}
        log(:info, "no renders listed for #{record_type} #{record_id}") if items.empty?
      end

      records = records_for(items)
      paths_by_key = items.keys.group_by { |path| items[path]["scKey"] }
      attached = {}
      unknown = []

      items.each do |path, entry|
        record = records[path]

        if record.nil?
          unknown << (entry["scKey"] || path)
          next
        end

        next if target && record != target

        # Two folders claiming one item would replace each other's renders on
        # every run.
        if paths_by_key[entry["scKey"]].size > 1
          log(:warn, "#{entry["scKey"]} is listed under #{paths_by_key[entry["scKey"]].join(", ")}, skipped")
          next
        end

        next if record_id.nil? && record.item_views_digest == entry["files"]

        fields = import(store, record, path, entry["files"])
        attached[record.sc_key] = fields if fields.any?
      rescue => e
        # Left on the old digest, so the next run tries the item again.
        log(:error, "#{path} failed: #{e.class}: #{e.message}")
        Appsignal.report_error(e)
      end

      log(:info, "no item for #{unknown.size} keys: #{unknown.join(", ")}") if unknown.any?
      attached.each { |sc_key, fields| log(:info, "attached #{sc_key}: #{fields.join(", ")}") }
      log(:info, "attached #{attached.values.sum(&:size)} renders to #{attached.size} items")
    end

    # The record of every listed item. The loaders file a game-file key as
    # either a component or equipment, but each table is only unique on its
    # own, and a key both carry names neither.
    private def records_for(items)
      keys = items.values.pluck("scKey").compact

      by_sc_key = [Component, Equipment]
        .flat_map { |klass| klass.where(sc_key: keys).to_a }
        .group_by(&:sc_key)
        .filter_map do |sc_key, records|
          next [sc_key, records.first] if records.one?

          log(:warn, "#{sc_key} is both a component and equipment, skipped")
          nil
        end
        .to_h

      items.to_h { |path, entry| [path, by_sc_key[entry["scKey"]]] }
    end

    private def field_for(name)
      field = ShipViewFields.field_for(name)

      field if FIELDS.include?(field)
    end

    private def render_metadata(_record, _field) = {}

    private def render_md5s_column = :item_view_md5s

    private def render_digest_column = :item_views_digest

    private def log(level, message)
      Rails.logger.public_send(level, "[sc_data] ItemViewsImportJob #{message}")
    end
  end
end
