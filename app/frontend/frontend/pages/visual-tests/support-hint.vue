<script lang="ts">
export default {
  name: "VisualTestsSupportHintPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import SupportHint from "@/shared/components/SupportHint/index.vue";
import { useSupportPrompt } from "@/shared/composables/useSupportPrompt";
import type { SupportPromptContext } from "@/shared/composables/useSupportPrompt";

const contexts: SupportPromptContext[] = [
  "hangarSync",
  "vehicleAdded",
  "fleetCreated",
  "loginMilestone",
  "visitMilestone",
];

const { forceNotify } = useSupportPrompt();

const trigger = (context: SupportPromptContext) => {
  forceNotify(context, { count: 10 });
};
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">Trigger notifications</Heading>
  <p>
    Fires the SupportHint as a persistent notification — bypasses the cooldown.
  </p>
  <div class="row">
    <div class="col-12">
      <Btn
        v-for="context in contexts"
        :key="`trigger-${context}`"
        :size="BtnSizesEnum.SMALL"
        :data-test="`trigger-support-hint-${context}`"
        @click="trigger(context)"
      >
        {{ context }}
      </Btn>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Inline variants</Heading>
  <p>Rendered inline (as used in the hangar sync modal).</p>
  <div class="row">
    <div
      v-for="context in contexts"
      :key="`inline-${context}`"
      class="col-12 col-md-6"
    >
      <SupportHint inline :context="context" :meta="{ count: 10 }" />
    </div>
  </div>
</template>
