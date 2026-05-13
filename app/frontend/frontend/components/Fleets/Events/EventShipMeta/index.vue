<script lang="ts">
export default {
  name: "FleetEventsShipMeta",
};
</script>

<script lang="ts" setup>
import type { FleetEventShip } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  ship: FleetEventShip;
};

const props = defineProps<Props>();
const { t } = useI18n();

type StatItem = { icon: string; label?: string; value: string };

const modelMinCrew = computed<number | null>(() => {
  const model = props.ship.model as
    | { minCrew?: number | null }
    | null
    | undefined;
  return model?.minCrew ?? null;
});

const modelMaxCrew = computed<number | null>(() => {
  const model = props.ship.model as
    | { maxCrew?: number | null }
    | null
    | undefined;
  return model?.maxCrew ?? null;
});

const items = computed<StatItem[]>(() => {
  const f = props.ship.filters;
  const list: StatItem[] = [];

  // Model-specific ship: show its crew range as info
  if (props.ship.model) {
    const min = f?.minCrew ?? modelMinCrew.value;
    const max = modelMaxCrew.value;
    if (min != null) {
      const value = max != null && max !== min ? `${min}–${max}` : String(min);
      list.push({
        icon: "fa-light fa-user-group",
        label: t("labels.fleets.missions.minCrew"),
        value,
      });
    }
    return list;
  }

  if (!f) return list;
  if (f.classification)
    list.push({ icon: "fa-light fa-tag", value: f.classification });
  if (f.focus) list.push({ icon: "fa-light fa-bullseye", value: f.focus });
  if (f.minSize)
    list.push({
      icon: "fa-light fa-down-left-and-up-right-to-center",
      label: t("labels.fleets.missions.minSize"),
      value: f.minSize,
    });
  if (f.maxSize)
    list.push({
      icon: "fa-light fa-up-right-and-down-left-from-center",
      label: t("labels.fleets.missions.maxSize"),
      value: f.maxSize,
    });
  if (f.minCrew != null)
    list.push({
      icon: "fa-light fa-user-group",
      label: t("labels.fleets.missions.minCrew"),
      value: String(f.minCrew),
    });
  if (f.minCargo != null)
    list.push({
      icon: "fa-light fa-box",
      value: `${f.minCargo} SCU`,
    });

  return list;
});
</script>

<template>
  <div v-if="items.length" class="event-ship-meta">
    <span v-for="(item, idx) in items" :key="idx" class="event-ship-meta__item">
      <i :class="item.icon" />
      <span v-if="item.label" class="event-ship-meta__label">
        {{ item.label }}
      </span>
      <span class="event-ship-meta__value">{{ item.value }}</span>
    </span>
  </div>
</template>

<style lang="scss" scoped>
.event-ship-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem 0.85rem;
  margin: 0.25rem 0 0.5rem;
  font-size: 0.78rem;
  color: var(--text);
}
.event-ship-meta__item {
  display: inline-flex;
  align-items: center;
  gap: 0.3rem;

  i {
    color: var(--text-muted);
  }
}
.event-ship-meta__label {
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.04em;
  font-size: 0.7rem;
}
.event-ship-meta__value {
  font-weight: 600;
}
</style>
