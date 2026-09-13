<script lang="ts">
export default {
  name: "HangarTransfersPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import TransferTable from "@/frontend/components/Logistics/TransferTable/index.vue";
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

const crumbs = computed<Crumb[]>(() => [
  { to: { name: "hangar" }, label: t("nav.hangar.index") },
  { to: { name: "hangar-inventories" }, label: t("nav.hangar.inventories") },
]);

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
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Logistics/TransferAcceptModal/index.vue"),
    props: {
      transfer,
      inventories: inventories.value?.items ?? [],
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
  <BreadCrumbs :crumbs="crumbs" />

  <Heading size="hero" hero>
    {{ t("headlines.logistics.transfers") }}
  </Heading>

  <!-- `Heading` takes only `default` and `subHeading`, so controls belong in
       the page header the way every other list does it. -->
  <Teleport to="#header-right">
    <BtnGroup>
      <Btn
        :size="BtnSizesEnum.MD"
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
        :size="BtnSizesEnum.MD"
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
