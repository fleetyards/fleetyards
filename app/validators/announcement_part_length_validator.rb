# frozen_string_literal: true

# Length, per element, for the ordered part lists an announcement carries.
#
# Its own validator rather than `length:`, which measures the array itself --
# a two-post thread would read as a length of 2 and pass any cap worth setting.
class AnnouncementPartLengthValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    platforms(record).each do |platform|
      Array(value).each_with_index do |part, index|
        length = platform.length(part.to_s)
        next if length <= platform.limit

        record.errors.add(
          attribute, :part_too_long,
          platform: platform_name(platform),
          position: index + 1, count: platform.limit, length:
        )
      end
    end
  end

  # The platforms this announcement is actually going to. A post can be legal
  # on Bluesky and too long for X, and telling an author their copy is too long
  # for a channel they did not select is noise.
  private def platforms(record)
    return [options[:platform]] if options[:platform]

    Array(options[:platforms]).filter_map do |key|
      next unless record.public_send(:"post_#{key}")

      Announcements::Platform.for(key)
    end
  end

  private def platform_name(platform)
    I18n.t("announcements.channels.#{platform.key}")
  end
end
