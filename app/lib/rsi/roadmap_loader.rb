# frozen_string_literal: true

require 'rsi/base_loader'

module Rsi
  class RoadmapLoader < ::Rsi::BaseLoader
    attr_accessor :json_file_path

    def initialize(options = {})
      super

      @json_file_path = 'public/roadmap.json'
    end

    def fetch
      return if roadmap_maintenance_on?

      roadmap_data = load_roadmap_data

      parse_roadmap(roadmap_data)
    end

    def load_roadmap_data
      return JSON.parse(File.read(json_file_path))['data']['releases'] if prevent_extra_server_requests? && File.exist?(json_file_path)

      response = fetch_remote("#{base_url}/api/roadmap/v1/boards/1?#{Time.zone.now.to_i}")

      return [] unless response.success?

      begin
        roadmap_data = JSON.parse(response.body)
        File.write(json_file_path, roadmap_data.to_json)
        roadmap_data['data']['releases']
      rescue JSON::ParserError => e
        Sentry.capture_exception(e)
        Rails.logger.error "Roadmap Data could not be parsed: #{response.body}"
        []
      end
    end

    private def roadmap_maintenance_on?
      return false if prevent_extra_server_requests?

      response = fetch_remote("#{base_url}/roadmap/board/1-Star-Citizen?#{Time.zone.now.to_i}")

      !response.success?
    end

    # rubocop:disable Metrics/MethodLength
    private def parse_roadmap(data)
      roadmap_item_ids = []
      data.each do |release|
        release['cards'].each do |card|
          card_status = (card['status'] || '').strip
          item = RoadmapItem.find_or_create_by(rsi_id: card['id']) do |new_item|
            new_item.release = release_name(new_item, release)
            new_item.release_description = release['description']
            new_item.rsi_release_id = release['id']
            new_item.released = (card_status == 'Released')
            new_item.committed = (card_status == 'Committed')
            new_item.rsi_category_id = card['category_id']
            new_item.name = card['name']
            new_item.description = card['description']
            new_item.body = card['body']
            new_item.active = true
          end

          item.update!(
            release: release_name(item, release),
            release_description: release['description'],
            rsi_release_id: release['id'],
            released: (card_status == 'Released'),
            committed: (card_status == 'Committed'),
            rsi_category_id: card['category_id'],
            name: card['name'],
            description: card['description'],
            body: card['body'],
            active: true
          )

          roadmap_item_ids << item.id

          if item.store_image.blank?
            image_url = card.dig('thumbnail', 'urls', 'source')
            if image_url.present? && !prevent_extra_server_requests?
              image_url = "#{base_url}#{image_url}" unless image_url.starts_with?('https')
              item.remote_store_image_url = image_url
              item.save
            end
          end

          next unless item.rsi_category_id == RoadmapItem::MODELS_CATEGORY && item.model_id.blank?

          item.update(
            model: Model.where('name ILIKE ?', strip_roadmap_name(card['name'])).first
          )
        end
      end

      cleanup_items(roadmap_item_ids)

      roadmap_item_ids
    end
    # rubocop:enable Metrics/MethodLength

    private def strip_roadmap_name(name)
      name_mapping(strip_name(name).gsub(/(?:Improvements|Update|Rework|Revision)/, '').strip)
    end

    private def name_mapping(name)
      mapping = {
        'C2 Hercules Starlifter' => 'C2 Hercules',
        'M2 Hercules Starlifter' => 'M2 Hercules',
        'A2 Hercules Starlifter' => 'A2 Hercules',
        'Ares Starfighter Ion' => 'Ares Ion',
        'Ares Starfighter Inferno' => 'Ares Inferno'
      }

      return mapping[name] if mapping[name].present?

      name
    end

    private def release_name(item, release)
      new_release_name = if release['name'].count('.') > 1
                           release['name'].strip.chomp('.0')
                         else
                           release['name'].strip
                         end
      old_release_name = (item.release || '').strip

      return old_release_name if new_release_name == old_release_name

      new_release_name
    end

    private def cleanup_items(item_ids)
      return if item_ids.blank?

      RoadmapItem.where.not(id: item_ids).find_each do |roadmap_item|
        roadmap_item.update(active: false)
      end
    end

    private def cleanup_changes
      PaperTrail::Version.where(item_type: 'RoadmapItem').select do |item|
        item.changeset.key?('release')
      end.select do |item|
        changes = item.changeset['release']
        changes[0] == "#{changes[1]}.0" || changes[1] == "#{changes[0]}.0"
      end.each do |item|
        if item.changeset.keys.count == 1
          roadmap_item = item.item
          item.destroy
          updated_at = roadmap_item.reload.versions.last&.created_at || 8.days.ago
          roadmap_item.update(updated_at: updated_at)
        else
          changes = item.changeset.except('release')
          changes.to_hash if changes.is_a?(ActiveSupport::HashWithIndifferentAccess)
          changes = ::YAML.dump(changes)

          item.update(object_changes: changes)
        end
      end
    end
  end
end
