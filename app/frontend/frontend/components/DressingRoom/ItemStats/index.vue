<script lang="ts">
export default {
  name: "DressingRoomItemStats",
};
</script>

<script lang="ts" setup>
import { useEquipmentStats } from "@/frontend/composables/useEquipmentStats";
import { useI18n } from "@/shared/composables/useI18n";
import { type Equipment } from "@/services/fyApi";

type Props = {
  equipment: Equipment;
  // Helmets, cores, arms, legs and undersuits are all size 1; weapons and
  // backpacks are the gear whose size varies.
  withSize?: boolean;
};

const props = withDefaults(defineProps<Props>(), { withSize: false });

const { t } = useI18n();

const stats = useEquipmentStats(() => props.equipment);

const leadStats = computed(() => stats.value.filter((stat) => stat.primary));

const size = computed(() =>
  props.withSize && Number(props.equipment.size) > 0
    ? t("dressingRoom.size", { size: props.equipment.size })
    : undefined,
);
</script>

<template>
  <span
    v-if="size || leadStats.length"
    class="dressing-room-item-stats"
    data-test="dressing-room-item-stats"
  >
    <span
      v-if="size"
      class="dressing-room-item-stats__size"
      data-test="dressing-room-item-size"
    >
      {{ size }}
    </span>
    <span
      v-for="stat in leadStats"
      :key="stat.label"
      class="dressing-room-item-stats__stat"
    >
      <span class="dressing-room-item-stats__label">{{ stat.label }}</span>
      {{ stat.value }}
    </span>
  </span>
</template>

<style lang="scss" scoped>
.dressing-room-item-stats {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.25rem 0.75rem;
  font-size: 0.8em;
  font-variant-numeric: tabular-nums;
}

.dressing-room-item-stats__size {
  padding: 0 0.375rem;
  border: 1px solid var(--color-edge, rgb(122 130 136 / 0.5));
  border-radius: 3px;
  font-weight: 600;
}

.dressing-room-item-stats__stat {
  white-space: nowrap;
}

.dressing-room-item-stats__label {
  opacity: 0.6;
}
</style>
