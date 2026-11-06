<script lang="ts">
export default {
  name: "HardpointGroup",
};
</script>

<script lang="ts" setup>
import { groupBy, sortBy } from "@/shared/utils/Array";
import Panel from "@/shared/components/base/Panel/index.vue";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { type Hardpoint, type HardpointGroupEnum } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import HardpointCategory from "@/frontend/components/Models/Hardpoints/Category/index.vue";
import SummaryCategories from "@/frontend/components/Models/Hardpoints/Summary/Categories/index.vue";
import { minimalCategories } from "@/frontend/components/Models/Hardpoints/summaryRows";
import {
  hardpointCardFoldKey,
  metricsCardFoldKey,
} from "@/frontend/components/Models/MetricsCard/fold";
import { HardpointCategoryEnum } from "@/services/fyAdminApi";

type Props = {
  group: HardpointGroupEnum;
  hardpoints: Hardpoint[];
  withoutTitle?: boolean;
  // The hardpoints with the reader's picked modules grafted on, which a summary
  // lists the contents of. The rows the full card draws pick their own.
  fitted?: Hardpoint[];
  // Ship matrix data has nothing more to expand to.
  summaryOnly?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withoutTitle: false,
  fitted: undefined,
  summaryOnly: false,
});

const fold = inject(hardpointCardFoldKey, undefined);

if (fold) {
  provide(metricsCardFoldKey, fold);
}

const summaryCategories = computed(() =>
  fold ? minimalCategories(props.fitted ?? props.hardpoints) : [],
);

const summary = computed(() =>
  props.summaryOnly || fold?.collapsed(props.group)
    ? summaryCategories.value
    : [],
);

const { t } = useI18n();

const groupLabel = computed(() =>
  t(`labels.hardpoint.groups.${props.group.toLowerCase()}`),
);

const groupByCategory = (items: Hardpoint[]) => {
  return groupBy<Hardpoint>(sortBy<Hardpoint>(items, "category"), "category");
};

const categories = computed(() => {
  const items = groupByCategory(props.hardpoints);

  const availableCategories: { [key in HardpointCategoryEnum]?: Hardpoint[] } =
    {};

  Object.keys(items).forEach((category) => {
    if (
      [
        `${HardpointCategoryEnum.CONTROLLER}`,
        `${HardpointCategoryEnum.UNKNOWN}`,
      ].includes(category as HardpointCategoryEnum)
    ) {
      return;
    }

    availableCategories[category as HardpointCategoryEnum] = items[category];
  });

  return availableCategories;
});
</script>

<template>
  <div
    v-if="hardpoints.length && Object.values(categories).length"
    class="hardpoint-group"
  >
    <MetricsCard
      v-if="!withoutTitle"
      variant="slim"
      :title="groupLabel"
      :collapse-key="
        !summaryOnly && summaryCategories.length ? group : undefined
      "
      keep-body
    >
      <SummaryCategories v-if="summary.length" :categories="summary" />
      <template v-else>
        <HardpointCategory
          v-for="(items, category) in categories"
          :key="category"
          :hardpoints="items || []"
          :category="category"
        />
      </template>
    </MetricsCard>
    <Panel v-else>
      <div class="hardpoint-group__inner">
        <HardpointCategory
          v-for="(items, category) in categories"
          :key="category"
          :hardpoints="items || []"
          :category="category"
        />
      </div>
    </Panel>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
