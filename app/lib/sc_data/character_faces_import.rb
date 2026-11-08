# frozen_string_literal: true

module ScData
  # Attaches a body's face library: the header and the two arrays a viewer
  # blends a character file's head from. The build is named only while all
  # three of its files are on the body, so a viewer never pairs a header with
  # the arrays of another build.
  class CharacterFacesImport
    include RenderImport

    FIELDS = {"index.json" => "face_index", "library.bin" => "face_positions", "normals.bin" => "face_normals"}.freeze

    def initialize(store)
      @store = store
    end

    # The fields it attached.
    def call(body, faces)
      files = faces["files"].slice(*FIELDS.keys)
      digest = Digest::MD5.hexdigest([faces["library"], files.sort].to_json)
      fields = (body.faces_digest == digest) ? [] : import(@store, body, faces["path"], digest, listing: {"files" => files})

      # Half a build -- one file in, another not -- names none: a viewer would
      # pair the new header with the old arrays.
      face_library = (body.faces_digest == digest) ? faces["library"] : nil
      body.update_columns(face_library:) if body.face_library != face_library

      fields
    end

    private def field_for(name) = FIELDS[name]

    private def render_metadata(_record, _field) = {}

    private def render_md5s_column = :face_md5s

    private def render_digest_column = :faces_digest

    private def log(level, message)
      Rails.logger.public_send(level, "[sc_data] CharacterFacesImport #{message}")
    end
  end
end
