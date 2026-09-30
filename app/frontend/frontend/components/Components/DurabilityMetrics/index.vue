<script lang="ts">
export default {
  name: "ComponentDurabilityMetrics",
};
</script>

<script lang="ts" setup>
import StatGroups from "@/frontend/components/Components/StatGroups/index.vue";
import type { ComponentDurability } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComponentDurability } from "@/frontend/composables/useComponentDurability";

type Props = {
  durability?: ComponentDurability | null;
};

const props = defineProps<Props>();

const { t } = useI18n();

const durabilityGroups = useComponentDurability(() => props.durability);

const groups = computed(() =>
  durabilityGroups.value.map((group) => ({
    ...group,
    title: t(`headlines.component.${group.key}`),
  })),
);
</script>

<template>
  <StatGroups :groups="groups" test-prefix="durability" />
</template>
