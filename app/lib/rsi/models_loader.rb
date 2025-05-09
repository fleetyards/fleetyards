module Rsi
  class ModelsLoader < ::Rsi::BaseLoader
    REFRENCE_MODEL_PRICE = 60

    attr_accessor :json_file_path, :hardpoints_loader, :manufacturers_loader, :pledge_store_loader

    def initialize(options = {})
      super

      self.json_file_path = "public/models.json"
      self.manufacturers_loader = ::Rsi::ManufacturersLoader.new
      self.hardpoints_loader = ::Rsi::HardpointsLoader.new
      self.pledge_store_loader = ::Rsi::PledgeStoreLoader.new
    end

    def all
      models = load_models

      models.each do |data|
        next if blocked(data["id"])

        sync_model(data)
      end

      cleanup_variants
    end

    def one(rsi_id)
      models = load_models

      model_data = models.find { |model| model["id"].to_s == rsi_id.to_s }

      return if model_data.blank?

      sync_model(model_data) unless blocked(rsi_id)

      cleanup_variants
    end

    def load_models
      response = fetch_remote("#{base_url}/ship-matrix/index?#{Time.zone.now.to_i}")

      return [] unless response.success?

      begin
        model_data = JSON.parse(response.body)
        model_data["data"]
      rescue JSON::ParserError => e
        Sentry.capture_exception(e)
        Rails.logger.error "Model Data could not be parsed: #{response.body}"
        []
      end
    end

    def sync_model(data)
      model_for_paint = find_model_for_paint(data)
      model = if model_for_paint.present?
        create_or_update_paint(data, model_for_paint.id)
      else
        create_or_update_model(data)
      end

      unless paint?(data)
        sleep 5 unless Rails.env.test?
        pledge_store_loader.run(model)
        manufacturers_loader.run(data["manufacturer"], model)
        hardpoints_loader.run(data["compiled"], model)
      end

      model.hidden = false

      model.save!
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    private def create_or_update_model(data)
      model = Model.find_by(rsi_id: data["id"])
      if model.blank?
        sc_identifier = resolve_sc_identifier(data)

        model = Model.find_by(sc_identifier: sc_identifier) if sc_identifier.present?
      end
      model = Model.create!(rsi_id: data["id"], name: strip_name(data["name"])) if model.blank?

      updates = {
        rsi_id: data["id"],
        rsi_chassis_id: data["chassis_id"],
        last_updated_at: new_time_modified(data)
      }

      if model_updated(model, data) || model.production_status.blank?
        updates[:production_status] = data["production_status"]
        updates[:production_note] = data["production_note"]
      end

      %w[length beam height mass].each do |attr|
        updates["rsi_#{attr}"] = data[attr].to_d
        updates[attr.to_sym] = data[attr].to_d if (model_updated(model, data) && data[attr].to_d != model.send(:"rsi_#{attr}").to_d) || model.send(attr).blank? || model.send(attr).zero?
      end

      updates[:rsi_description] = data["description"]
      updates[:description] = data["description"] if (model_updated(model, data) && data["description"] != model.rsi_description) || model.description.blank?

      updates[:rsi_cargo] = nil_or_decimal(data["cargocapacity"])
      updates[:cargo] = nil_or_decimal(data["cargocapacity"]) if (model_updated(model, data) && nil_or_decimal(data["cargocapacity"]) != model.rsi_cargo) || model.cargo.blank? || model.cargo.zero?

      %w[max_crew min_crew scm_speed].each do |attr|
        updates["rsi_#{attr}"] = nil_or_decimal(data[attr])
        updates[attr.to_sym] = nil_or_decimal(data[attr]) if (model_updated(model, data) && nil_or_decimal(data[attr]) != model.send(:"rsi_#{attr}")) || model.send(attr).blank? || model.send(attr).zero?
      end

      updates[:rsi_max_speed] = nil_or_decimal(data["afterburner_speed"])
      updates[:max_speed] = nil_or_decimal(data["afterburner_speed"]) if model_updated(model, data) && nil_or_decimal(data["afterburner_speed"]) != model.rsi_max_speed || model.rsi_max_speed.blank? || model.rsi_max_speed.zero?

      updates[:rsi_pitch] = nil_or_decimal(data["pitch_max"])
      updates[:pitch] = nil_or_decimal(data["pitch_max"]) if model_updated(model, data) && nil_or_decimal(data["pitch_max"]) != model.rsi_pitch || model.rsi_pitch.blank? || model.rsi_pitch.zero?
      updates[:rsi_yaw] = nil_or_decimal(data["yaw_max"])
      updates[:yaw] = nil_or_decimal(data["yaw_max"]) if model_updated(model, data) && nil_or_decimal(data["yaw_max"]) != model.rsi_yaw || model.rsi_yaw.blank? || model.rsi_yaw.zero?
      updates[:rsi_roll] = nil_or_decimal(data["roll_max"])
      updates[:roll] = nil_or_decimal(data["roll_max"]) if model_updated(model, data) && nil_or_decimal(data["roll_max"]) != model.rsi_roll || model.rsi_roll.blank? || model.rsi_roll.zero?

      updates[:ground] = true if data["type"] == "ground" && model_updated(model, data) && data["type"] != model.classification

      %w[size focus].each do |attr|
        updates["rsi_#{attr}"] = data[attr]
        updates[attr] = data[attr] if (model_updated(model, data) && data[attr] != model.send(:"rsi_#{attr}")) || model.send(:"rsi_#{attr}").blank?
      end

      updates[:rsi_classification] = data["type"]
      updates[:classification] = data["type"] if (model_updated(model, data) && data["type"] != model.rsi_classification) || model.classification.blank?

      updates[:rsi_store_url] = data["url"]
      updates[:store_url] = data["url"] if (model_updated(model, data) && data["url"] != model.rsi_store_url) || model.store_url.blank?

      updates[:rsi_name] = data["name"].strip
      updates[:name] = strip_name(data["name"]) if (model_updated(model, data) && data["name"] != model.rsi_name) || model.name.blank?

      model.update(updates.merge(update_reason: :rsi_loader))

      load_store_image(model, data["media"][0])

      model
      # rescue ActiveRecord::RecordInvalid => e
      #   puts "Error: #{e.message}"
      #   puts "Data: #{data.inspect}"
      #   raise e
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    # rubocop:disable Metrics/CyclomaticComplexity
    private def create_or_update_paint(data, model_id)
      paint = ModelPaint.find_or_create_by!(rsi_id: data["id"])

      updates = {
        last_updated_at: new_time_modified(data),
        model_id:
      }

      updates[:rsi_description] = data["description"]
      updates[:description] = data["description"] if (model_updated(paint, data) && data["description"] != paint.rsi_description) || paint.description.blank?

      updates[:rsi_store_url] = data["url"]
      updates[:store_url] = data["url"] if (model_updated(paint, data) && data["url"] != paint.rsi_store_url) || paint.store_url.blank?

      if model_updated(paint, data) || paint.production_status.blank?
        updates[:production_status] = data["production_status"]
        updates[:production_note] = data["production_note"]
      end

      updates[:rsi_name] = data["name"].strip
      updates[:name] = strip_name(data["name"]) if (model_updated(paint, data) && data["name"] != paint.rsi_name) || paint.name.blank?

      paint.update(updates)

      load_store_image(paint, data["media"][0])

      paint
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    # rubocop:disable Metrics/CyclomaticComplexity
    private def load_store_image(model, media_data)
      return if Rails.env.test? || (model.rsi_store_image.present? && model.store_images_updated_at >= store_images_updated_at(media_data))

      model.store_images_updated_at = media_data["time_modified"]

      store_image_url = media_data["images"]["store_hub_large"]
      store_image_url = "#{base_url}#{store_image_url}" unless store_image_url.starts_with?("https")

      return if store_image_url.blank?

      image_url = store_image_url.gsub("store_hub_large", "source")

      model.remote_rsi_store_image_url = image_url
      model.remote_store_image_url = image_url if model.store_image.blank?
      model.save
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    private def find_model_for_paint(data)
      mapping = paint_mapping.find { |item| item[:rsi_id] == data["id"].to_i }

      return if mapping.blank?

      model_rsi_id = mapping[:model_rsi_id]

      return if model_rsi_id.blank?

      Model.find_by(rsi_id: model_rsi_id)
    end

    private def store_images_updated_at(media_data)
      Time.zone.parse(media_data["time_modified"])
    rescue
      nil
    end

    private def new_time_modified(data)
      Time.zone.parse(data["time_modified.unfiltered"])
    rescue ArgumentError
      nil
    end

    private def model_updated(model, data)
      model.last_updated_at.blank? || model.last_updated_at < new_time_modified(data)
    end

    private def paint?(data)
      paint_mapping.any? { |item| item[:rsi_id] == data["id"].to_i }
    end

    # rubocop:disable Metrics/MethodLength
    private def paint_mapping
      [
        {
          # Carrack
          rsi_id: 206,
          model_rsi_id: 62
        }, {
          # Ballista
          rsi_id: 185,
          model_rsi_id: 183
        }, {
          rsi_id: 184,
          model_rsi_id: 183
        }, {
          # Caterpillar
          rsi_id: 194,
          model_rsi_id: 24
        }, {
          rsi_id: 125,
          model_rsi_id: 24
        }, {
          # Phoenix
          rsi_id: 156,
          model_rsi_id: 49
        }, {
          # Cutlass
          rsi_id: 193,
          model_rsi_id: 56
        }, {
          # Hammerhead
          rsi_id: 195,
          model_rsi_id: 151
        }, {
          # Reclaimer
          rsi_id: 196,
          model_rsi_id: 51
        }, {
          # Mole
          rsi_id: 202,
          model_rsi_id: 201
        }, {
          rsi_id: 203,
          model_rsi_id: 201
        }, {
          # Mustang
          rsi_id: 172,
          model_rsi_id: 65
        }, {
          # Nautilus
          rsi_id: 187,
          model_rsi_id: 186
        }, {
          # Archimedes
          rsi_id: 207,
          model_rsi_id: 104
        }, {
          # Valkyrie
          rsi_id: 171,
          model_rsi_id: 169
        }
      ]
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/MethodLength
    private def blocklist
      [{
        rsi_id: 205,
        replacements: [{
          rsi_id: 62,
          paint_rsi_id: 205
        }, {
          rsi_id: 192
        }]
      }, {
        rsi_id: 204,
        replacements: [{
          rsi_id: 62
        }, {
          rsi_id: 192
        }]
      }]
    end
    # rubocop:enable Metrics/MethodLength

    private def blocked(rsi_id)
      blocklist.find { |item| item[:rsi_id] == rsi_id.to_i }
    end

    private def cleanup_variants
      cleanup_paints
      cleanup_blocked
    end

    private def cleanup_paints
      ModelPaint.where.not(rsi_id: nil).find_each do |paint|
        model = Model.find_by(rsi_id: paint.rsi_id)
        next if model.blank?

        Vehicle.where(model_id: model.id).find_each do |vehicle|
          vehicle.update(model_id: paint.model_id, model_paint_id: paint.id)
        end

        model.destroy
      end
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    private def cleanup_blocked
      blocklist.each do |item|
        model = Model.find_by(rsi_id: item[:rsi_id])
        next if model.blank?

        replacements = item[:replacements].map { |replacement| replacement.merge(model: Model.find_by!(rsi_id: replacement[:rsi_id])) }

        Vehicle.where(model_id: model.id, loaner: false).find_each do |vehicle|
          next if replacements.first[:model].blank?

          vehicle.update(model_id: replacements.first[:model].id)
          replacements.each_with_index do |replacement, index|
            next if index.zero?

            replacement_model = replacement[:model]
            next if replacement_model.blank?

            paint = ModelPaint.find_by!(rsi_id: replacement[:paint_rsi_id]) if replacement[:paint_rsi_id].present?

            Vehicle.create(model_id: replacement_model.id, user_id: vehicle.user_id, model_paint_id: paint&.id)
          end
        end

        model.destroy
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength

    private def resolve_sc_identifier(item)
      sc_identifier_parts = [
        item.dig("manufacturer", "code"),
        item["name"].tr(" ", "_").downcase
      ].compact

      if sc_identifier_parts.size > 1
        return sc_identifier_parts.join("_").downcase
      end

      nil
    end
  end
end
