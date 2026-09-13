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

import FilteredList from "@/shared/components/FilteredList/index.vue";
import TransferTable from "@/frontend/components/Logistics/TransferTable/index.vue";
import TransferFilterForm from "@/frontend/components/Logistics/TransferFilterForm/index.vue";
import { useTransferFilters } from "@/frontend/composables/useTransferFilters";
import { useI18n } from "@/shared/composables/useI18n";
import { useInventoryTransfers } from "@/frontend/composables/useInventoryTransfers";
import { useTransferDirection } from "@/frontend/composables/useTransferDirection";

type Props = {
  crumbs: Crumb[];
  // Present when the page acts for a fleet; absent for a user's own transfers.
  fleetSlug?: string;
  incomingRoute: string;
  outgoingRoute: string;
};

const props = withDefaults(defineProps<Props>(), { fleetSlug: undefined });

const { t } = useI18n();

const { direction } = useTransferDirection({
  incoming: props.incomingRoute,
  outgoing: props.outgoingRoute,
});

const { isFilterSelected, getQuery } = useTransferFilters();

const {
  transfers,
  isLoading,
  busy,
  refetch,
  asyncStatus,
  onAccept,
  onDecline,
  onCancel,
  onReport,
} = useInventoryTransfers(() => props.fleetSlug, direction, getQuery);

const DIRECTIONS = ["incoming", "outgoing"] as const;
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Heading size="hero" hero>
    {{ t("headlines.logistics.transfers") }}
  </Heading>

  <FilteredList
    name="inventory-transfers"
    :records="transfers"
    :async-status="asyncStatus"
    placeholders
    :hide-empty="true"
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <TransferFilterForm :update-callback="refetch" />
    </template>

    <!-- The same segmented control the stock and transactions views use, in
         the same slot, because it is the same kind of choice. -->
    <template #actions-left>
      <BtnGroup segmented>
        <Btn
          v-for="value in DIRECTIONS"
          :key="value"
          :active="direction === value"
          mobile-icon-only
          :data-test="`transfers-${value}`"
          @click="direction = value"
        >
          <i
            class="fa-duotone"
            :class="
              value === 'incoming'
                ? 'fa-arrow-right-to-bracket'
                : 'fa-arrow-right-from-bracket'
            "
          />
          {{ t(`labels.logistics.${value}`) }}
        </Btn>
      </BtnGroup>
    </template>

    <template #default>
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
  </FilteredList>
</template>
