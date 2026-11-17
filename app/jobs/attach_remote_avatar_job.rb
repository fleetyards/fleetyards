# frozen_string_literal: true

# The picture is the provider's, not something the account holder picked, so
# it is fetched and stored after the sign-in rather than as part of it: a
# storage outage then costs a retry instead of the sign-in.
class AttachRemoteAvatarJob < ::ApplicationJob
  sidekiq_options queue: "default", retry: 5

  # The provider no longer serving the picture is not worth a retry.
  UNREACHABLE = [OpenURI::HTTPError, SocketError, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED].freeze

  def self.enqueue(user, url)
    return if url.blank?
    return if user.avatar.attached?

    perform_async(user.id, url)
  end

  def perform(user_id, url)
    user = User.find_by(id: user_id)
    return if user.nil? || user.avatar.attached?

    avatar_uri = URI.parse(url)
    return unless %w[http https].include?(avatar_uri.scheme)

    filename = "avatar#{File.extname(avatar_uri.path)}"
    content_type = Marcel::MimeType.for(name: filename)
    return if ActiveStorageVariants::VECTOR_CONTENT_TYPES.include?(content_type)

    io = begin
      avatar_uri.open(open_timeout: 5, read_timeout: 10)
    rescue *UNREACHABLE
      return
    end

    # Uploaded before it is attached: attaching to a saved user commits the
    # attachment first and uploads after, so a failed upload would leave an
    # avatar without a file that the retry then takes as already there.
    blob = ActiveStorage::Blob.create_and_upload!(io:, filename:, content_type:)
    user.avatar.attach(blob)
  rescue URI::InvalidURIError
    nil
  end
end
