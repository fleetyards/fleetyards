# frozen_string_literal: true

module ActiveStorageVariants
  extend ActiveSupport::Concern

  REPRESENTATION_SIZES = {
    small: {resize_to_limit: [500, 500], saver: {quality: 80}},
    medium: {resize_to_limit: [1000, 1000], saver: {quality: 90}},
    large: {resize_to_limit: [2000, 2000], saver: {quality: 90}},
    xlarge: {resize_to_limit: [3000, 3000]}
  }.freeze

  included do
    after_commit :preprocess_representations, if: :has_new_attachments?
  end

  def preprocess_representations
    image_attachments.each do |name|
      attachment = send(name)
      next unless attachment.attached? && attachment.representable?

      PreprocessRepresentationsJob.perform_async(attachment.blob.id)
    end
  end

  private

  def image_attachments
    self.class.reflect_on_all_attachments
      .select { |a| a.macro == :has_one_attached }
      .map(&:name)
      .select { |name| send(name).attached? && send(name).representable? }
  end

  def has_new_attachments?
    self.class.reflect_on_all_attachments
      .select { |a| a.macro == :has_one_attached }
      .map(&:name)
      .any? { |name| attachment_changes.key?(name.to_s) }
  end
end
