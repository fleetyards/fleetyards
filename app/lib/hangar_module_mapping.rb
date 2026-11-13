# frozen_string_literal: true

# Shared mapping from RSI hangar component names to {model_names, module_name}
# pairs, plus the game-data key a new module is loaded from. The key sits on the
# component rather than the module name because names repeat across ships: the
# Aurora Mk II and the Galaxy both have a "Cargo Module".
# Used by both ModulesImporter and HangarSync.
# Keys are downcased for case-insensitive lookup.
module HangarModuleMapping
  COMPONENT_MAPPING = {
    # Aurora Mk II
    "aurora mk ii combat module" => {model_names: ["Aurora Mk II"], module_name: "Combat Module", sc_key: "RSI_Aurora_Mk2_Module_Missile"},
    "aurora mk ii cargo module" => {model_names: ["Aurora Mk II"], module_name: "Cargo Module", sc_key: "RSI_Aurora_Mk2_Module_Cargo"},

    # Apollo (shared between Medivac and Triage)
    "apollo tier 1 module right" => {model_names: ["Apollo Medivac", "Apollo Triage"], module_name: "Tier 1 Module Right"},
    "apollo tier 2 module right" => {model_names: ["Apollo Medivac", "Apollo Triage"], module_name: "Tier 2 Module Right"},
    "apollo tier 3 module right" => {model_names: ["Apollo Medivac", "Apollo Triage"], module_name: "Tier 3 Module Right"},
    "apollo tier 1 module left" => {model_names: ["Apollo Medivac", "Apollo Triage"], module_name: "Tier 1 Module Left"},
    "apollo tier 2 module left" => {model_names: ["Apollo Medivac", "Apollo Triage"], module_name: "Tier 2 Module Left"},
    "apollo tier 3 module left" => {model_names: ["Apollo Medivac", "Apollo Triage"], module_name: "Tier 3 Module Left"},

    # Galaxy
    "galaxy - cargo module" => {model_names: ["Galaxy"], module_name: "Cargo Module", sc_key: "RSI_Galaxy_Module_Cargo"},
    "galaxy - med bay module" => {model_names: ["Galaxy"], module_name: "Med Bay Module", sc_key: "RSI_Galaxy_Module_Medical"},
    # The game files carry an unnamed refinery shell with no equipment: linking
    # it would mark the module flight-ready before it is.
    "galaxy - refinery module" => {model_names: ["Galaxy"], module_name: "Refinery Module"},

    # Retaliator
    "retaliator front living module" => {model_names: ["Retaliator"], module_name: "Front Living Module", sc_key: "AEGS_Retaliator_Module_Front_Base"},
    "retaliator rear living module" => {model_names: ["Retaliator"], module_name: "Rear Living Module", sc_key: "AEGS_Retaliator_Module_Rear_Base"},
    "retaliator front drop ship module" => {model_names: ["Retaliator"], module_name: "Front Dropship Module", sc_key: "AEGS_Retaliator_Module_Front"},
    "retaliator drop ship module - bow" => {model_names: ["Retaliator"], module_name: "Front Dropship Module", sc_key: "AEGS_Retaliator_Module_Front"},
    "retaliator torpedo module - bow" => {model_names: ["Retaliator"], module_name: "Front Torpedo Bay", sc_key: "AEGS_Retaliator_Module_Front_Bomber"},
    "retaliator torpedo module - stern" => {model_names: ["Retaliator"], module_name: "Rear Torpedo Bay", sc_key: "AEGS_Retaliator_Module_Rear_Bomber"},
    "retaliator cargo module - bow" => {model_names: ["Retaliator"], module_name: "Front Cargo Module", sc_key: "AEGS_Retaliator_Module_Front_Cargo"},
    "retaliator cargo module - stern" => {model_names: ["Retaliator"], module_name: "Rear Cargo Module", sc_key: "AEGS_Retaliator_Module_Rear_Cargo"},
    "retaliator personnel module - bow" => {model_names: ["Retaliator"], module_name: "Front Living Module", sc_key: "AEGS_Retaliator_Module_Front_Base"},
    "retaliator personnel module - stern" => {model_names: ["Retaliator"], module_name: "Rear Living Module", sc_key: "AEGS_Retaliator_Module_Rear_Base"}
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
