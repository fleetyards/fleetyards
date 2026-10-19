# frozen_string_literal: true

# Shared mapping from RSI hangar component names to {model_name, module_name} pairs.
# Used by both ModulesImporter and HangarSync.
# Keys are downcased for case-insensitive lookup.
module HangarModuleMapping
  COMPONENT_MAPPING = {
    # Aurora Mk II
    "aurora mk ii combat module" => {model_names: ["Aurora Mk II"], module_name: "Combat Module"},
    "aurora mk ii cargo module" => {model_names: ["Aurora Mk II"], module_name: "Cargo Module"},

    # Apollo (shared between Medivac and Triage)
    "apollo tier 1 module right" => {model_names: ["Apollo Medivac", "Apollo Triage"], module_name: "Tier 1 Module Right"},
    "apollo tier 2 module right" => {model_names: ["Apollo Medivac", "Apollo Triage"], module_name: "Tier 2 Module Right"},
    "apollo tier 3 module right" => {model_names: ["Apollo Medivac", "Apollo Triage"], module_name: "Tier 3 Module Right"},
    "apollo tier 1 module left" => {model_names: ["Apollo Medivac", "Apollo Triage"], module_name: "Tier 1 Module Left"},
    "apollo tier 2 module left" => {model_names: ["Apollo Medivac", "Apollo Triage"], module_name: "Tier 2 Module Left"},
    "apollo tier 3 module left" => {model_names: ["Apollo Medivac", "Apollo Triage"], module_name: "Tier 3 Module Left"},

    # Galaxy
    "galaxy - cargo module" => {model_names: ["Galaxy"], module_name: "Cargo Module"},
    "galaxy - med bay module" => {model_names: ["Galaxy"], module_name: "Med Bay Module"},
    "galaxy - refinery module" => {model_names: ["Galaxy"], module_name: "Refinery Module"},

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
    COMPONENT_MAPPING[HangarModuleMapping.normalize(name)]
  end

  def self.normalize(name)
    name.to_s.strip.downcase.tr("\u2013", "-").tr("\u00A0", " ")
  end

  # RSI lists ship modules and ship parts alike as components. A module is one
  # the mapping knows, or one named as a module ("Retaliator Cargo Module -
  # Bow"): those are fitted to a ship, the rest are kept as ship components.
  # The sync modal tells them apart by the same word before the server sees
  # them.
  def self.module?(name)
    COMPONENT_MAPPING.key?(normalize(name)) || normalize(name).match?(/\bmodule\b/)
  end
end
