# frozen_string_literal: true

require "json"

class ModulesImporter
  include HangarModuleMapping

  def run
    modules = []

    Imports::HangarSync.find_each do |import|
      modules << extract_modules(import)
    end

    modules.flatten!
    modules.uniq!
    modules.compact!

    results = modules.map do |mod|
      import_module(mod)
    end

    results.flatten!

    {
      new: {
        count: results.count { |mod| mod[:new] && !mod[:error] },
        items: results.select { |mod| mod[:new] && !mod[:error] }
      },
      new_with_error: {
        count: results.count { |mod| mod[:new] && mod[:error] },
        items: results.select { |mod| mod[:new] && mod[:error] }
      },
      existing: {
        count: results.count { |mod| mod[:module_id].present? && !mod[:new] },
        items: results.select { |mod| mod[:module_id].present? && !mod[:new] }
      },
      model_not_found: {
        count: results.count { |mod| mod[:model_id].blank? },
        items: results.select { |mod| mod[:model_id].blank? }
      }
    }
  end

  def self.github_issue_body(results)
    lines = []

    lines << "## New Modules (#{results[:new][:count] || 0})"
    lines << ""
    if results[:new][:items].present?
      results[:new][:items].each do |mod|
        lines << "- **#{mod[:model_name]} #{mod[:name]}**"
      end
    else
      lines << "No new Modules found"
    end

    if results[:new_with_error][:items].present?
      lines << ""
      lines << "## New Modules with Errors (#{results[:new_with_error][:count]})"
      lines << ""
      results[:new_with_error][:items].each do |mod|
        lines << "- **#{mod[:model_name]} #{mod[:name]}**"
      end
    end

    if results[:model_not_found][:items].present?
      lines << ""
      lines << "## Missing Models (#{results[:model_not_found][:count]})"
      lines << ""
      results[:model_not_found][:items].each do |mod|
        lines << "- **#{mod[:model_name]} #{mod[:name]}**"
      end
    end

    lines.join("\n")
  end

  def list_modules(filter = nil)
    modules = []

    Imports::HangarSync.find_each do |import|
      modules << extract_modules(import)
    end

    modules.flatten!
    modules.uniq!
    modules.compact!

    modules.select do |mod|
      return true if filter.blank?

      mod[:model_name].include?(filter) || mod[:name].include?(filter)
    end
  end

  private def extract_modules(import)
    return if import.input.blank?

    imported_data = import.input
    return unless imported_data.is_a?(Array)

    imported_data.filter_map do |item|
      next if item["type"] != "component"

      mapped = component_mapping(item["name"])
      next if mapped.blank?

      {
        name: mapped[:module_name],
        model_names: mapped[:model_names],
        image: item["image"]
      }
    end
  rescue JSON::ParserError => e
    Sentry.capture_exception(e)
    Rails.logger.error "Modules Data could not be parsed: #{import.input}"
    nil
  end

  private def import_module(mod)
    models = Model.where(name: mod[:model_names])

    if models.empty?
      return mod[:model_names].map do |model_name|
        {
          new: false,
          module_id: nil,
          model_id: nil,
          model_name: model_name,
          name: mod[:name],
          error: false
        }
      end
    end

    model_module = nil
    found_names = models.pluck(:name)
    missing_names = mod[:model_names] - found_names

    results = missing_names.map do |model_name|
      {
        new: false,
        module_id: nil,
        model_id: nil,
        model_name: model_name,
        name: mod[:name],
        error: false
      }
    end

    results + models.map do |model|
      existing_module = model.modules.find_by("lower(model_modules.name) = :name OR model_modules.slug = :slug",
        name: mod[:name].downcase, slug: mod[:name].parameterize)

      if existing_module.present?
        next {
          new: false,
          module_id: existing_module.id,
          model_id: model.id,
          model_name: model.name,
          name: mod[:name],
          error: false
        }
      end

      model_module ||= ModelModule.create!(
        name: mod[:name],
        hidden: false,
        active: true
      )

      attach_store_image(model_module, mod[:image]) if mod[:image].present? && !model_module.store_image.attached?

      ModuleHardpoint.create!(
        model_id: model.id,
        model_module_id: model_module.id
      )

      {
        new: true,
        module_id: model_module.id,
        model_id: model.id,
        model_name: model.name,
        name: mod[:name],
        error: false
      }
    end.tap do
      enrich_from_sc_data(model_module) if model_module.present?
    end
  rescue => e
    Sentry.capture_exception(e)
    Rails.logger.error "Module could not be imported: #{mod[:name]}"
    [{
      new: true,
      module_id: nil,
      model_id: nil,
      model_name: mod[:model_names].first,
      name: mod[:name],
      error: true
    }]
  end

  private def attach_store_image(model_module, image_url)
    uri = URI.parse(image_url)
    tempfile = uri.open # rubocop:disable Security/Open
    filename = File.basename(uri.path)
    content_type = Marcel::MimeType.for(name: filename)
    model_module.store_image.attach(io: tempfile, filename: filename, content_type: content_type)
  rescue => e
    Sentry.capture_exception(e)
    Rails.logger.error "Store image could not be attached for module: #{model_module.name}"
  end

  private def enrich_from_sc_data(model_module)
    sc_key = find_sc_key(model_module.name)
    return if sc_key.blank?

    model_module.update!(sc_key: sc_key)
    ::ScData::Loader::ModelModulesLoader.new.one(model_module)
  end

  private def find_sc_key(name)
    sc_key_mapping[name.downcase]
  end

  # rubocop:disable Metrics/MethodLength
  private def sc_key_mapping
    {
      "front torpedo bay" => "AEGS_Retaliator_Module_Front_Bomber",
      "rear torpedo bay" => "AEGS_Retaliator_Module_Rear_Bomber",
      "front cargo module" => "AEGS_Retaliator_Module_Front_Cargo",
      "rear cargo module" => "AEGS_Retaliator_Module_Rear_Cargo",
      "front living module" => "AEGS_Retaliator_Module_Front_Base",
      "rear living module" => "AEGS_Retaliator_Module_Rear_Base",
      "front dropship module" => "AEGS_Retaliator_Module_Front",
      "rear dropship module" => "AEGS_Retaliator_Module_Rear",
      "transport & storage module" => "RSI_Aurora_Mk2_Module_Cargo",
      "defensive measures module" => "RSI_Aurora_Mk2_Module_Missile"
    }
  end
  # rubocop:enable Metrics/MethodLength
end
