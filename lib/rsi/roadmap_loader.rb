# frozen_string_literal: true

require 'rsi/base_loader'

# loader = ::RSI::RoadmapLoader.new; ENV['RSI_LOAD_FROM_FILE'] = 'true'; loader.fetch

module RSI
  class RoadmapLoader < ::RSI::BaseLoader
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
      return JSON.parse(File.read(json_file_path))['data']['releases'] if (Rails.env.test? || ENV['CI'] || ENV['RSI_LOAD_FROM_FILE']) && File.exist?(json_file_path)

      response = fetch_remote("#{base_url}/api/roadmap/v1/boards/1?#{Time.zone.now.to_i}")

      return [] unless response.success?

      begin
        roadmap_data = JSON.parse(response.body)
        File.open(json_file_path, 'w') do |f|
          f.write(roadmap_data.to_json)
        end
        roadmap_data['data']['releases']
      rescue JSON::ParserError => e
        Raven.capture_exception(e)
        Rails.logger.error "Roadmap Data could not be parsed: #{response.body}"
        []
      end
    end

    private def roadmap_maintenance_on?
      return false if Rails.env.test? || ENV['CI'] || ENV['RSI_LOAD_FROM_FILE']

      response = fetch_remote("#{base_url}/roadmap/board/1-Star-Citizen?#{Time.zone.now.to_i}")

      !response.success?
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    private def parse_roadmap(data)
      roadmap_item_ids = []
      data.each do |release|
        release['cards'].each do |card|
          item = RoadmapItem.find_or_create_by(rsi_id: card['id']) do |new_item|
            new_item.release = release_name(new_item, release)
            new_item.release_description = release['description']
            new_item.rsi_release_id = release['id']
            new_item.released = release['released'].zero? ? false : true
            new_item.rsi_category_id = card['category_id']
            new_item.name = card['name']
            new_item.description = card['description']
            new_item.body = card['body']
            new_item.tasks = card['tasks']
            new_item.inprogress = card['inprogress']
            new_item.completed = card['completed']
            new_item.active = true
          end

          item.update!(
            release: release_name(item, release),
            release_description: release['description'],
            rsi_release_id: release['id'],
            released: release['released'].zero? ? false : true,
            rsi_category_id: card['category_id'],
            name: card['name'],
            description: card['description'],
            body: card['body'],
            tasks: card['tasks'],
            inprogress: card['inprogress'],
            completed: card['completed'],
            active: true
          )

          roadmap_item_ids << item.id

          if item.store_image.blank?
            image_url = card['thumbnail']['urls']['source']
            image_url = "#{base_url}#{image_url}" unless image_url.starts_with?('https')
            if image_url.present? && !Rails.env.test? && !ENV['CI'] && !ENV['RSI_LOAD_FROM_FILE']
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

      RoadmapItem.where.not(id: roadmap_item_ids).find_each do |roadmap_item|
        roadmap_item.update(active: false)
      end

      roadmap_item_ids
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity

    private def strip_roadmap_name(name)
      strip_name(name).gsub(/(?:Improvements|Update|Rework|Revision)/, '').strip
    end

    private def release_name(item, release)
      new_release_name = release['name'].strip
      old_release_name = (item.release || '').strip
      return item.release if new_release_name == "#{old_release_name}.0" || old_release_name == "#{new_release_name}.0"

      release['name']
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
          updated_at = roadmap_item.reload.versions.last&.created_at || (Time.zone.now - 8.days)
          roadmap_item.update(updated_at: updated_at)
        else
          changes = item.changeset.except('release')
          changes = changes.to_hash if changes.is_a?(HashWithIndifferentAccess)
          changes = ::YAML.dump(changes)

          item.update(object_changes: changes)
        end
      end
    end
  end
end
