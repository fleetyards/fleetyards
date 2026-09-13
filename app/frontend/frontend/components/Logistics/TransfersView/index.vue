<script lang="ts">
export default {
  name: "LogisticsTransfersView",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import type { Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import TransferTable from "@/frontend/components/Logistics/TransferTable/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useInventoryTransfers } from "@/frontend/composables/useInventoryTransfers";

type Props = {
  crumbs: Crumb[];
  // Present when the page acts for a fleet; absent for a user's own transfers.
  fleetSlug?: string;
};

const props = withDefaults(defineProps<Props>(), { fleetSlug: undefined });

const { t } = useI18n();

const {
  direction,
  transfers,
  isLoading,
  busy,
  onAccept,
  onDecline,
  onCancel,
  onReport,
} = useInventoryTransfers(() => props.fleetSlug);

const DIRECTIONS = ["incoming", "outgoing"] as const;
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Heading size="hero" hero>
    {{ t("headlines.logistics.transfers") }}
  </Heading>

  <!-- `Heading` takes only `default` and `subHeading`, so controls belong in
       the page header the way every other list does it. -->
  <Teleport to="#header-right">
    <BtnGroup>
      <Btn
        v-for="value in DIRECTIONS"
        :key="value"
        :size="BtnSizesEnum.MD"
        :variant="
          direction === value ? BtnVariantsEnum.SOLID : BtnVariantsEnum.BARE
        "
        :data-test="`transfers-${value}`"
        @click="direction = value"
      >
        {{ t(`labels.logistics.${value}`) }}
      </Btn>
    </BtnGroup>
  </Teleport>

  <TransferTable
    :transfers="transfers"
    :direction="direction"
    :loading="isLoading"
    :busy="busy"
    @accept="onAccept"
    @decline="onDecline"
    @cancel="onCancel"
    @report="onReport"
  />
</template>
