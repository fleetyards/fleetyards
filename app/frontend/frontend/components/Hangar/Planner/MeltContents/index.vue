<script lang="ts">
export default {
  name: "HangarPlannerMeltContents",
};
</script>

<script lang="ts" setup>
import type {
  HangarPlanPledgeItem,
  HangarPlanPledgeShip,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  ships: HangarPlanPledgeShip[];
  items: HangarPlanPledgeItem[];
  unlisted?: number;
};

const props = withDefaults(defineProps<Props>(), {
  unlisted: 0,
});

const { t } = useI18n();

const entries = computed(() => [
  ...props.ships.map((ship) => ({
    id: ship.id,
    name: ship.name ? `${ship.name} (${ship.model.name})` : ship.model.name,
    quantity: 1,
    icon: "fa-light fa-rocket",
  })),
  ...props.items.map((item) => ({
    id: item.id,
    name: item.name,
    quantity: item.quantity,
    icon: "fa-light fa-box",
  })),
]);
</script>

<template>
  <ul class="melt-contents">
    <li v-for="entry in entries" :key="entry.id" class="melt-contents__item">
      <i :class="entry.icon" aria-hidden="true" />
      <span>{{ entry.name }}</span>
      <span v-if="entry.quantity > 1" class="melt-contents__dim">
        ×{{ entry.quantity }}
      </span>
    </li>
    <li v-if="unlisted" class="melt-contents__item melt-contents__dim">
      {{ t("hangarPlanner.meltList.unlisted", { count: unlisted }) }}
    </li>
  </ul>
</template>

<style lang="scss" scoped>
.melt-contents {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.melt-contents__item {
  display: flex;
  gap: 8px;
  align-items: baseline;
  font-size: 0.9rem;

  i {
    width: 1rem;
    color: var(--color-text-dim);
    text-align: center;
  }
}

.melt-contents__dim {
  color: var(--color-text-dim);
}
</style>
