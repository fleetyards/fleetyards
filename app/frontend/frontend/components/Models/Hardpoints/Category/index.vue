<script lang="ts">
export default {
  name: "HardpointCategory",
};
</script>

<script lang="ts" setup>
import { type ComputedRef } from "vue";
import { useI18n } from "@/shared/composables/useI18n";
import { HardpointCategoryEnum } from "@/services/fyAdminApi";
import { type Hardpoint } from "@/services/fyApi";
import HardpointItems from "@/frontend/components/Models/Hardpoints/Items/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";

import { categorySvgIcons } from "@/frontend/components/Models/Hardpoints/categoryIcon";
import {
  powerPlantContextKey,
  type PowerPlantContext,
} from "@/frontend/components/Models/Hardpoints/powerPlant";

type Props = {
  hardpoints: Hardpoint[];
  category: HardpointCategoryEnum;
};

const props = defineProps<Props>();

const { t } = useI18n();

const powerPlantContext = computed<PowerPlantContext | null>(() => {
  if (props.category !== HardpointCategoryEnum.POWERPLANT) return null;

  const plants = props.hardpoints
    .map((hp) => hp.component)
    .filter((c) => c?.typeData && "powerBase" in c.typeData && c.size);

  if (plants.length === 0) return null;

  return {
    count: plants.length,
    sizeSum: plants.reduce((sum, c) => sum + Number(c!.size), 0),
  };
});

// Each plant item resolves its own pip share from this ship-level context.
provide(powerPlantContextKey, powerPlantContext);

const modelSlug = inject<ComputedRef<string> | undefined>(
  "modelSlug",
  undefined,
);

const cargoGridsRoute = computed(() => ({
  name: "cargo-grids",
  query: { ship: modelSlug?.value },
}));
</script>

<template>
  <div class="hardpoint-category">
    <div class="hardpoint-category__label">
      <span
        v-if="category === HardpointCategoryEnum.CARGOGRID"
        class="hardpoint-category__icon"
      >
        <i class="fa-duotone fa-thin fa-cubes fa-lg" />
      </span>
      <span
        v-else-if="category === HardpointCategoryEnum.SEAT"
        class="hardpoint-category__icon"
      >
        <i class="fa-duotone fa-person-seat-reclined fa-lg" />
      </span>
      <span
        v-else-if="category === HardpointCategoryEnum.MODULE"
        class="hardpoint-category__icon"
      >
        <i class="fa-duotone fa-puzzle fa-lg" />
      </span>
      <span
        v-else-if="category === HardpointCategoryEnum.SALVAGEFILLERSTATION"
        class="hardpoint-category__icon"
      >
        <i class="fa-duotone fa-bin-recycle fa-lg" />
      </span>
      <span
        v-else-if="category === HardpointCategoryEnum.ARMOR"
        class="hardpoint-category__icon"
      >
        <i class="fa-duotone fa-shield-halved fa-lg" />
      </span>
      <span
        v-else-if="category === HardpointCategoryEnum.COUNTERMEASURES"
        class="hardpoint-category__icon"
      >
        <i class="fa-duotone fa-shield-quartered fa-lg" />
      </span>
      <span
        v-else-if="category === HardpointCategoryEnum.LIFESUPPORT"
        class="hardpoint-category__icon"
      >
        <i class="fa-duotone fa-heart-pulse fa-lg" />
      </span>
      <span
        v-else-if="category === HardpointCategoryEnum.RELAY"
        class="hardpoint-category__icon"
      >
        <i class="fa-duotone fa-transformer-bolt fa-lg" />
      </span>
      <img
        v-else
        :src="categorySvgIcons[category as keyof typeof categorySvgIcons]"
        class="hardpoint-category__icon hardpoint-category__icon--img"
        :alt="`icon-${category}`"
      />
      <span class="hardpoint-category__name">
        {{ t(`labels.hardpoint.categories.${category}`) }}
      </span>
      <Btn
        v-if="category === HardpointCategoryEnum.CARGOGRID && modelSlug"
        :to="cargoGridsRoute"
        class="hardpoint-category__link"
      >
        <i class="fa-light fa-cube" />
        3D
      </Btn>
    </div>
    <HardpointItems
      :hardpoints="hardpoints"
      :category="category as HardpointCategoryEnum"
    />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
