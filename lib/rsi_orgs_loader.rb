# frozen_string_literal: true

class RsiOrgsLoader
  attr_accessor :base_url

  def initialize(options = {})
    @base_url = options[:base_url] || "https://robertsspaceindustries.com"
  end

  def fetch(sid)
    data = fetch_org_data(sid)

    OpenStruct.new(data) if data.present?
  end

  private def fetch_org_data(sid)
    response = Typhoeus.get("#{base_url}/orgs/#{sid}")
    return if response.code != 200
    page = Nokogiri::HTML(response.body)
    org_box = page.css('#organization')
    org_data = {}
    org_data[:name] = org_box.css('.heading h1').text.delete('/').gsub(sid.upcase, '').strip
    org_data[:sid] = sid.downcase
    org_data[:archetype] = org_box.css('.heading .tags .model').text.strip
    org_data[:commitment] = org_box.css('.heading .tags .commitment').text.strip
    org_data[:rpg] = org_box.css('.heading .tags .roleplay').text.strip.present?
    org_data[:exclusive] = org_box.css('.heading .tags .exclusive').text.strip.present?
    org_data[:main_activity] = org_box.css('.heading .focus .primary .content').text.strip
    org_data[:secondary_activity] = org_box.css('.heading .focus .secondary .content').text.strip
    org_data[:recruiting] = org_box.css('.join-us .bt-join').text.strip.present?
    org_data[:member_count] = org_box.css('.heading .logo .count').text.strip.gsub(' member', '').gsub(' members', '') || 1
    if org_box.css('.heading .logo img').present?
      org_data[:logo] = "https://robertsspaceindustries.com#{org_box.css('.heading .logo img')[0]['src']}"
    end
    org_data
  end
end
