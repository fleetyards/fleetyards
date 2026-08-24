<script lang="ts">
export default {
  name: "PrimaryAction",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";

/*
 * The one obvious next step a page offers, floated over it. It was a
 * `<div @click>` in a circle, which meant the hangar's primary action could not
 * be reached from the keyboard, had no focus ring and no button semantics - the
 * same defect Btn was rebuilt to fix, in the one control that matters most on
 * the page.
 *
 * So it renders a Btn now, which brings the keyboard, the focus ring, the
 * surface and the hover with it, and drops a hover colour computed with
 * `invert()` along with two border tokens belonging to the panel this design
 * retired. The circle stays - it is the one shape override, and the app is round
 * elsewhere too, in Avatar.
 */
type Props = {
  action?: () => void;
  icon?: string;
  label?: string;
};

withDefaults(defineProps<Props>(), {
  action: undefined,
  icon: "fa-light fa-plus",
  label: undefined,
});
</script>

<template>
  <transition name="back-to-top-fade">
    <div v-if="action" class="primary-action">
      <Btn
        v-tooltip="label"
        :aria-label="label"
        :size="BtnSizesEnum.LG"
        :variant="BtnVariantsEnum.SOLID"
        class="primary-action__btn"
        data-test="primary-action"
        @click="action"
      >
        <i :class="icon" />
      </Btn>
    </div>
  </transition>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
