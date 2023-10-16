<template>
  <div
    :class="{
      'panel-outer-spacing': outerSpacing,
      'panel-highlight': highlight,
    }"
    class="panel-wrapper"
  >
    <div
      :class="{
        [variantClass]: true,
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

type Props = {
  outerSpacing?: boolean;
  transparency?: "default" | "more" | "complete";
  highlight?: boolean;
  variant?: "default" | "primary" | "success";
  alignment?: "left" | "right";
  inset?: boolean;
  shadow?: "left" | "right";
  bgImage?: string;
  bgAlign?: "left" | "right";
  bgRounded?: "all" | "left" | "right" | "top" | "bottom";
  to?: RouteLocationRaw;
  linkLabel?: string;
  slim?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  outerSpacing: true,
  transparency: "default",
  highlight: false,
  inset: false,
  alignment: undefined,
  variant: "default",
  shadow: undefined,
  bgImage: undefined,
  bgAlign: undefined,
  bgRounded: "all",
  to: undefined,
  linkLabel: undefined,
  slim: false,
});

const variantClass = computed(() => `panel-${props.variant}`);

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
@import "./index.scss";
</style>
