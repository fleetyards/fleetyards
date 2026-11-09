# frozen_string_literal: true

module ScData
  # Attaches a body's default character: the character file the game's
  # customizer opens with, resolved like any player's.
  class CharacterDefaultImport
    include RenderImport

    FIELDS = {"default.chf" => "chf"}.freeze

    def initialize(store)
      @store = store
    end

    # The fields it attached.
    def call(body, default)
      files = default["files"].slice(*FIELDS.keys)
      digest = Digest::MD5.hexdigest(files.sort.to_json)
      return [] if body.default_digest == digest

      fields = import(@store, body, default["path"], digest, listing: {"files" => files})
      # A new file is resolved afresh.
      body.update_columns(resolved: nil, resolved_digest: nil) if fields.any?
      fields
    end

    private def field_for(name) = FIELDS[name]

    private def render_metadata(_record, _field) = {}

    private def render_md5s_column = :default_md5s

    private def render_digest_column = :default_digest

    private def log(level, message)
      Rails.logger.public_send(level, "[sc_data] CharacterDefaultImport #{message}")
    end
  end
end
