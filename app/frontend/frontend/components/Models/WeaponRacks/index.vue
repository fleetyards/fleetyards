<script lang="ts">
export default {
  name: "ModelWeaponRacks",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import type { Model } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type RackSlotGroup,
  groupRackSlots,
} from "@/frontend/composables/useWeaponRackSlots";

const { t } = useI18n();

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const racks = computed(() => props.model.weaponRacks || []);

const rackCount = computed(() =>
  racks.value.reduce((sum, rack) => sum + rack.count, 0),
);

const groups = computed(() => groupRackSlots(racks.value));

const slotCount = computed(() =>
  groups.value.reduce((sum, group) => sum + group.count, 0),
);

const groupName = (group: RackSlotGroup) =>
  group.categories
    .map((category) => t(`labels.weaponRacks.categories.${category}`))
    .join(" / ");

const groupSize = (group: RackSlotGroup) => {
  if (group.minSize === group.maxSize) {
    return t("labels.weaponRacks.size", { size: group.maxSize });
  }

  if (group.minSize === 0) {
    return t("labels.weaponRacks.sizeUpTo", { size: group.maxSize });
  }

  return t("labels.weaponRacks.sizeRange", {
    min: group.minSize,
    max: group.maxSize,
  });
};
</script>

<template>
  <MetricsCard
    v-if="slotCount"
    :title="t('labels.model.weaponRacks')"
    data-test="weapon-racks"
  >
    <div class="metrics-card__hero">
      <div class="metrics-card__tile metrics-card__tile--primary">
        <div class="metrics-card__tile__label">
          {{ t("labels.weaponRacks.slots") }}
        </div>
        <div class="metrics-card__tile__value">{{ slotCount }}</div>
      </div>
      <div class="metrics-card__tile">
        <div class="metrics-card__tile__label">
          {{ t("labels.weaponRacks.racks") }}
        </div>
        <div class="metrics-card__tile__value">{{ rackCount }}x</div>
      </div>
    </div>

    <div class="rack-slots">
      <div
        v-for="group in groups"
        :key="group.key"
        class="rack-slot"
        data-test="weapon-rack-slot"
      >
        <div class="rack-slot__head">
          <span class="rack-slot__name">
            {{ groupName(group) }}
            <span v-if="group.restriction" class="rack-slot__restriction">
              {{
                t("labels.weaponRacks.only", {
                  tag: t(`labels.weaponRacks.tags.${group.restriction}`),
                })
              }}
            </span>
          </span>
          <span class="rack-slot__count">{{ group.count }}x</span>
          <span class="rack-slot__size">{{ groupSize(group) }}</span>
        </div>
        <div class="rack-slot__bar">
          <div
            class="rack-slot__bar-fill"
            :style="{ width: `${group.share}%` }"
          />
        </div>
      </div>
    </div>

    <div class="metrics-card__footer">
      <span class="metrics-card__hint">
        {{ t("labels.weaponRacks.hint") }}
      </span>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.rack-slots {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.rack-slot__head {
  display: flex;
  align-items: baseline;
  gap: 8px;
  margin-bottom: 5px;
}

.rack-slot__name {
  flex: 1 1 auto;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 12px;
  color: lighten($text-color, 15%);
}

.rack-slot__restriction {
  font-size: 11px;
  color: $gray;
}

.rack-slot__count {
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 12px;
  font-variant-numeric: tabular-nums;
  color: lighten($text-color, 15%);
}

.rack-slot__size {
  flex: 0 0 auto;
  font-size: 11px;
  color: $gray;
}

.rack-slot__bar {
  height: 5px;
  border-radius: 3px;
  background: rgba($gray-light, 0.28);
  overflow: hidden;
}

.rack-slot__bar-fill {
  height: 100%;
  background: linear-gradient(90deg, $primary, rgba($primary, 0.5));
}
</style>
