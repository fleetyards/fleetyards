<script lang="ts">
export default {
  name: "EquipmentItemPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import Availability from "@/frontend/components/Availability/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Chip from "@/shared/components/base/Chip/index.vue";
import EquipmentIcon from "@/frontend/components/Equipment/Icon/index.vue";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useEquipmentStats } from "@/frontend/composables/useEquipmentStats";
import {
  BlueprintCraftableTypeEnum,
  useBlueprints as useBlueprintsQuery,
  useEquipmentItem as useEquipmentItemQuery,
} from "@/services/fyApi";

const { t } = useI18n();

const { updateMetaInfo } = useMetaInfo();

const route = useRoute();

const slug = computed(() => route.params.slug as string);

const { data: equipment, ...asyncStatus } = useEquipmentItemQuery(slug);

const stats = useEquipmentStats(equipment);

const heroStats = computed(() => stats.value.filter((stat) => stat.primary));
const restStats = computed(() => stats.value.filter((stat) => !stat.primary));

// Which recipes make this. Looked up by id, so only once the item has arrived.
const { data: blueprints, isPending: recipesPending } = useBlueprintsQuery(
  computed(() => ({
    q: {
      craftableTypeEq: BlueprintCraftableTypeEnum.EQUIPMENT,
      craftableIdEq: equipment.value?.id,
    },
  })),
  {
    query: { enabled: computed(() => Boolean(equipment.value?.id)) },
  },
);

const recipes = computed(() => blueprints.value?.items || []);

// One crumb: `/catalogue/` is a redirect rather than a page of its own.
const crumbs = computed<Crumb[]>(() => [
  { to: { name: "equipment" }, label: t("nav.catalogue.equipment") },
]);

const details = computed(() => {
  const value = equipment.value;
  if (!value) return [];

  return [
    {
      label: t("labels.equipment.equipmentType"),
      value: value.equipmentTypeLabel,
    },
    { label: t("labels.equipment.itemType"), value: value.itemTypeLabel },
    { label: t("labels.equipment.subType"), value: value.subTypeLabel },
    {
      label: t("labels.equipment.manufacturer"),
      value: value.manufacturer?.name,
    },
  ].filter((entry) => entry.value);
});

watch(
  equipment,
  (value) => {
    if (!value) return;

    updateMetaInfo({
      title: t("title.equipmentItem", { name: value.name }),
      description: value.description ?? undefined,
    });
  },
  { immediate: true },
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <div v-if="equipment" class="equipment-page">
        <BreadCrumbs :crumbs="crumbs" />

        <div class="equipment-page__masthead">
          <EquipmentIcon :equipment="equipment" class="equipment-page__icon" />

          <div class="equipment-page__title">
            <h1 class="equipment-page__name">{{ equipment.name }}</h1>
            <div v-if="equipment.manufacturer" class="equipment-page__sub">
              {{ equipment.manufacturer.name }}
            </div>
          </div>

          <div class="equipment-page__badges">
            <span v-if="equipment.slotLabel" class="equipment-page__badge">
              <span class="equipment-page__badge-label">
                {{ t("labels.equipment.slot") }}
              </span>
              <span class="equipment-page__badge-value">
                {{ equipment.slotLabel }}
              </span>
            </span>
            <span v-if="equipment.size" class="equipment-page__badge">
              <span class="equipment-page__badge-label">
                {{ t("labels.equipment.size") }}
              </span>
              <span class="equipment-page__badge-value">
                {{ equipment.size }}
              </span>
            </span>
            <span v-if="equipment.grade" class="equipment-page__badge">
              <span class="equipment-page__badge-label">
                {{ t("labels.equipment.grade") }}
              </span>
              <span class="equipment-page__badge-value">
                {{ equipment.grade }}
              </span>
            </span>
            <!-- An item the current build no longer describes. It stays
                 reachable because a ledger entry points at it, so it says so
                 rather than serving the last build's figures as current. -->
            <Chip v-if="equipment.retired" :state="ChipStatesEnum.EXCLUDED">
              {{ t("labels.equipment.retired") }}
            </Chip>
          </div>
        </div>

        <p v-if="equipment.description" class="equipment-page__description">
          {{ equipment.description }}
        </p>

        <div class="equipment-page__columns">
          <MetricsCard :title="t('headlines.equipment.metrics')">
            <div v-if="heroStats.length" class="metrics-card__hero">
              <div
                v-for="(stat, index) in heroStats"
                :key="stat.label"
                class="metrics-card__tile"
                :class="{ 'metrics-card__tile--primary': index === 0 }"
              >
                <div class="metrics-card__tile__label">{{ stat.label }}</div>
                <div class="metrics-card__tile__value">{{ stat.value }}</div>
              </div>
            </div>

            <div
              v-if="restStats.length"
              class="metrics-card__rows metrics-card__rows--split"
            >
              <div
                v-for="stat in restStats"
                :key="stat.label"
                class="metrics-card__row"
              >
                <span class="metrics-card__row__label">{{ stat.label }}</span>
                <span class="metrics-card__row__value">{{ stat.value }}</span>
              </div>
            </div>

            <!-- Clothing mostly carries no figure at all, and an empty card
                 reads as something having failed to load. -->
            <p v-if="!stats.length" class="equipment-page__empty">
              {{ t("labels.equipment.noMetrics") }}
            </p>
          </MetricsCard>

          <div class="equipment-page__rail">
            <MetricsCard
              v-if="details.length"
              :title="t('headlines.equipment.identity')"
              variant="slim"
            >
              <div class="metrics-card__rows">
                <div
                  v-for="entry in details"
                  :key="entry.label"
                  class="metrics-card__row"
                >
                  <span class="metrics-card__row__label">{{
                    entry.label
                  }}</span>
                  <span class="metrics-card__row__value">{{
                    entry.value
                  }}</span>
                </div>
              </div>
            </MetricsCard>

            <Availability
              :availability="equipment.availability"
              :retired="equipment.retired"
              scope="equipment"
              :craftable="recipes.length > 0"
              :loading="recipesPending"
            />

            <MetricsCard
              v-if="recipes.length"
              :title="t('headlines.equipment.craftedFrom')"
              variant="slim"
            >
              <div class="metrics-card__rows">
                <router-link
                  v-for="recipe in recipes"
                  :key="recipe.id"
                  :to="{ name: 'blueprint', params: { slug: recipe.slug } }"
                  class="metrics-card__row metrics-card__row--stack equipment-page__link-row"
                >
                  <span class="metrics-card__row__label">
                    {{ recipe.name }}
                  </span>
                  <span class="metrics-card__row__value">
                    {{
                      (recipe.materials || []).map((m) => m.name).join(" · ")
                    }}
                  </span>
                </router-link>
              </div>
            </MetricsCard>
          </div>
        </div>
      </div>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
@import "index";
</style>
