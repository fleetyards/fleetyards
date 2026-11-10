# frozen_string_literal: true

# A processed variant is attached to its VariantRecord like any upload, so
# ActiveStorage queues an analysis that downloads the variant straight back
# from the bucket. Only the original's metadata is ever read, and on a bucket
# that answers bursts with SlowDown that download is the one to drop.
module CoreExtensions
  module SkipVariantAnalysis
    private def analyze_blob_later
      return if record_type == "ActiveStorage::VariantRecord"

      super
    end
  end
end

ActiveSupport.on_load(:active_storage_attachment) do
  prepend CoreExtensions::SkipVariantAnalysis
end
