<script lang="ts">
export default {
  name: "CrewPositions",
};
</script>

<script lang="ts" setup>
import Loader from "@/shared/components/Loader/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useModelPositions as useModelPositionsQuery,
  type ModelPosition,
  type Model,
} from "@/services/fyApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { isLoading, data: positions } = useModelPositionsQuery(
  props.model.slug,
  {
    query: { enabled: !!props.model },
  },
);

const positionIcon = (positionType: string) => {
  switch (positionType) {
    case "pilot":
      return "fa-duotone fa-plane";
    case "copilot":
      return "fa-duotone fa-plane-up";
    case "turret_gunner":
      return "fa-duotone fa-crosshairs";
    case "engineer":
      return "fa-duotone fa-wrench";
    case "gunner":
      return "fa-duotone fa-gun";
    case "loadmaster":
      return "fa-duotone fa-boxes-stacked";
    case "passenger":
      return "fa-duotone fa-person-seat-reclined";
    case "operator":
      return "fa-duotone fa-desktop";
    default:
      return "fa-duotone fa-user";
  }
};

const groupedPositions = computed(() => {
  if (!positions.value?.length) return [];

  const groups: Record<string, { position: ModelPosition; count: number }> = {};

  positions.value.forEach((pos) => {
    const key = `${pos.positionType}-${pos.name}`;
    if (groups[key]) {
      groups[key].count++;
    } else {
      groups[key] = { position: pos, count: 1 };
    }
  });

  return Object.values(groups);
});
</script>

<template>
  <div v-if="positions?.length || isLoading" class="crew-positions">
    <h2 class="crew-positions__label">
      {{ t("labels.model.crewPositions") }}
    </h2>
    <div v-if="positions?.length" class="crew-positions__list">
      <div
        v-for="group in groupedPositions"
        :key="`${group.position.positionType}-${group.position.name}`"
        class="crew-positions__item"
      >
        <span class="crew-positions__count" v-if="group.count > 1">
          {{ group.count }}x
        </span>
        <i :class="positionIcon(group.position.positionType)" />
        <span class="crew-positions__name">{{ group.position.name }}</span>
        <span
          class="crew-positions__source"
          v-if="group.position.source === 'curated'"
        >
          <i
            class="fa-light fa-pen-to-square"
            v-tooltip="t('labels.model.curatedPosition')"
          />
        </span>
      </div>
    </div>
    <Loader :loading="isLoading" fixed />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
