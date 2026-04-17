# frozen_string_literal: true

require "json"

class ModulesImporter
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

    imported_data = import.input.is_a?(String) ? JSON.parse(import.input) : import.input
    return unless imported_data.is_a?(Array)

    imported_data.filter_map do |item|
      next if item["type"] != "component"

      name = item["name"].tr("\u2013", "-")
      name = name.tr("\u00A0", " ").strip

      model_name = name.split(" ").first
      module_name = name.gsub(model_name, "").strip.delete_prefix("-").strip

      next if module_name.blank?

      {
        name: module_mapping(module_name),
        model_name: model_mapping(model_name)
      }
    end
  rescue JSON::ParserError => e
    Sentry.capture_exception(e)
    Rails.logger.error "Modules Data could not be parsed: #{import.input}"
    nil
  end

  private def import_module(mod)
    model = Model.find_by("lower(name) = :name OR slug = :slug", name: mod[:model_name].downcase, slug: mod[:model_name].parameterize)

    if model.blank?
      return {
        new: false,
        module_id: nil,
        model_id: nil,
        model_name: mod[:model_name],
        name: mod[:name],
        error: false
      }
    end

    existing_module = model.modules.find_by("lower(model_modules.name) = :name OR model_modules.slug = :slug",
      name: mod[:name].downcase, slug: mod[:name].parameterize)

    if existing_module.present?
      return {
        new: false,
        module_id: existing_module.id,
        model_id: model.id,
        model_name: model.name,
        name: mod[:name],
        error: false
      }
    end

    model_module = ModelModule.create!(
      name: mod[:name],
      hidden: false,
      active: true
    )

    ModuleHardpoint.create!(
      model_id: model.id,
      model_module_id: model_module.id
    )

    enrich_from_sc_data(model_module)

    {
      new: true,
      module_id: model_module.id,
      model_id: model.id,
      model_name: model.name,
      name: mod[:name],
      error: false
    }
  rescue => e
    Sentry.capture_exception(e)
    Rails.logger.error "Module could not be imported: #{mod[:name]}"
    {
      new: true,
      module_id: nil,
      model_id: model&.id,
      model_name: mod[:model_name],
      name: mod[:name],
      error: true
    }
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
      "rear dropship module" => "AEGS_Retaliator_Module_Rear"
    }
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  private def module_mapping(name)
    name = name.tr("\u2013", "-")

    mapping = {
      "RETALIATOR FRONT LIVING MODULE" => "Front Living Module",
      "Retaliator Front Living Module" => "Front Living Module",
      "RETALIATOR REAR LIVING MODULE" => "Rear Living Module",
      "Retaliator Rear Living Module" => "Rear Living Module",
      "RETALIATOR FRONT DROP SHIP MODULE" => "Front Dropship Module",
      "Retaliator Front Drop Ship Module" => "Front Dropship Module",
      "RETALIATOR TORPEDO Module - Bow" => "Front Torpedo Bay",
      "Retaliator Torpedo Module - Bow" => "Front Torpedo Bay",
      "RETALIATOR TORPEDO Module - Stern" => "Rear Torpedo Bay",
      "Retaliator Torpedo Module - Stern" => "Rear Torpedo Bay",
      "RETALIATOR CARGO MODULE - BOW" => "Front Cargo Module",
      "RETALIATOR CARGO MODULE - STERN" => "Rear Cargo Module",
      "Retaliator Cargo Module - Bow" => "Front Cargo Module",
      "Retaliator Cargo Module - Stern" => "Rear Cargo Module",
      "Retaliator Personnel Module - Bow" => "Front Living Module",
      "Retaliator Personnel Module - Stern" => "Rear Living Module",
      "Retaliator Drop Ship Module - Bow" => "Front Dropship Module",
      "FRONT LIVING MODULE" => "Front Living Module",
      "Front Living Module" => "Front Living Module",
      "REAR LIVING MODULE" => "Rear Living Module",
      "Rear Living Module" => "Rear Living Module",
      "FRONT DROP SHIP MODULE" => "Front Dropship Module",
      "Front Drop Ship Module" => "Front Dropship Module",
      "TORPEDO Module - Bow" => "Front Torpedo Bay",
      "Torpedo Module - Bow" => "Front Torpedo Bay",
      "TORPEDO Module - Stern" => "Rear Torpedo Bay",
      "Torpedo Module - Stern" => "Rear Torpedo Bay",
      "Cargo Module - Bow" => "Front Cargo Module",
      "Cargo Module - Stern" => "Rear Cargo Module",
      "CARGO MODULE - BOW" => "Front Cargo Module",
      "CARGO MODULE - STERN" => "Rear Cargo Module",
      "Personnel Module - Bow" => "Front Living Module",
      "Personnel Module - Stern" => "Rear Living Module",
      "Drop Ship Module - Bow" => "Front Dropship Module"
    }

    return mapping[name.strip] if mapping[name.strip].present?

    name
  end
  # rubocop:enable Metrics/MethodLength

  private def model_mapping(name)
    mapping = {
      "Retaliator" => "Retaliator"
    }

    return mapping[name.strip] if mapping[name.strip].present?

    name
  end
end
