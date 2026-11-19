# config/initializers/active_storage.rb

ActiveSupport.on_load(:active_storage_blob) do
  def self.ransackable_attributes(auth_object = nil)
    ["filename", "created_at", "service_name", "metadata"]
  end
end

ActiveSupport.on_load(:active_storage_attachment) do
  def self.ransackable_attributes(auth_object = nil)
    ["blob_id", "created_at", "id", "name", "record_id", "record_type"]
  end
end

# A USDZ is a zip archive, so Marcel names it application/zip from its bytes.
# AR Quick Look only takes the file under its own type, and the public bucket
# serves each file under the type it was stamped with at upload.
Marcel::MimeType.extend "model/vnd.usdz+zip", extensions: %w[usdz], parents: "application/zip"

# Marcel has no glTF type, so a holo the sc_data imports upload went up as
# application/octet-stream, which the CDN serves uncompressed. Under its own
# type it is compressed.
Marcel::MimeType.extend "model/gltf-binary", extensions: %w[glb], magic: [[0, "glTF"]]
Marcel::MimeType.extend "model/gltf+json", extensions: %w[gltf], parents: "application/json"
