<script lang="ts">
export default {
  name: "ModelStorageContainers",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import {
  type Model,
  type StorageContainer,
  StorageContainerKindEnum,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type CapacityGroup,
  groupByCapacity,
} from "@/frontend/composables/useCapacityGroups";

const { t, toNumber } = useI18n();

type Props = {
  model: Model;
};

const props = defineProps<Props>();

type Card = {
  kind: StorageContainerKindEnum;
  title: string;
  total: number;
  count: number;
  groups: CapacityGroup[];
};

const TITLES: Record<StorageContainerKindEnum, string> = {
  [StorageContainerKindEnum.ORE]: "labels.model.orePods",
  [StorageContainerKindEnum.SALVAGE]: "labels.model.salvageStorage",
};

/**
 * Ore pods and salvage storage, a card per kind, apart from the cargo card:
 * what they hold is not cargo space. Salvage storage has no name in the game
 * files, so it is named by its kind.
 */
const cards = computed<Card[]>(() =>
  Object.values(StorageContainerKindEnum)
    .map((kind) => {
      const containers = (props.model.storageContainers || []).filter(
        (container: StorageContainer) => container.kind === kind,
      );

      return {
        kind,
        title: t(TITLES[kind]),
        total: containers.reduce(
          (sum, container) => sum + (container.capacity || 0),
          0,
        ),
        count: containers.length,
        groups: groupByCapacity(containers, t(TITLES[kind])),
      };
    })
    .filter((card) => card.count),
);
</script>

<template>
  <MetricsCard
    v-for="card in cards"
    :key="card.kind"
    :title="card.title"
    :data-test="`storage-containers-${card.kind}`"
  >
    <div class="metrics-card__hero">
      <div class="metrics-card__tile metrics-card__tile--primary">
        <div class="metrics-card__tile__label">
          {{ t("labels.storageContainers.total") }}
        </div>
        <div class="metrics-card__tile__value">
          {{ toNumber(card.total, "cargo") }}
        </div>
      </div>
      <div class="metrics-card__tile">
        <div class="metrics-card__tile__label">
          {{ t("labels.storageContainers.count") }}
        </div>
        <div class="metrics-card__tile__value">{{ card.count }}x</div>
      </div>
    </div>

    <div class="storage-containers">
      <div
        v-for="group in card.groups"
        :key="group.key"
        class="storage-container"
        :title="group.name"
      >
        <div class="storage-container__head">
          <span class="storage-container__name">{{ group.name }}</span>
          <span class="storage-container__count">{{ group.count }}x</span>
          <span class="storage-container__share">
            {{ toNumber(group.capacity, "cargo") }}
            {{ t("labels.storageContainers.perContainer") }}
          </span>
        </div>
        <div class="storage-container__bar">
          <div
            class="storage-container__bar-fill"
            :style="{ width: `${group.share}%` }"
          />
        </div>
      </div>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.storage-containers {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.storage-container__head {
  display: flex;
  align-items: baseline;
  gap: 8px;
  margin-bottom: 5px;
}

.storage-container__name {
  flex: 1 1 auto;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 12px;
  color: lighten($text-color, 15%);
}

.storage-container__count {
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 12px;
  font-variant-numeric: tabular-nums;
  color: lighten($text-color, 15%);
}

.storage-container__share {
  flex: 0 0 auto;
  font-size: 11px;
  color: $gray;
}

.storage-container__bar {
  height: 5px;
  border-radius: 3px;
  background: rgba($gray-light, 0.28);
  overflow: hidden;
}

.storage-container__bar-fill {
  height: 100%;
  background: linear-gradient(90deg, $primary, rgba($primary, 0.5));
}
</style>
