<script lang="ts">
export default {
  name: "VisualTestsDedicationPlaquesPage",
};
</script>

<script lang="ts" setup>
import VehiclePlaque from "./index.vue";
import PlaqueDownloadBtn from "@/frontend/components/Vehicles/PlaqueDownloadBtn/index.vue";
import { PLAQUE_MAKERS } from "./makers";
import {
  NullableVehiclePlaqueStyleEnum,
  type VehiclePublic,
} from "@/services/fyApi";

// Every style a supporter can pick, and every manufacturer's own, on one
// ship's data, so a change to a shared rule shows up across all of them.
const NOW = "2026-10-12T12:00:00Z";

const vehicle = (
  code: string,
  plaqueStyle: VehiclePublic["plaqueStyle"],
): VehiclePublic =>
  ({
    id: `plaque-${code}-${plaqueStyle}`,
    name: "Contorta",
    serial: "L8-4261-HA",
    dedication: "Built rough, flown far, and never once turned back.",
    launchedOn: "2024-11-29",
    launchPort: "Grim HEX",
    affiliation: "MARU Inc.",
    operationsGroup: "mercenary_guild",
    shipyard: "Borea (Magnus II)",
    manufacturerCode: code,
    manufacturerShortName: code,
    plaqueStyle,
    loaner: false,
    publicLogEntriesCount: 0,
    modelModuleIds: [],
    modelUpgradeIds: [],
    hangarGroupIds: [],
    hangarGroups: [],
    model: {
      id: "model",
      name: "Corsair",
      slug: "corsair",
      media: {},
      manufacturer: {
        name: code,
        longName: code,
        slug: code.toLowerCase(),
        code,
        createdAt: NOW,
        updatedAt: NOW,
      },
    },
    createdAt: NOW,
    updatedAt: NOW,
  }) as unknown as VehiclePublic;

const generalStyles = Object.values(NullableVehiclePlaqueStyleEnum).filter(
  (style): style is NonNullable<typeof style> =>
    !!style && style !== "manufacturer",
);

const makerCodes = Object.keys(PLAQUE_MAKERS);
</script>

<template>
  <div class="plaque-visual">
    <h2>General styles</h2>
    <div class="plaque-visual__grid">
      <div v-for="style in generalStyles" :key="style">
        <p class="text-muted">{{ style }}</p>
        <VehiclePlaque :vehicle="vehicle('DRAK', style)" captain="TorlekMaru" />
        <PlaqueDownloadBtn
          :element="`vehicle-plaque-plaque-DRAK-${style}`"
          :filename="`plaque-${style}`"
          :data-test="`download-${style}`"
        />
      </div>
    </div>

    <h2>Manufacturer styles</h2>
    <div class="plaque-visual__grid">
      <div v-for="code in makerCodes" :key="code" :data-test="`maker-${code}`">
        <p class="text-muted">{{ code }}</p>
        <VehiclePlaque
          :vehicle="vehicle(code, 'manufacturer')"
          captain="TorlekMaru"
        />
        <PlaqueDownloadBtn
          :element="`vehicle-plaque-plaque-${code}-manufacturer`"
          :filename="`plaque-${code}`"
          :data-test="`download-${code}`"
        />
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.plaque-visual {
  &__grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(420px, 1fr));
    gap: 24px;
    margin-bottom: 40px;
  }
}
</style>
