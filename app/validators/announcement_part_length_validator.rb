# frozen_string_literal: true

# Length, per element, for the ordered part lists an announcement carries.
#
# Its own validator rather than `length:`, which measures the array itself --
# a two-post thread would read as a length of 2 and pass any cap worth setting.
class AnnouncementPartLengthValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    maximum = options.fetch(:maximum)

    Array(value).each_with_index do |part, index|
      next if part.to_s.length <= maximum

      record.errors.add(
        attribute, :part_too_long,
        position: index + 1, count: maximum, length: part.to_s.length
      )
    end
  end
end
