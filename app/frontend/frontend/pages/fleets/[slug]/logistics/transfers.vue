<script lang="ts">
export default {
  name: "FleetLogisticsTransfersPage",
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
  type Fleet,
  type FleetMember,
  type InventoryTransfer,
  useFleetInventoryTransfers,
  useFleetInventories,
  useAcceptFleetInventoryTransfer,
  useDeclineFleetInventoryTransfer,
  useCancelFleetInventoryTransfer,
  useReportFleetInventoryTransfer,
} from "@/services/fyApi";

// Handed down by `logistics.vue`, which also gates the whole branch on
// `fleet_logistics` -- so this page never renders for a fleet that cannot use
// it.
type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { displayAlert } = useAppNotifications();

const fleetSlug = computed(() => props.fleet.slug);

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet", params: { slug: fleetSlug.value } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-logistics", params: { slug: fleetSlug.value } },
    label: t("nav.fleets.logistics.index"),
  },
]);

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
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Logistics/TransferAcceptModal/index.vue"),
    props: {
      transfer,
      inventories: inventories.value?.items ?? [],
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
  <BreadCrumbs :crumbs="crumbs" />

  <div class="row">
    <div class="col-12">
      <Heading size="hero" hero>
        {{ t("headlines.logistics.transfers") }}
      </Heading>
    </div>
  </div>

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
        data-test="fleet-transfers-incoming"
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
        data-test="fleet-transfers-outgoing"
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
