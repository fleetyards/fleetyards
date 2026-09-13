<script lang="ts">
export default {
  name: "FleetLogisticsTransfersPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Grid from "@/shared/components/base/Grid/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import TransferPanel from "@/frontend/components/Logistics/TransferPanel/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  type InventoryTransfer,
  useFleetInventoryTransfers,
  useFleetInventories,
  useAcceptFleetInventoryTransfer,
  useDeclineFleetInventoryTransfer,
  useCancelFleetInventoryTransfer,
  useReportFleetInventoryTransfer,
} from "@/services/fyApi";

const { t } = useI18n();
const route = useRoute();
const comlink = useComlink();
const { displayAlert } = useAppNotifications();

const fleetSlug = computed(() => route.params.slug as string);

const direction = ref<"incoming" | "outgoing">("incoming");

const queryParams = computed(() => ({ direction: direction.value }));

const { data, isLoading, refetch } = useFleetInventoryTransfers(
  fleetSlug,
  queryParams,
);
const { data: inventories } = useFleetInventories(fleetSlug);

const transfers = computed<InventoryTransfer[]>(() => data.value?.items ?? []);

const { mutateAsync: accept } = useAcceptFleetInventoryTransfer();
const { mutateAsync: decline } = useDeclineFleetInventoryTransfer();
const { mutateAsync: cancel } = useCancelFleetInventoryTransfer();
const { mutateAsync: report } = useReportFleetInventoryTransfer();

const busy = ref(false);

const run = async (action: () => Promise<unknown>) => {
  busy.value = true;

  try {
    await action();
    await refetch();
  } catch {
    displayAlert({ text: t("messages.logistics.transfer.resolve.failure") });
  } finally {
    busy.value = false;
  }
};

// Where it lands is this side's choice -- the sender never named an inventory.
// With one to land in there is nothing to ask about.
const onAccept = (transfer: InventoryTransfer) => {
  const options = inventories.value?.items ?? [];

  if (options.length === 1) {
    void run(() =>
      accept({
        fleetSlug: fleetSlug.value,
        id: transfer.id,
        data: { fleetInventoryId: options[0].id },
      }),
    );
    return;
  }

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Logistics/TransferAcceptModal/index.vue"),
    props: {
      transfer,
      inventories: options,
      onAccept: (inventoryId: string) =>
        run(() =>
          accept({
            fleetSlug: fleetSlug.value,
            id: transfer.id,
            data: { fleetInventoryId: inventoryId },
          }),
        ),
    },
  });
};

const onDecline = (transfer: InventoryTransfer) =>
  run(() => decline({ fleetSlug: fleetSlug.value, id: transfer.id }));

const onCancel = (transfer: InventoryTransfer) =>
  run(() => cancel({ fleetSlug: fleetSlug.value, id: transfer.id }));

const onReport = (transfer: InventoryTransfer) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Logistics/TransferReportModal/index.vue"),
    props: {
      transfer,
      onReport: (payload: { reason: string; note?: string }) =>
        run(() =>
          report({
            fleetSlug: fleetSlug.value,
            id: transfer.id,
            data: payload as Parameters<typeof report>[0]["data"],
          }),
        ),
    },
  });
};
</script>

<template>
  <Heading>
    {{ t("headlines.logistics.transfers") }}

    <template #right>
      <BtnGroup>
        <Btn
          :size="BtnSizesEnum.SM"
          :variant="
            direction === 'incoming'
              ? BtnVariantsEnum.SOLID
              : BtnVariantsEnum.BARE
          "
          data-test="fleet-transfers-incoming"
          @click="direction = 'incoming'"
        >
          {{ t("labels.logistics.incoming") }}
        </Btn>
        <Btn
          :size="BtnSizesEnum.SM"
          :variant="
            direction === 'outgoing'
              ? BtnVariantsEnum.SOLID
              : BtnVariantsEnum.BARE
          "
          data-test="fleet-transfers-outgoing"
          @click="direction = 'outgoing'"
        >
          {{ t("labels.logistics.outgoing") }}
        </Btn>
      </BtnGroup>
    </template>
  </Heading>

  <Loader :loading="isLoading" />

  <Empty
    v-if="!isLoading && transfers.length === 0"
    variant="box"
    hide-actions
    name="transfers"
  />

  <Grid v-else :records="transfers" primary-key="id">
    <template #default="{ record }">
      <TransferPanel
        :transfer="record"
        :direction="direction"
        :busy="busy"
        @accept="onAccept"
        @decline="onDecline"
        @cancel="onCancel"
        @report="onReport"
      />
    </template>
  </Grid>
</template>
