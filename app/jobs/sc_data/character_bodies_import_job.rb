# frozen_string_literal: true

module ScData
  # Attaches the rigged base bodies sc-tools publishes under `characters/` to a
  # CharacterBody per listed body, creating the record the first time a body
  # is listed: the rest-pose body and the clips that pose it.
  class CharacterBodiesImportJob < ApplicationJob
    include RenderImport

    sidekiq_options queue: "loaders"

    FIELDS = {"body.glb" => "holo", "animations.glb" => "animations"}.freeze

    def perform
      return unless ::ScData::CharacterStore.configured?

      store = ::ScData::CharacterStore.new
      attached = {}

      store.characters.each do |key, entry|
        body = CharacterBody.find_or_create_by!(key:)
        clips = entry["clips"].map { |clip| clip.slice("name", "static", "looping") }
        weapon_in_hand = entry["weapon_in_hand"]&.slice("bones", "helper")
        body.update_columns(clips:) if body.clips != clips
        body.update_columns(weapon_in_hand:) if body.weapon_in_hand != weapon_in_hand

        # The index has no digest of its own for a body, so its file list is.
        digest = Digest::MD5.hexdigest(entry["files"].sort.to_json)
        next if body.views_digest == digest

        fields = import(store, body, entry["path"], digest, listing: {"files" => entry["files"]})
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
