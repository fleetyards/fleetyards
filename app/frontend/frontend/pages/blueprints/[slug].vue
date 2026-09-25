<script lang="ts">
export default {
  name: "BlueprintPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import BlueprintSlot from "@/frontend/components/Blueprints/Slot/index.vue";
import BlueprintPreview from "@/frontend/components/Blueprints/Preview/index.vue";
import BlueprintSources from "@/frontend/components/Blueprints/Sources/index.vue";
import BlueprintFleetOwners from "@/frontend/components/Blueprints/FleetOwners/index.vue";
import BlueprintOwnToggle from "@/frontend/components/Blueprints/OwnToggle/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useCraftTime } from "@/frontend/composables/useCraftTime";
import { NEUTRAL_QUALITY } from "@/frontend/composables/useQualityRamp";
import { useBlueprint as useBlueprintQuery } from "@/services/fyApi";
import { useMaterialStockUpdates } from "@/frontend/composables/useMaterialStock";
import { craftableRoute as craftableRouteFor } from "@/frontend/components/Blueprints/craftableRoute";

const { t } = useI18n();
const { updateMetaInfo } = useMetaInfo();
const route = useRoute();

const slug = computed(() => route.params.slug as string);

const { data: blueprint, ...asyncStatus } = useBlueprintQuery(slug);

const { format: formatCraftTime } = useCraftTime();

// The held-material rows under each slot read the reader's inventories, which
// anyone else with access can move stock in and out of while this page is
// open. Subscribed once here rather than inside `useMaterialStock`, which
// every slot instantiates.
useMaterialStockUpdates();

// One quality per slot, keyed by the slot's position.
//
// A crafter buys each material separately, so the Frame's Iron and the
// Barrel's Titanium are rarely the same grade. A single page-wide figure would
// assert they are, and the stats under a slot only ever ramp off that slot's
// own material.
const qualities = ref<Record<number, number>>({});

// The neutral grade. Every ramp in the build is centred on 1.0x at 500 --
// the single-segment ones are symmetric about it (0.8-1.2, 1.4-0.6), and the
// piecewise ones put their seam there -- so 500 is the item as the catalogue
// lists it. Opening at 0 showed every recipe at its worst.
const qualityFor = (position: number) =>
  qualities.value[position] ?? NEUTRAL_QUALITY;

const setQuality = (position: number, value: number) => {
  qualities.value = { ...qualities.value, [position]: value };
};

const setEveryQuality = (value: number) => {
  const next: Record<number, number> = {};
  (blueprint.value?.costSlots || []).forEach((slot) => {
    next[slot.position] = value;
  });
  qualities.value = next;
};

const craftableRoute = computed(() =>
  craftableRouteFor(blueprint.value?.craftable),
);

const qualitySummary = computed(() => {
  const slots = blueprint.value?.costSlots || [];
  if (!slots.length) return undefined;

  const values = slots.map((slot) => qualityFor(slot.position));
  const lowest = Math.min(...values);
  const highest = Math.max(...values);

  if (lowest === highest) {
    return t("labels.blueprint.qualityAll", { quality: lowest });
  }

  return t("labels.blueprint.qualityRange", { from: lowest, to: highest });
});

watch(
  blueprint,
  (value) => {
    if (!value) return;

    updateMetaInfo({ title: value.name || t("headlines.blueprints.index") });
  },
  { immediate: true },
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <!-- `resolved`, not the default slot: AsyncData renders the error and
         loading slots by name and the success one by name too, so content in
         the default slot is silently never rendered at all. -->
    <template #resolved>
      <div v-if="blueprint" class="blueprint-page">
        <div class="blueprint-page__masthead">
          <div class="blueprint-page__title">
            <div class="blueprint-page__headline">
              <Heading hero>{{ blueprint.name }}</Heading>
              <!-- Beside the name, because that is what it is about: the
                   badges are what the catalogue knows about the recipe, and
                   this is the reader saying they have it. -->
              <BlueprintOwnToggle :blueprint="blueprint" />
            </div>
            <div class="blueprint-page__sub">
              <template v-if="blueprint.craftable">
                {{ t("labels.blueprint.makesA") }}
                <router-link v-if="craftableRoute" :to="craftableRoute">
                  {{ blueprint.craftable.name }}
                </router-link>
                <span v-else>{{ blueprint.craftable.name }}</span>
              </template>
              <!-- 5 of the 1,607 recipes make something no catalogue here
                 carries: four mission carryables, and one entity class in no
                 file in the export. -->
              <span v-else>{{ t("labels.blueprint.makesUnknown") }}</span>
            </div>
          </div>

          <div class="blueprint-page__badges">
            <span
              v-if="blueprint.retired"
              class="blueprint-page__badge blueprint-page__badge--retired"
            >
              <span class="blueprint-page__badge-value">
                {{ t("labels.blueprint.retired") }}
              </span>
            </span>

            <span v-if="blueprint.craftTime" class="blueprint-page__badge">
              <span class="blueprint-page__badge-label">
                {{ t("labels.blueprint.craftTime") }}
              </span>
              <span class="blueprint-page__badge-value">
                {{ formatCraftTime(blueprint.craftTime) }}
              </span>
            </span>

            <span v-if="blueprint.slotCount" class="blueprint-page__badge">
              <span class="blueprint-page__badge-label">
                {{ t("labels.blueprint.slots") }}
              </span>
              <span class="blueprint-page__badge-value">
                {{ blueprint.slotCount }}
              </span>
            </span>
          </div>
        </div>

        <div class="blueprint-page__columns">
          <MetricsCard
            class="blueprint-page__recipe"
            :title="t('labels.blueprint.materials')"
          >
            <template #head>
              <!-- Almost every recipe fills all its slots; three in the build
                 ask for a subset, and "Materials" over a list of four would
                 be wrong for those. -->
              <span
                v-if="
                  blueprint.slotCount &&
                  blueprint.costSlots &&
                  blueprint.slotCount < blueprint.costSlots.length
                "
                class="blueprint-page__choice"
              >
                {{
                  t("labels.blueprint.anyOf", {
                    count: blueprint.slotCount,
                    total: blueprint.costSlots.length,
                  })
                }}
              </span>
            </template>

            <div
              v-if="blueprint.costSlots?.length"
              class="blueprint-page__quickset"
            >
              <span class="blueprint-page__quickset-label">
                {{ t("labels.blueprint.setEverySlot") }}
              </span>
              <button
                v-for="preset in [0, 250, 500, 750, 1000]"
                :key="preset"
                type="button"
                class="blueprint-page__preset"
                @click="setEveryQuality(preset)"
              >
                {{ preset }}
              </button>
              <span class="blueprint-page__quickset-summary">
                {{ qualitySummary }}
              </span>
            </div>

            <div class="blueprint-page__slots">
              <BlueprintSlot
                v-for="slot in blueprint.costSlots"
                :key="slot.position"
                :slot-data="slot"
                :quality="qualityFor(slot.position)"
                @update:quality="setQuality(slot.position, $event)"
              />
            </div>

            <p
              v-if="!blueprint.costSlots?.length"
              class="blueprint-page__empty"
            >
              {{ t("labels.blueprint.noMaterials") }}
            </p>
          </MetricsCard>

          <div class="blueprint-page__rail">
            <!-- What comes out, above where it comes from: the stats move as
                 the sliders move, so they belong beside the recipe. -->
            <BlueprintPreview
              :blueprint="blueprint"
              :quality-for="qualityFor"
            />
            <BlueprintSources
              :sources="blueprint.sources || []"
              :source-unknown="blueprint.sourceUnknown"
            />
            <!-- Last in the rail: who can already make this matters once you
                 know what it costs and where it drops, not before. -->
            <BlueprintFleetOwners :blueprint-id="blueprint.id" />
          </div>
        </div>
      </div>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
@import "index";
</style>
