# frozen_string_literal: true

require 'rsi_base_loader'

class RsiRoadmapLoader < RsiBaseLoader
  def fetch
    return if roadmap_maintenance_on?

    response = Typhoeus.get("#{base_url}/api/roadmap/v1/boards/1")
    return false, nil unless response.success?

    begin
      roadmap_data = JSON.parse(response.body)

      items = parse_roadmap(roadmap_data)

      # cleanup_changes

      items
    rescue JSON::ParserError => e
      Raven.capture_exception(e)
      Rails.logger.error "Roadmap Data could not be parsed: #{response.body}"
      []
    end
  end

  private def roadmap_maintenance_on?
    response = Typhoeus.get("#{base_url}/roadmap/board/1-Star-Citizen")

    !response.success?
  end

  # rubocop:disable Metrics/MethodLength
  private def parse_roadmap(data)
    roadmap_item_ids = []
    data['data']['releases'].each do |release|
      release['cards'].each do |card|
        item = RoadmapItem.find_or_create_by(rsi_id: card['id']) do |new_item|
          new_item.release = release_name(new_item, release)
          new_item.release_description = release['description']
          new_item.rsi_release_id =release['id']
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
          if image_url.present?
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
  end
  # rubocop:enable Metrics/MethodLength

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
