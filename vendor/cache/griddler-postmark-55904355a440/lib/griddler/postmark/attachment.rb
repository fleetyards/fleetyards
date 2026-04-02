module Griddler
  module Postmark
    class Attachment < ActionDispatch::Http::UploadedFile
      attr_accessor :content_id

      def initialize(hash)
        @content_id = hash[:content_id]
        super
      end

      def inline?
        content_id.present?
      end
    end
  end
end