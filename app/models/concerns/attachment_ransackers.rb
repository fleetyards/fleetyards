# frozen_string_literal: true

# Ransack builds its conditions from columns, and an attachment is not one --
# left alone, a `store_image_blank` term is dropped without an error and the
# list comes back unfiltered. The ransacker stands in for the missing column
# with the id of the attachment row, or NULL when nothing is attached, which is
# what the `blank` and `present` predicates test.
#
# The generated name still has to be whitelisted in `ransackable_attributes`.
module AttachmentRansackers
  extend ActiveSupport::Concern

  class_methods do
    def ransack_attachment(*names)
      record_type = base_class.name
      table = table_name

      names.each do |name|
        ransacker(name) do
          Arel.sql(
            "(SELECT CAST(active_storage_attachments.id AS TEXT) FROM active_storage_attachments " \
            "WHERE active_storage_attachments.record_type = '#{record_type}' " \
            "AND active_storage_attachments.record_id = #{table}.id " \
            "AND active_storage_attachments.name = '#{name}')"
          )
        end
      end
    end
  end
end
