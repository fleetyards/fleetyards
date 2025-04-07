<script lang="ts">
export default {
  name: "BaseBox",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import {
  HeadingLevelEnum,
  HeadingSizeEnum,
} from "@/shared/components/base/Heading/types";

type Props = {
  large?: boolean;
  variant?: PanelVariantsEnum;
  headingLevel?: HeadingLevelEnum;
  headingSize?: HeadingSizeEnum;
  animated?: boolean;
};

withDefaults(defineProps<Props>(), {
  large: false,
  variant: undefined,
  headingLevel: HeadingLevelEnum.H1,
  headingSize: HeadingSizeEnum.XXL,
  animated: false,
});

const slots = defineSlots<{
  default: [];
  heading: [];
  footer: [];
}>();
</script>

<template>
  <div
    :class="{
      'box-large': large,
    }"
    class="box"
  >
    <Panel :variant="variant" :animated="animated" slim>
      <PanelHeading
        v-if="slots.heading"
        :level="headingLevel"
        :size="headingSize"
      >
        <slot name="heading" />
      </PanelHeading>
      <PanelBody no-padding-top>
        <slot />
      </PanelBody>
    </Panel>
    <slot name="footer" />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
