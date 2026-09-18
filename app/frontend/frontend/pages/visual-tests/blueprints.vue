<script lang="ts">
export default {
  name: "VisualTestsBlueprints",
};

// ── BlueprintSlot ────────────────────────────────────────────────────

// One fitting position in a recipe: the material it takes, the grade of that
// material, and what the grade buys. The three below are the shapes it has to
// survive -- a stat the catalogue can put a figure to, one it cannot, and a
// slot that gates on a minimum grade.
const ramp = (attrs = {}) =>
  ({
    name: "Max. Shield Strength",
    propertyKey: "gpp_shield_maxhealth",
    ramp: "linear",
    startQuality: 0,
    endQuality: 1000,
    modifierAtStart: 0.9,
    modifierAtEnd: 1.1,
    unit: null,
    baseValue: 100000,
    ...attrs,
  }) as BlueprintCostModifier;

const costSlot = (attrs: Partial<BlueprintCostSlot> = {}): BlueprintCostSlot =>
  ({
    name: "Field Array",
    scKey: "vt_slot",
    position: 0,
    options: [
      {
        type: "resource",
        quantity: 1.9,
        minQuality: 0,
        commodityKey: "items_commodities_corundum",
        commodity: { id: "vt-c", name: "Corundum", slug: "corundum" },
      },
    ],
    modifiers: [ramp()],
    ...attrs,
  }) as BlueprintCostSlot;

const slotQualities = ref<Record<string, number>>({
  valued: 500,
  unvalued: 500,
  gated: 200,
});

const setSlotQuality = (key: string, value: number) => {
  slotQualities.value = { ...slotQualities.value, [key]: value };
};

// A stat the game names and gives no figures for -- 598 modifiers are in
// exactly that position.
const unvaluedSlot = costSlot({
  name: "Shell",
  modifiers: [
    ramp({
      name: "Power Pips",
      propertyKey: "gpp_itemresource_powergeneration",
      ramp: "linear_integer_additive",
      modifierAtStart: null,
      modifierAtEnd: null,
      baseValue: null,
    }),
  ],
});

// 22 of the 4,289 slots ask for a minimum grade before they accept anything.
const gatedSlot = costSlot({
  name: "Frequency Controller",
  options: [
    {
      type: "item",
      quantity: 170,
      minQuality: 400,
      commodityKey: "items_commodities_glacosite",
      commodity: { id: "vt-g", name: "Glacosite", slug: "glacosite" },
    },
  ],
});
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import BlueprintsList from "@/frontend/components/Blueprints/List/index.vue";
import BlueprintSlot from "@/frontend/components/Blueprints/Slot/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import {
  type Blueprint,
  type BlueprintCostModifier,
  type BlueprintCostSlot,
} from "@/services/fyApi";

const catalogueBlueprint = (attrs: Partial<Blueprint>): Blueprint =>
  ({
    retired: false,
    sourceUnknown: false,
    createdAt: "2026-01-01",
    updatedAt: "2026-01-01",
    ...attrs,
  }) as Blueprint;

const catalogueBlueprints: Blueprint[] = [
  catalogueBlueprint({
    id: "vt-blueprint-1",
    name: "FR-76 Shield Generator",
    slug: "fr-76-shield-generator-blueprint",
    scKey: "bp_fr76",
    scRef: "bp-fr76",
    craftTime: 5400,
    slotCount: 2,
    craftable: {
      type: "Component",
      id: "vt-component-1",
      name: "FR-76 Shield Generator",
      slug: "fr-76-shield-generator",
    },
    materials: [
      { id: "m1", name: "Aluminium", slug: "aluminium" },
      { id: "m2", name: "Tungsten", slug: "tungsten" },
    ],
  }),
  catalogueBlueprint({
    id: "vt-blueprint-2",
    name: "Bulwark Cooler",
    slug: "bulwark-cooler-blueprint",
    scKey: "bp_bulwark",
    scRef: "bp-bulwark",
    craftTime: 1800,
    sourceUnknown: true,
    craftable: {
      type: "Component",
      id: "vt-component-2",
      name: "Bulwark Cooler",
      slug: "bulwark-cooler",
    },
    materials: [{ id: "m1", name: "Aluminium", slug: "aluminium" }],
  }),
  catalogueBlueprint({
    id: "vt-blueprint-3",
    name: "Field Ration Pack",
    slug: "field-ration-pack",
    scKey: "bp_ration",
    scRef: "bp-ration",
    sourceUnknown: true,
  }),
];
</script>

<template>
  <Heading :level="HeadingLevelEnum.H1">Blueprints</Heading>

  <Heading :level="HeadingLevelEnum.H2">BlueprintsList</Heading>
  <p>
    The section's second tenant on the same list. Kept directly under the
    components one on purpose: the two rows are meant to be identical furniture,
    and side by side is the only place a drift between them is obvious.
  </p>

  <BlueprintsList :blueprints="catalogueBlueprints" />

  <Heading :level="HeadingLevelEnum.H2">BlueprintSlot</Heading>
  <p>
    A recipe's fitting position. The grades held are marked on the track itself
    rather than listed beside it, because where a material sits on the ramp is
    the question being asked; the stock rows under it are only shown to a reader
    who has the stock to match, so they are absent here.
  </p>

  <BlueprintSlot
    :slot-data="costSlot()"
    :quality="slotQualities.valued"
    @update:quality="setSlotQuality('valued', $event)"
  />

  <Heading :level="HeadingLevelEnum.H2">BlueprintSlot | No figures</Heading>
  <p>
    A stat the export names and gives no numbers for. Rendering the nils would
    print 0 to 0 and invent a figure, so the row says so instead.
  </p>

  <BlueprintSlot
    :slot-data="unvaluedSlot"
    :quality="slotQualities.unvalued"
    @update:quality="setSlotQuality('unvalued', $event)"
  />

  <Heading :level="HeadingLevelEnum.H2">BlueprintSlot | Below the gate</Heading>
  <p>
    A slot that refuses material under a minimum grade. The figures stay
    readable but go quiet, because they are not what this material would buy.
  </p>

  <BlueprintSlot
    :slot-data="gatedSlot"
    :quality="slotQualities.gated"
    @update:quality="setSlotQuality('gated', $event)"
  />
</template>
