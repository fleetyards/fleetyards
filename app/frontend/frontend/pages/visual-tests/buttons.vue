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

const disabled = ref<string[]>([]);

const toggleButton = (name: string) => {
  if (disabled.value.includes(name)) {
    disabled.value = disabled.value.filter((n) => n !== name);
  } else {
    disabled.value.push(name);
  }
  setTimeout(() => {
    disabled.value = disabled.value.filter((n) => n !== name);
  }, 2000);
};

const isDisabled = (name: string) => {
  return disabled.value.includes(name);
};
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">Button Sizes</Heading>
  <div class="row">
    <div class="col-12">
      <Btn
        :size="BtnSizesEnum.SMALL"
        :disabled="isDisabled('Small')"
        @click="toggleButton('Small')"
      >
        Small
      </Btn>
      <Btn
        :size="BtnSizesEnum.X_SMALL"
        :disabled="isDisabled('X-Small')"
        @click="toggleButton('X-Small')"
      >
        X-Small
      </Btn>
      <Btn
        :size="BtnSizesEnum.DEFAULT"
        :disabled="isDisabled('DefaultSize')"
        @click="toggleButton('DefaultSize')"
      >
        Default
      </Btn>
      <Btn
        :size="BtnSizesEnum.LARGE"
        :disabled="isDisabled('Large')"
        @click="toggleButton('Large')"
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
        :disabled="isDisabled('Default')"
        @click="toggleButton('Default')"
      >
        Default
      </Btn>
      <Btn
        :variant="BtnVariantsEnum.DANGER"
        :disabled="isDisabled('Danger')"
        @click="toggleButton('Danger')"
      >
        DANGER
      </Btn>
      <Btn
        :variant="BtnVariantsEnum.TRANSPARENT"
        :disabled="isDisabled('Transparent')"
        @click="toggleButton('Transparent')"
      >
        TRANSPARENT
      </Btn>
      <Btn
        :variant="BtnVariantsEnum.LINK"
        :disabled="isDisabled('Link')"
        @click="toggleButton('Link')"
      >
        Link
      </Btn>
    </div>
  </div>
</template>
