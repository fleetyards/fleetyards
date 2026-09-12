<script lang="ts">
export default {
  name: "HangarTransfersPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
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
  useHangarInventoryTransfers,
  useHangarInventories,
  useAcceptHangarInventoryTransfer,
  useDeclineHangarInventoryTransfer,
  useCancelHangarInventoryTransfer,
  useReportHangarInventoryTransfer,
} from "@/services/fyApi";

const { t } = useI18n();
const comlink = useComlink();
const { displayAlert } = useAppNotifications();

const direction = ref<"incoming" | "outgoing">("incoming");

const queryParams = computed(() => ({ direction: direction.value }));

const { data, isLoading, refetch } = useHangarInventoryTransfers(queryParams);
const { data: inventories } = useHangarInventories();

const transfers = computed<InventoryTransfer[]>(() => data.value?.items ?? []);

const { mutateAsync: accept } = useAcceptHangarInventoryTransfer();
const { mutateAsync: decline } = useDeclineHangarInventoryTransfer();
const { mutateAsync: cancel } = useCancelHangarInventoryTransfer();
const { mutateAsync: report } = useReportHangarInventoryTransfer();

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

// Accepting needs a destination, which is this side's choice -- the sender
// never named one. With a single inventory there is nothing to ask about.
const onAccept = (transfer: InventoryTransfer) => {
  const options = inventories.value?.items ?? [];

  if (options.length === 1) {
    void run(() =>
      accept({ id: transfer.id, data: { inventoryId: options[0].id } }),
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
        run(() => accept({ id: transfer.id, data: { inventoryId } })),
    },
  });
};

const onDecline = (transfer: InventoryTransfer) =>
  run(() => decline({ id: transfer.id }));

const onCancel = (transfer: InventoryTransfer) =>
  run(() => cancel({ id: transfer.id }));

const onReport = (transfer: InventoryTransfer) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Logistics/TransferReportModal/index.vue"),
    props: {
      transfer,
      onReport: (payload: { reason: string; note?: string }) =>
        run(() =>
          report({
            id: transfer.id,
            data: payload as Parameters<typeof report>[0]["data"],
          }),
        ),
    },
  });
};
</script>

<template>
  <section class="container">
    <BreadCrumbs />

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
            data-test="transfers-incoming"
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
            data-test="transfers-outgoing"
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
      :text="t('labels.logistics.noTransfers')"
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
  </section>
</template>
