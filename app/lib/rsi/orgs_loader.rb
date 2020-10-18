# frozen_string_literal: true

require 'rsi/base_loader'

module RSI
  class OrgsLoader < RSI::BaseLoader
    def fetch(sid)
      data = fetch_org_data(sid)
      return false, nil if data.blank?

      [true, OpenStruct.new(data)]
    end

    def fetch_citizen(handle)
      response = fetch_remote("#{base_url}/citizens/#{handle}")
      return false, nil unless response.success?

      citizen = parse_citizen(Nokogiri::HTML(response.body))

      success, orgs = fetch_orgs_for_citizen(handle)
      citizen.orgs = orgs if success

      [true, citizen]
    end

    def fetch_orgs_for_citizen(handle)
      response = fetch_remote("#{base_url}/citizens/#{handle}/organizations")
      return false, nil unless response.success?

      [true, parse_citizen_orgs(Nokogiri::HTML(response.body))]
    end

    private def parse_citizen(page)
      user = RsiUser.new
      page.css('.info .value').each_with_index do |value, index|
        user.username = value.text.strip if index.zero?
        user.handle = value.text.strip if index == 1
        user.title = value.text.strip if index == 2
      end
      user.avatar = parse_image(page.css('.profile .thumb img'))
      user.bio = page.css('.profile-content .bio').text.strip if page.css('.profile-content .bio').present?
      user.citizen_record = page.css('.citizen-record .value').text.strip
      page.css('.profile-content > .left-col .value').each_with_index do |value, index|
        if index.zero?
          user.enlisted = value.text.strip
        elsif index == 1
          user.location = value.text.squish.strip
        elsif index == 2
          user.languages = value.text.squish.strip
        end
      end

      user
    end

    private def parse_citizen_orgs(page)
      orgs = []

      page.css('.orgs-content .org').each do |org_box|
        org_box.css('.info .entry .value').each_with_index do |value, index|
          text = value.text.squish!

          orgs << text if index == 1
        end
      end

      orgs.reject(&:empty?)
    end

    private def fetch_org_data(sid)
      response = fetch_remote("#{base_url}/orgs/#{sid}")
      return if response.code != 200

      page = Nokogiri::HTML(response.body)
      org_box = page.css('#organization')
      {
        name: org_box.css('.heading h1').text.split('/').first.strip,
        sid: sid.downcase,
        archetype: org_box.css('.heading .tags .model').text.strip,
        commitment: org_box.css('.heading .tags .commitment').text.strip,
        rpg: org_box.css('.heading .tags .roleplay').text.strip.present?,
        exclusive: org_box.css('.heading .tags .exclusive').text.strip.present?,
        main_activity: org_box.css('.heading .focus .primary .content').text.strip,
        secondary_activity: org_box.css('.heading .focus .secondary .content').text.strip,
        recruiting: org_box.css('.join-us .bt-join').text.strip.present?,
        member_count: org_box.css('.heading .logo .count').text.strip.gsub(' members', '').gsub(' member', '').to_i || 1,
        logo: parse_image(org_box.css('.heading .logo img')),
        background: parse_background_image(page.css('#post-background')),
        banner: parse_image(org_box.css('.heading .banner img')),
      }
    end

    private def parse_background_image(element)
      div = element&.first || {}
      return if div.blank? || div.to_h.fetch('style', nil).blank?

      background_url = div.to_h.fetch('style', '').scan(/background-image:url\('(.*)'\);/).last&.first
      "#{base_url}#{background_url}"
    end

    private def parse_image(element)
      img = element&.first || {}
      return if img.blank? || img.to_h.fetch('src', nil).blank?

      "#{base_url}#{img.to_h.fetch('src', nil)}"
    end
  end
end
