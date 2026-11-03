<script lang="ts">
export default {
  name: "CompareKindSwitch",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import DuotoneGlyph from "@/shared/components/DuotoneGlyph/index.vue";
import { SHIP_GLYPH } from "@/shared/glyphs/ships";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const route = useRoute();

const kinds = [
  { route: "compare", label: "nav.compare.ships", glyph: SHIP_GLYPH },
  {
    route: "compare-components",
    label: "nav.compare.components",
    icon: "fa-duotone fa-microchip",
  },
  {
    route: "compare-equipment",
    label: "nav.compare.equipment",
    icon: "fa-duotone fa-shirt",
  },
] as const;
</script>

<template>
  <BtnGroup segmented :size="BtnSizesEnum.MD">
    <Btn
      v-for="kind in kinds"
      :key="kind.route"
      :to="{ name: kind.route }"
      :active="route.name === kind.route"
      :aria-label="t(kind.label)"
      :data-test="`compare-kind-${kind.route}`"
      mobile-icon-only
    >
      <DuotoneGlyph v-if="'glyph' in kind" :glyph="kind.glyph" />
      <i v-else :class="kind.icon" />
      {{ t(kind.label) }}
    </Btn>
  </BtnGroup>
</template>
