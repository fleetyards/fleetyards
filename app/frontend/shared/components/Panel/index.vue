<template>
  <div
    :class="{
      'panel-outer-spacing': outerSpacing,
      'panel-highlight': highlight,
      'panel-wrapper-error': variant === PanelVariantsEnum.ERROR,
      [variantClass]: true,
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
          'panel-inner-text': inset,
          'panel-inner-left': alignment === 'left',
          'panel-inner-right': alignment === 'right',
          'panel-inner-slim': slim,
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

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import PanelLink from "@/shared/components/Panel/Link/index.vue";
import PanelBgImage from "@/shared/components/Panel/BgImage/index.vue";
import PanelShadow from "@/shared/components/Panel/Shadow/index.vue";
import {
  PanelVariantsEnum,
  PanelTransparenciesEnum,
  PanelAlignmentsEnum,
  PanelShadowsEnum,
  PanelBgAlignmentsEnum,
  PanelBgRoundedEnum,
} from "@/shared/components/Panel/types";

type Props = {
  alignment?: PanelAlignmentsEnum;
  bgAlign?: PanelBgAlignmentsEnum;
  bgImage?: string;
  bgRounded?: PanelBgRoundedEnum;
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
  bgRounded: PanelBgRoundedEnum.ALL,
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

const variantClass = computed(() => `panel-wrapper-${props.variant}`);

const transparencyClass = computed(
  () => `panel-transparency-${props.transparency}`,
);
</script>

<script lang="ts">
export default {
  name: "BasePanel",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
