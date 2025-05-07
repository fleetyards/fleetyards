<script lang="ts">
export default {
  name: "BasePanelHeading",
};
</script>

<script lang="ts" setup>
import { PanelHeadingShadowEnum } from "@/shared/components/base/Panel/Heading/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  HeadingLevelEnum,
  HeadingSizeEnum,
} from "@/shared/components/base/Heading/types";

type Props = {
  shadow?: PanelHeadingShadowEnum;
  level?: HeadingLevelEnum;
  size?: HeadingSizeEnum;
  hero?: boolean;
};

withDefaults(defineProps<Props>(), {
  shadow: undefined,
  level: HeadingLevelEnum.H1,
  size: HeadingSizeEnum.XXL,
  hero: false,
});

const slots = defineSlots<{
  default: [];
  subtitle: [];
  actions: [];
}>();
</script>

<template>
  <div
    class="panel-heading"
    :class="{
      'panel-heading--top': shadow === 'top',
      'panel-heading--bottom': shadow === 'bottom',
    }"
  >
    <Heading
      :level="level"
      :size="size"
      hero
      shadow
      class="panel-heading__title"
      :class="{
        'panel-heading__title--with-actions': slots.actions,
      }"
    >
      <template #default>
        <slot name="default" />
      </template>
      <template v-if="slots.subtitle" #subHeading>
        <slot name="subtitle" />
      </template>
    </Heading>

    <div v-if="slots.actions" class="panel-heading__actions">
      <slot name="actions" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
