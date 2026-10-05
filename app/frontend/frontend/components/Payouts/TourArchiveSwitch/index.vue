<script lang="ts">
export default {
  name: "PayoutsTourArchiveSwitch",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const archived = defineModel<boolean>({ default: false });

const { t } = useI18n();
</script>

<template>
  <BtnGroup
    segmented
    class="tour-archive-switch"
    data-test="tours-archive-switch"
  >
    <Btn
      :active="!archived"
      mobile-icon-only
      data-test="tours-tab-current"
      @click="archived = false"
    >
      <i class="fa-light fa-route" />
      {{ t("labels.payouts.activeTours") }}
    </Btn>
    <Btn
      :active="archived"
      mobile-icon-only
      data-test="tours-tab-archived"
      @click="archived = true"
    >
      <i class="fa-light fa-box-archive" />
      {{ t("labels.payouts.archived") }}
    </Btn>
  </BtnGroup>
</template>

<style lang="scss" scoped>
.tour-archive-switch {
  margin-bottom: 16px;
}
</style>
