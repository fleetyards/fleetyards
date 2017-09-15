# frozen_string_literal: true

class RsiOrgsLoader
  attr_accessor :base_url

  def initialize(options = {})
    @base_url = options[:base_url] || "https://robertsspaceindustries.com"
  end

  def fetch(sid)
    data = fetch_org_data(sid)

    return if data.blank?

    save_org(data)
  end

  def for_handle(handle)
    sids = fetch_org_sids(handle)

    orgs_data = []
    sids.each do |sid|
      orgs_data << fetch_org_data(sid)
    end

    orgs = []
    orgs_data.each do |org_data|
      orgs << save_org(org_data)
    end

    orgs
  end

  def for_citizen(user)
    sids = fetch_org_sids(user.rsi_handle)

    orgs_data = []
    sids.each do |sid|
      orgs_data << fetch_org_data(sid)
    end

    orgs = []
    orgs_data.each do |org_data|
      orgs << save_org(org_data)
    end

    RsiAffiliation.where(user_id: user.id).destroy_all
    orgs.each_with_index do |org, index|
      affiliation = RsiAffiliation.find_or_initialize_by(rsi_org_id: org.id, user_id: user.id)
      affiliation.main = index.zero?
      affiliation.save
    end

    orgs
  end

  private def fetch_org_sids(handle)
    sids = []

    response = Typhoeus.get("#{base_url}/citizens/#{handle}/organizations")
    return sids if response.code != 200

    page = Nokogiri::HTML(response.body)
    page.css('.orgs-content .org .info .entry:nth-child(2) .value').each do |sid_item|
      sids << sid_item.text.strip
    end

    sids
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

    if org_box.css('.heading .logo img').present?
      org_data[:logo] = "https://robertsspaceindustries.com#{org_box.css('.heading .logo img')[0]['src']}"
    end

    org_data
  end

  private def save_org(org_data)
    org = RsiOrg.find_or_initialize_by(name: org_data[:name])

    org.sid = org_data[:sid]
    org.archetype = org_data[:archetype]
    org.main_activity = org_data[:main_activity]
    org.secondary_activity = org_data[:secondary_activity]
    org.recruiting = org_data[:recruiting]
    org.rpg = org_data[:rpg]
    org.exclusive = org_data[:exclusive]
    org.commitment = org_data[:commitment]
    org.logo = org_data[:logo]

    org.save

    org
  end
end
