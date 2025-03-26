<script lang="ts">
export default {
  name: "VisualTestsButtonsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";

const disabled = ref(false);

const toggleButton = () => {
  disabled.value = true;

  setTimeout(() => {
    disabled.value = false;
  }, 2000);
};
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">Button Sizes</Heading>
  <div class="row">
    <div class="col-12">
      <Btn
        :size="BtnSizesEnum.X_SMALL"
        :disabled="disabled"
        @click="toggleButton"
      >
        X-Small
      </Btn>
      <Btn
        :size="BtnSizesEnum.SMALL"
        :disabled="disabled"
        @click="toggleButton"
      >
        Small
      </Btn>
      <Btn
        :size="BtnSizesEnum.DEFAULT"
        :disabled="disabled"
        @click="toggleButton"
      >
        Default
      </Btn>
      <Btn
        :size="BtnSizesEnum.LARGE"
        :disabled="disabled"
        @click="toggleButton"
      >
        LARGE
      </Btn>
    </div>
  </div>
  <Heading :level="HeadingLevelEnum.H2">Button Variants</Heading>
  <div class="row">
    <div class="col-12">
      <Btn
        :variant="BtnVariantsEnum.DEFAULT"
        :disabled="disabled"
        @click="toggleButton"
      >
        Default
      </Btn>
      <Btn
        :variant="BtnVariantsEnum.LINK"
        :disabled="disabled"
        @click="toggleButton"
      >
        Link
      </Btn>
      <Btn
        :variant="BtnVariantsEnum.DANGER"
        :disabled="disabled"
        @click="toggleButton"
      >
        DANGER
      </Btn>
      <Btn
        :variant="BtnVariantsEnum.TRANSPARENT"
        :disabled="disabled"
        @click="toggleButton"
      >
        TRANSPARENT
      </Btn>
    </div>
  </div>
</template>
