# frozen_string_literal: true

module Youtube
  class VideoLoader
    attr_accessor :base_url, :channel_id, :api_key

    def initialize
      @base_url = 'https://www.googleapis.com/youtube/v3/activities'
      @channel_id = 'UCTeLqJq1mXUX5WWoNXLmOIA'
      @api_key = Rails.application.secrets[:google_youtube_api_key]
    end

    def update
      return if @api_key.blank?

      activities = fetch_activities

      return if activities.blank?

      activities['items'].map do |item|
        item['contentDetails']['upload']
      end.compact.each do |item|
        YoutubeUpdate.find_or_create_by(video_id: item['videoId'])
      end
    end

    private def fetch_activities
      response = Typhoeus.get("#{@base_url}?part=contentDetails&channelId=#{@channel_id}&key=#{@api_key}")

      return {} unless response.success?

      begin
        JSON.parse(response.body)
      rescue JSON::ParserError => e
        Raven.capture_exception(e)
        Rails.logger.error "Spreadsheet Data could not be parsed: #{response.body}"
        {}
      end
    end
  end
end
