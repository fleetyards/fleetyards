# frozen_string_literal: true

module RSI
  class NewsLoader
    attr_accessor :base_url

    def initialize
      @base_url = 'https://robertsspaceindustries.com'
    end

    def update
      news = fetch_news

      return if news.blank?

      news.each do |news_item|
        StarCitizenUpdate.find_or_create_by(slug: news_item[:slug]) do |new_news|
          new_news.title = news_item[:title]
          new_news.news_type = news_item[:type]
          new_news.news_sub_type = news_item[:sub_type]
          new_news.url = news_item[:url]
        end
      end
    end

    private def fetch_news
      response = Typhoeus.get("#{@base_url}/comm-link")

      return [] unless response.success?

      page = Nokogiri::HTML(response.body)

      news = []
      (page.css('.hub-blocks .hub-block') || []).each do |news_element|
        url = news_element['href']

        next if url.blank?

        url_parts = url.split('/')
        type = news_element.css('.type span').text
        sub_type = url_parts[2]
        slug = url_parts.last

        next if type == 'video' # Videos are fetched directly from YouTube

        news << {
          title: news_element.css('.title-holder .title').text,
          type: type,
          sub_type: sub_type,
          url: "#{@base_url}#{url}",
          slug: slug,
        }
      end

      news.reverse
    end
  end
end
