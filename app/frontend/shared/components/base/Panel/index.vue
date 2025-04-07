<script lang="ts">
export default {
  name: "BasePanel",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import PanelLink from "@/shared/components/base/Panel/Link/index.vue";
import PanelBgImage from "@/shared/components/base/Panel/BgImage/index.vue";
import PanelShadow from "@/shared/components/base/Panel/Shadow/index.vue";
import {
  PanelVariantsEnum,
  PanelTransparenciesEnum,
  PanelAlignmentsEnum,
  PanelShadowsEnum,
  PanelBgAlignmentsEnum,
  PanelBgRoundedEnum,
  PanelBgColorsEnum,
} from "@/shared/components/base/Panel/types";

type Props = {
  alignment?: PanelAlignmentsEnum;
  bgAlign?: PanelBgAlignmentsEnum;
  bgImage?: string;
  bgColor?: PanelBgColorsEnum;
  bgRounded?: PanelBgRoundedEnum;
  animated?: boolean;
  highlight?: boolean;
  inset?: boolean;
  linkLabel?: string;
  outerSpacing?: boolean;
  slim?: boolean;
  shadow?: PanelShadowsEnum;
  transparency?: PanelTransparenciesEnum;
  to?: RouteLocationRaw;
  variant?: PanelVariantsEnum;
};

const props = withDefaults(defineProps<Props>(), {
  alignment: undefined,
  bgAlign: undefined,
  bgImage: undefined,
  bgColor: PanelBgColorsEnum.DEFAULT,
  bgRounded: PanelBgRoundedEnum.ALL,
  animated: false,
  highlight: false,
  inset: false,
  linkLabel: undefined,
  outerSpacing: true,
  slim: false,
  shadow: undefined,
  transparency: PanelTransparenciesEnum.DEFAULT,
  to: undefined,
  variant: PanelVariantsEnum.DEFAULT,
});

const variantClass = computed(() => `panel-wrapper--${props.variant}`);

const bgColorClass = computed(() => `panel-wrapper--${props.bgColor}-bg`);

const transparencyClass = computed(
  () => `panel--transparency-${props.transparency}`,
);
</script>

<template>
  <div
    :class="{
      'panel-wrapper--outer-spacing': outerSpacing,
      'panel-wrapper--highlight': highlight,
      'panel-wrapper--animated': animated,
      [variantClass]: true,
      [bgColorClass]: true,
    }"
    class="panel-wrapper"
  >
    <div
      :class="{
        [transparencyClass]: true,
      }"
      class="panel"
    >
      <div
        :class="{
          'panel-inner--text': inset,
          'panel-inner--left': alignment === 'left',
          'panel-inner--right': alignment === 'right',
          'panel-inner--slim': slim,
        }"
        class="panel-inner"
      >
        <PanelBgImage
          v-if="bgImage"
          :image="bgImage"
          :rounded="bgRounded"
          :alignment="bgAlign"
        />
        <PanelShadow v-if="shadow" :alignment="shadow" />
        <PanelLink v-if="to && linkLabel" :to="to" :label="linkLabel" />
        <slot name="default" />
      </div>
      <slot name="footer" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
