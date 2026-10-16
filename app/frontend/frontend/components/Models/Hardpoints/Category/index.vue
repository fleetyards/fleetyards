<script lang="ts">
export default {
  name: "HardpointCategory",
};
</script>

<script lang="ts" setup>
import { type ComputedRef } from "vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type Hardpoint, HardpointCategoryEnum } from "@/services/fyApi";
import HardpointItems from "@/frontend/components/Models/Hardpoints/Items/index.vue";
import HardpointCategoryIcon from "@/frontend/components/Models/Hardpoints/CategoryIcon/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
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
      <HardpointCategoryIcon
        :category="category"
        class="hardpoint-category__icon"
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
