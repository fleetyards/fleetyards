<script lang="ts">
export default {
  name: "PanelHeading",
};
</script>

<script lang="ts" setup>
import {
  PanelHeadingLevelEnum,
  PanelHeadingShadowEnum,
  PanelHeadingSizeEnum,
  PanelHeadingAlignmentEnum,
} from "@/shared/components/Panel/Heading/types";

type Props = {
  level?: PanelHeadingLevelEnum;
  shadow?: PanelHeadingShadowEnum;
  size?: PanelHeadingSizeEnum;
  titleAlign?: PanelHeadingAlignmentEnum;
};

withDefaults(defineProps<Props>(), {
  level: PanelHeadingLevelEnum.H2,
  shadow: undefined,
  size: PanelHeadingSizeEnum.DEFAULT,
  titleAlign: PanelHeadingAlignmentEnum.LEFT,
});

const slots = defineSlots();
</script>

<template>
  <div
    class="panel-heading"
    :class="{
      'panel-heading-top': shadow === 'top',
      'panel-heading-bottom': shadow === 'bottom',
      'panel-heading-with-actions': slots.actions,
    }"
  >
    <component
      :is="level"
      class="panel-heading-title"
      :class="{
        'panel-heading-title-title-large': size === 'large',
        'panel-heading-title-align-left': titleAlign === 'left',
        'panel-heading-title-align-center': titleAlign === 'center',
        'panel-heading-title-align-right': titleAlign === 'right',
        'panel-heading-title-align-justify': titleAlign === 'justify',
      }"
    >
      <span class="panel-heading-title-main">
        <slot name="default" />
      </span>

      <small class="panel-heading-title-sub">
        <slot name="subtitle" />
      </small>
    </component>
    <div class="panel-heading-actions">
      <slot name="actions" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
