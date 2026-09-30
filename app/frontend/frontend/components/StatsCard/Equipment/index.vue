<script lang="ts">
export default {
  name: "EquipmentStatsCard",
};
</script>

<script lang="ts" setup>
import StatsCard from "@/frontend/components/StatsCard/index.vue";
import { type StatsCardBadge } from "@/frontend/components/StatsCard/types";
import { useEquipmentStats } from "@/frontend/composables/useEquipmentStats";
import { useI18n } from "@/shared/composables/useI18n";
import { type Equipment } from "@/services/fyApi";

type Props = {
  equipment?: Equipment;
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  equipment: undefined,
  loading: false,
});

const emit = defineEmits<{ navigate: [] }>();

const { t } = useI18n();

const stats = useEquipmentStats(() => props.equipment);

const subtitle = computed(() =>
  [
    props.equipment?.manufacturer?.name,
    props.equipment?.equipmentTypeLabel,
    props.equipment?.itemTypeLabel,
  ]
    .filter(Boolean)
    .join(" · "),
);

const badges = computed<StatsCardBadge[]>(() => {
  const equipment = props.equipment;
  if (!equipment) return [];

  return [
    {
      key: "slot",
      label: t("labels.equipment.slot"),
      value: equipment.slotLabel,
    },
    { key: "size", label: t("labels.equipment.size"), value: equipment.size },
    {
      key: "grade",
      label: t("labels.equipment.grade"),
      value: equipment.grade,
    },
  ].filter((badge): badge is StatsCardBadge => Boolean(badge.value));
});

const to = computed(() =>
  props.equipment?.slug
    ? { name: "equipment-item", params: { slug: props.equipment.slug } }
    : undefined,
);
</script>

<template>
  <StatsCard
    :title="equipment?.name || ''"
    :subtitle="subtitle || undefined"
    :badges="badges"
    :stats="stats"
    :to="to"
    :loading="loading || !equipment"
    @navigate="emit('navigate')"
  >
    <slot />
  </StatsCard>
</template>
