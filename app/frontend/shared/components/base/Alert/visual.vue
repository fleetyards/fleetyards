<script lang="ts">
export default {
  name: "VisualTestsAlertsPage",
};
</script>

<script lang="ts" setup>
import Alert from "@/shared/components/base/Alert/index.vue";
import {
  AlertSizesEnum,
  AlertVariantsEnum,
} from "@/shared/components/base/Alert/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";

const variants = Object.values(AlertVariantsEnum);

const sid = ref("MARU");

const dismissed = ref(false);
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2" mt>Variants</Heading>
  <Alert v-for="variant in variants" :key="variant" :variant="variant">
    A {{ variant }} notice with one line of text.
  </Alert>

  <Heading :level="HeadingLevelEnum.H2" mt>Title and text</Heading>
  <Alert
    v-for="variant in variants"
    :key="variant"
    :variant="variant"
    title="Your fleet ID is not protected"
  >
    Another fleet that verifies the RSI organisation MARU can claim it, and your
    fleet's address changes.
  </Alert>

  <Heading :level="HeadingLevelEnum.H2" mt>With an action</Heading>
  <Alert
    :variant="AlertVariantsEnum.WARNING"
    title="Your fleet ID is not protected"
  >
    Another fleet that verifies the RSI organisation MARU can claim it.
    <template #actions>
      <Btn :size="BtnSizesEnum.SM" :variant="BtnVariantsEnum.BARE">
        Verify
        <i class="fa-light fa-chevron-right" />
      </Btn>
    </template>
  </Alert>
  <Alert :variant="AlertVariantsEnum.INFO">
    Fleet features are rolling out to supporters first.
    <template #actions>
      <Btn :size="BtnSizesEnum.SM">Learn more</Btn>
    </template>
  </Alert>

  <Heading :level="HeadingLevelEnum.H2" mt>Dismissible</Heading>
  <Alert
    v-if="!dismissed"
    :variant="AlertVariantsEnum.NEUTRAL"
    title="Tip"
    dismissible
    @dismiss="dismissed = true"
  >
    Drag a ship onto a group to file it there.
  </Alert>
  <Btn v-else :size="BtnSizesEnum.SM" @click="dismissed = false">
    Show it again
  </Btn>

  <Heading :level="HeadingLevelEnum.H2" mt>Compact</Heading>
  <Alert
    v-for="variant in variants"
    :key="variant"
    :variant="variant"
    :size="AlertSizesEnum.COMPACT"
  >
    A compact {{ variant }} notice.
  </Alert>

  <Heading :level="HeadingLevelEnum.H2" mt>Long text</Heading>
  <Alert
    :variant="AlertVariantsEnum.DANGER"
    title="RSI is refusing our requests"
    dismissible
  >
    Hangar syncs and verification checks will fail until the block is lifted.
    Nothing you entered is lost: the checks run again once RSI answers, and the
    hangar sync can be started again from the hangar page. This paragraph runs
    on so the wrapping and the icon's alignment can be judged.
    <template #actions>
      <Btn :size="BtnSizesEnum.SM">Status page</Btn>
    </template>
  </Alert>

  <Heading :level="HeadingLevelEnum.H2" mt>In context: above a form</Heading>
  <div class="row">
    <div class="col-12 col-lg-8">
      <Alert
        :variant="AlertVariantsEnum.WARNING"
        title="Your fleet ID is not protected"
      >
        Another fleet that verifies the RSI organisation MARU can claim it.
        <template #actions>
          <Btn :size="BtnSizesEnum.SM" :variant="BtnVariantsEnum.BARE">
            Verify
            <i class="fa-light fa-chevron-right" />
          </Btn>
        </template>
      </Alert>
      <div class="row">
        <div class="col-12 col-md-6">
          <FormInput v-model="sid" name="fid" label="Fleet ID" />
        </div>
        <div class="col-12 col-md-6">
          <FormInput v-model="sid" name="rsiSid" label="SID" />
        </div>
      </div>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2" mt>
    Narrow column: the action drops below
  </Heading>
  <div class="vt-narrow-column">
    <Alert
      :variant="AlertVariantsEnum.WARNING"
      title="Your fleet ID is not protected"
      dismissible
    >
      Another fleet that verifies the RSI organisation MARU can claim it.
      <template #actions>
        <Btn :size="BtnSizesEnum.SM" :variant="BtnVariantsEnum.BARE">
          Verify
          <i class="fa-light fa-chevron-right" />
        </Btn>
      </template>
    </Alert>
  </div>
</template>

<style lang="scss" scoped>
.vt-narrow-column {
  width: 361px;
  outline: 1px dashed rgba(#fff, 0.15);
}
</style>
