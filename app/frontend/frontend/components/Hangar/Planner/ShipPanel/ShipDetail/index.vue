<script lang="ts">
export default {
  name: "HangarPlannerShipDetail",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import ShipName from "@/frontend/components/Hangar/Planner/ShipName/index.vue";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useI18n } from "@/shared/composables/useI18n";
import type { HangarPlanModel } from "@/services/fyApi";

type Props = {
  title: string;
  // The ship the pick stands for; unset for one not chosen yet, such as a
  // store purchase of a ship the slot has still to pick.
  ship?: HangarPlanModel;
  sub?: string;
  actionLabel: string;
  busy?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  ship: undefined,
  sub: undefined,
  busy: false,
});

const emit = defineEmits<{
  commit: [];
}>();

const { t } = useI18n();
const { money } = usePlanMoney();

const metrics = computed(() => {
  const ship = props.ship;
  if (!ship) return [];

  return [
    {
      key: "cargo",
      value: ship.cargo ? `${ship.cargo} SCU` : undefined,
    },
    { key: "crew", value: ship.crew ?? undefined },
    { key: "size", value: ship.size ?? undefined },
    { key: "price", value: money(ship.pledgePrice) },
  ].filter((metric) => metric.value !== undefined);
});
</script>

<template>
  <article class="ship-detail" data-test="ship-detail">
    <img
      v-if="ship"
      :src="ship.image?.smallUrl || fallbackImage"
      alt=""
      class="ship-detail__image"
      loading="lazy"
    />
    <header class="ship-detail__head">
      <h3 class="ship-detail__title">
        <ShipName v-if="ship && ship.name === title" :ship="ship" />
        <template v-else>{{ title }}</template>
      </h3>
      <span v-if="sub || ship?.manufacturerName" class="ship-detail__sub">
        {{ sub ?? ship?.manufacturerName }}
      </span>
    </header>
    <dl v-if="metrics.length" class="ship-detail__metrics">
      <div
        v-for="metric in metrics"
        :key="metric.key"
        class="ship-detail__metric"
      >
        <dt>{{ t(`hangarPlanner.specs.${metric.key}`) }}</dt>
        <dd>{{ metric.value }}</dd>
      </div>
    </dl>
    <slot />
    <Btn
      :size="BtnSizesEnum.MD"
      :loading="busy"
      block
      data-test="ship-detail-commit"
      @click="emit('commit')"
    >
      <i class="fa-light fa-check" />
      {{ actionLabel }}
    </Btn>
  </article>
</template>

<style lang="scss" scoped>
.ship-detail {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.ship-detail__image {
  display: block;
  width: 100%;
  height: 150px;
  object-fit: cover;
  border-radius: 12px;
}

.ship-detail__head {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.ship-detail__title {
  margin: 0;
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--color-lifted);
}

.ship-detail__sub {
  font-size: 0.8rem;
  color: var(--color-text-dim);
}

.ship-detail__metrics {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 6px;
  margin: 0;
}

.ship-detail__metric {
  display: flex;
  flex-direction: column;
  gap: 3px;
  padding: 8px 10px;
  border-radius: 8px;
  background: var(--color-gray-black);

  dt {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 0.625rem;
    font-weight: 400;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--color-text-dim);
  }

  dd {
    margin: 0;
    font-size: 0.84375rem;
    font-weight: 600;
    color: var(--color-lifted);
  }
}
</style>
