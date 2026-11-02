# frozen_string_literal: true

module ScData
  # Attaches the base bodies sc-tools publishes under `characters/` to a
  # CharacterBody per folder, creating the record the first time a body is
  # listed. Only the rest-pose body is taken; the animations are not used yet.
  class CharacterBodiesImportJob < ApplicationJob
    include RenderImport

    sidekiq_options queue: "loaders"

    FIELDS = {"body.glb" => "holo"}.freeze

    def perform
      return unless ::ScData::CharacterStore.configured?

      store = ::ScData::CharacterStore.new
      attached = {}

      store.characters.each do |key, entry|
        body = CharacterBody.find_or_create_by!(key:)

        next if body.views_digest == entry["files"]

        fields = import(store, body, key, entry["files"])
        attached[key] = fields if fields.any?
      rescue => e
        log(:error, "#{key} failed: #{e.class}: #{e.message}")
        Appsignal.report_error(e)
      end

      attached.each { |key, fields| log(:info, "attached #{key}: #{fields.join(", ")}") }
    end

    private def field_for(name) = FIELDS[name]

    private def render_metadata(_record, _field) = {}

    private def render_md5s_column = :view_md5s

    private def render_digest_column = :views_digest

    private def log(level, message)
      Rails.logger.public_send(level, "[sc_data] CharacterBodiesImportJob #{message}")
    end
  end
end
