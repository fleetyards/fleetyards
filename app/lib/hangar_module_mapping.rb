# frozen_string_literal: true

# Shared mapping from RSI hangar component names to {model_name, module_name} pairs.
# Used by both ModulesImporter and HangarSync.
# Keys are downcased for case-insensitive lookup.
module HangarModuleMapping
  COMPONENT_MAPPING = {
    # Aurora Mk II
    "aurora mk ii combat module" => {model_names: ["Aurora Mk II"], module_name: "Defensive Measures Module"},
    "aurora mk ii cargo module" => {model_names: ["Aurora Mk II"], module_name: "Transport & Storage Module"},

    # Apollo (shared between Medivac and Triage)
    "apollo tier 1 module right" => {model_names: ["Apollo Medivac", "Apollo Triage"], module_name: "Tier 1 Module Right"},
    "apollo tier 2 module right" => {model_names: ["Apollo Medivac", "Apollo Triage"], module_name: "Tier 2 Module Right"},
    "apollo tier 3 module right" => {model_names: ["Apollo Medivac", "Apollo Triage"], module_name: "Tier 3 Module Right"},
    "apollo tier 1 module left" => {model_names: ["Apollo Medivac", "Apollo Triage"], module_name: "Tier 1 Module Left"},
    "apollo tier 2 module left" => {model_names: ["Apollo Medivac", "Apollo Triage"], module_name: "Tier 2 Module Left"},
    "apollo tier 3 module left" => {model_names: ["Apollo Medivac", "Apollo Triage"], module_name: "Tier 3 Module Left"},

    # Retaliator
    "retaliator front living module" => {model_names: ["Retaliator"], module_name: "Front Living Module"},
    "retaliator rear living module" => {model_names: ["Retaliator"], module_name: "Rear Living Module"},
    "retaliator front drop ship module" => {model_names: ["Retaliator"], module_name: "Front Dropship Module"},
    "retaliator drop ship module - bow" => {model_names: ["Retaliator"], module_name: "Front Dropship Module"},
    "retaliator torpedo module - bow" => {model_names: ["Retaliator"], module_name: "Front Torpedo Bay"},
    "retaliator torpedo module - stern" => {model_names: ["Retaliator"], module_name: "Rear Torpedo Bay"},
    "retaliator cargo module - bow" => {model_names: ["Retaliator"], module_name: "Front Cargo Module"},
    "retaliator cargo module - stern" => {model_names: ["Retaliator"], module_name: "Rear Cargo Module"},
    "retaliator personnel module - bow" => {model_names: ["Retaliator"], module_name: "Front Living Module"},
    "retaliator personnel module - stern" => {model_names: ["Retaliator"], module_name: "Rear Living Module"}
  }.freeze

  def component_mapping(name)
    normalized = name.strip.downcase.tr("\u2013", "-").tr("\u00A0", " ")
    COMPONENT_MAPPING[normalized]
  end
end
