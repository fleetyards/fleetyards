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
