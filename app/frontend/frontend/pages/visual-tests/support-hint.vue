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
import { useComlink } from "@/shared/composables/useComlink";

const contexts: SupportPromptContext[] = [
  "hangarSync",
  "vehicleAdded",
  "fleetCreated",
  "loginMilestone",
  "visitMilestone",
];

const { forceNotify } = useSupportPrompt();
const comlink = useComlink();

const trigger = (context: SupportPromptContext) => {
  forceNotify(context, { count: 10 });
};

const openSyncModalPreview = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/pages/visual-tests/sync-modal/StatePreview.vue"),
    props: {
      title: "Hangar Sync",
      processSteps: [
        { name: "fetchHangar", status: "success" },
        { name: "submitData", status: "success" },
      ],
      currentPage: 5,
      pledges: [],
      result: {
        importedVehicles: ["v-1", "v-2", "v-3"],
        foundVehicles: ["v-4", "v-5"],
        missingModels: ["Mystery Ship"],
      },
      finished: true,
      finishedWithErrors: false,
    },
  });
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

  <Heading :level="HeadingLevelEnum.H2">In sync modal</Heading>
  <p>
    Opens a stand-in of the hangar sync modal with the inline hint at the
    bottom.
  </p>
  <div class="row">
    <div class="col-12">
      <Btn
        :size="BtnSizesEnum.SMALL"
        data-test="open-sync-modal-preview"
        @click="openSyncModalPreview"
      >
        Open sync modal preview
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
