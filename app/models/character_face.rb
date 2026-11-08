# frozen_string_literal: true

# A character a user exported from the game's character creator, kept as the
# exact file they uploaded so a download gives back what the game loads. What
# the file says about itself is stored beside it: the face library build it
# was saved against (`dna_stamp`), which body it is for, its format and the
# game version it was uploaded under.
#
# Anyone holding the token sees the character and can download the file, which
# is how an outfit share link carries it.
class CharacterFace < ApplicationRecord
  MAX_PER_USER = 20

  # Game files are 4 KB, zero-padded.
  MAX_FILE_SIZE = 64.kilobytes

  belongs_to :user

  has_many :outfits, dependent: :nullify

  has_one_attached :chf

  has_secure_token :token, length: 24

  # A file that could not be read is the one thing to say about an upload.
  with_options unless: :file_error? do
    validates :name, presence: true, length: {maximum: 100}, uniqueness: {scope: :user_id}
    validates :body, inclusion: {in: ItemViews::RIGGED_BODIES}
  end
  validate :file_readable
  validate :file_attached
  validate :body_expected
  validate :face_limit, on: :create

  before_validation :name_after_file, on: :create
  before_save :name_file

  # The body the uploader is dressing; a file for the other one is refused.
  attr_accessor :expected_body

  # What validation errors on `file` name.
  def file = chf

  # Reads an upload, refusing anything that is not a character file before it
  # is stored. Only as much is read as a character file can be.
  def file=(upload)
    @file_error = nil

    unless upload.respond_to?(:read)
      @file_error = :invalid
      return
    end

    if upload.respond_to?(:size) && upload.size.to_i > MAX_FILE_SIZE
      @file_error = :too_large
      return
    end

    bytes = upload.read(MAX_FILE_SIZE + 1).to_s.b
    if bytes.bytesize > MAX_FILE_SIZE
      @file_error = :too_large
      return
    end

    chf = Chf::Reader.read(bytes)

    self.body = Chf::Resolver.body_for(chf)
    self.dna_stamp = chf.dig("dna", "stamp")
    self.gender_hash = chf.dig("dna", "gender_hash")
    self.format_version = chf["format_version"]
    self.game_version = ::ScData::Source.find("live")&.version
    self.resolved = nil
    self.resolved_digest = nil
    if name.blank? && upload.respond_to?(:original_filename)
      @named_after_file = true
      self.name = File.basename(upload.original_filename.to_s, ".*").presence
    end
    @chf = chf

    self.chf = {io: StringIO.new(bytes), filename: "#{name.presence || "character"}.chf", content_type: "application/octet-stream"}
  rescue Chf::Reader::Invalid
    @file_error = :invalid
  end

  # The resolved character, refreshed when the catalogue or a face library
  # changed since it was last resolved. Nil until both are imported.
  def character(context = Chf::Context.current)
    return if context.nil? || !context.body?(body)

    if resolved_digest != context.digest || resolved.nil?
      spec = context.resolve(parsed)
      update_columns(resolved: spec, resolved_digest: context.digest) if persisted?
      self.resolved = spec
      self.resolved_digest = context.digest
    end

    context.served(resolved)
  rescue => e
    # An export the resolver cannot read still lets a share link hand out the
    # file; the character waits for an export it can.
    Rails.logger.error("[chf] #{id} could not be resolved: #{e.class}: #{e.message}")
    Appsignal.report_error(e)
    nil
  end

  private def parsed
    @chf ||= Chf::Reader.read(chf.download)
  end

  private def file_error? = @file_error.present?

  # The download is named after the character, whatever the upload was called.
  private def name_file
    return unless chf.attached?
    return unless new_record? || name_changed?

    filename = "#{name}.chf"
    if chf.blob.persisted?
      chf.blob.update!(filename:)
    else
      chf.blob.filename = filename
    end
  end

  # A name the uploader never typed: the file's, kept short and made unique
  # among their characters, so a second upload of the same file still saves.
  private def name_after_file
    return unless @named_after_file && name.present? && user

    base = name.truncate(90, omission: "")
    taken = user.character_faces.where("name = :base OR name LIKE :numbered", base:, numbered: "#{CharacterFace.sanitize_sql_like(base)} (%)").pluck(:name).to_set
    self.name = base
    self.name = "#{base} (#{(2..).find { |n| !taken.include?("#{base} (#{n})") }})" if taken.include?(base)
  end

  private def file_readable
    errors.add(:file, @file_error) if @file_error
  end

  private def file_attached
    errors.add(:file, :blank) unless @file_error || chf.attached?
  end

  private def body_expected
    return if expected_body.blank? || body.blank? || expected_body == body

    errors.add(:file, :other_body)
  end

  private def face_limit
    return if user.nil? || user.character_faces.count < MAX_PER_USER

    errors.add(:base, :limit_reached, count: MAX_PER_USER)
  end
end
