<script lang="ts">
export default {
  name: "BlueprintPreview",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useCraftedStats } from "@/frontend/composables/useCraftedStats";
import { type Blueprint } from "@/services/fyApi";
import { catalogueItemRoute } from "@/frontend/utils/catalogueItemRoute";

type Props = {
  blueprint: Blueprint;
  qualityFor: (position: number) => number;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { stats } = useCraftedStats(
  () => props.blueprint.costSlots || [],
  (position) => props.qualityFor(position),
);

const craftableRoute = computed(() =>
  catalogueItemRoute(props.blueprint.craftable),
);
</script>

<template>
  <MetricsCard
    v-if="stats.length"
    class="blueprint-preview"
    :title="t('labels.blueprint.whatYouGet')"
    variant="slim"
  >
    <template #head>
      <router-link
        v-if="craftableRoute"
        :to="craftableRoute"
        class="blueprint-preview__craftable"
      >
        {{ blueprint.craftable?.name }}
      </router-link>
      <span
        v-else-if="blueprint.craftable"
        class="blueprint-preview__craftable"
      >
        {{ blueprint.craftable.name }}
      </span>
    </template>

    <div class="blueprint-preview__stats">
      <div
        v-for="stat in stats"
        :key="stat.key"
        class="blueprint-preview__stat"
      >
        <span class="blueprint-preview__stat-name">
          {{ stat.name }}
          <!-- 358 recipes move one stat from two slots, and the figure here
               is both of them together -- which neither slot's own panel
               can say. -->
          <span v-if="stat.slots > 1" class="blueprint-preview__stat-slots">
            {{ t("labels.blueprint.fromSlots", { count: stat.slots }) }}
          </span>
        </span>
        <span class="blueprint-preview__stat-value">{{ stat.value }}</span>
        <span
          class="blueprint-preview__delta"
          :class="`blueprint-preview__delta--${stat.trend}`"
        >
          {{ stat.delta }}
        </span>
        <span v-if="stat.base" class="blueprint-preview__stat-base">
          {{ t("labels.blueprint.atNeutral", { value: stat.base }) }}
        </span>
        <span v-else class="blueprint-preview__stat-base">
          {{ t("labels.blueprint.factorOnly") }}
        </span>
      </div>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "index";
</style>
