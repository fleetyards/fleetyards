<script lang="ts">
export default {
  name: "LogisticsTransferTable",
};
</script>

<script lang="ts" setup>
import BaseTable from "@/shared/components/base/Table/index.vue";
import type { BaseTableCol } from "@/shared/components/base/Table/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useI18n } from "@/shared/composables/useI18n";
import type { InventoryTransfer } from "@/services/fyApi";

type Props = {
  transfers: InventoryTransfer[];
  // Which side the viewer is on, which decides what they can do about it.
  direction: "incoming" | "outgoing";
  loading?: boolean;
  busy?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  busy: false,
});

const emit = defineEmits<{
  accept: [InventoryTransfer];
  decline: [InventoryTransfer];
  cancel: [InventoryTransfer];
  report: [InventoryTransfer];
}>();

const { t, l } = useI18n();

// Waiting is the only state that asks anything of the reader; the rest are
// history, which is what the neutral variant is for.
const STATE_VARIANTS: Record<string, `${PillVariantsEnum}`> = {
  pending: PillVariantsEnum.WARNING,
  completed: PillVariantsEnum.SUCCESS,
  declined: PillVariantsEnum.DANGER,
  cancelled: PillVariantsEnum.NEUTRAL,
  expired: PillVariantsEnum.NEUTRAL,
};

const columns = computed<BaseTableCol<InventoryTransfer>[]>(() => [
  {
    name: "from",
    label: t("labels.logistics.sender"),
    minWidth: "150px",
  },
  {
    name: "to",
    label: t("labels.logistics.recipient"),
    minWidth: "150px",
  },
  {
    name: "contents",
    label: t("labels.logistics.contents"),
    flexGrow: 2,
  },
  {
    name: "state",
    label: t("labels.logistics.state"),
    width: "130px",
  },
  {
    // Wide enough for a formatted date on one line; the raw ISO string it used
    // to print wrapped in half the space this needs.
    name: "createdAt",
    label: t("labels.logistics.sentAt"),
    width: "170px",
    mobile: false,
    sortable: true,
    attributeKey: "createdAt",
  },
]);

// Both halves: whose it is, and which of their inventories. The inventory name
// alone says "Caterpillar" without saying whose, and two people's inventories
// can share a name.
const from = (transfer: InventoryTransfer) => ({
  party: transfer.sender?.name,
  inventory: transfer.source?.name,
});

// A pending transfer has no destination yet -- the recipient picks one when
// they accept -- so it names the party alone until then.
const to = (transfer: InventoryTransfer) => ({
  party: transfer.recipient?.name ?? transfer.destination?.name,
  inventory: transfer.recipient ? undefined : transfer.destination?.name,
});

// Only a transfer still waiting can be answered, and only the side that did not
// send it answers. The API decides this too -- this is what to render, not what
// is permitted.
const canAnswer = (transfer: InventoryTransfer) =>
  transfer.state === "pending" && props.direction === "incoming";

const canCancel = (transfer: InventoryTransfer) =>
  transfer.state === "pending" && props.direction === "outgoing";
</script>

<template>
  <BaseTable
    :records="transfers"
    :columns="columns"
    primary-key="id"
    :loading="loading"
    :empty-visible="!loading && !transfers.length"
  >
    <template #col-from="{ record }">
      <span class="transfer-party">
        {{ from(record as InventoryTransfer).party }}
      </span>
      <span
        v-if="from(record as InventoryTransfer).inventory"
        class="transfer-place"
      >
        {{ from(record as InventoryTransfer).inventory }}
      </span>
    </template>

    <template #col-to="{ record }">
      <span class="transfer-party">
        {{ to(record as InventoryTransfer).party }}
      </span>
      <span
        v-if="to(record as InventoryTransfer).inventory"
        class="transfer-place"
      >
        {{ to(record as InventoryTransfer).inventory }}
      </span>
    </template>

    <template #col-contents="{ record }">
      <ul class="transfer-contents">
        <li v-for="line in (record as InventoryTransfer).lines" :key="line.id">
          <span class="transfer-contents-name">{{ line.name }}</span>
          <span class="transfer-contents-amount">
            {{ line.quantity }}
            {{ t(`labels.logistics.units.${line.unit}`) }}
          </span>
        </li>
      </ul>
    </template>

    <template #col-state="{ record }">
      <Pill
        uppercase
        :variant="
          STATE_VARIANTS[(record as InventoryTransfer).state] ??
          PillVariantsEnum.NEUTRAL
        "
        :data-test="`transfer-state-${(record as InventoryTransfer).state}`"
      >
        {{
          t(
            `labels.logistics.transferStates.${(record as InventoryTransfer).state}`,
          )
        }}
      </Pill>
    </template>

    <template #col-createdAt="{ record }">
      <span
        v-if="(record as InventoryTransfer).createdAt"
        class="transfer-date"
      >
        {{
          l((record as InventoryTransfer).createdAt!, "datetime.formats.short")
        }}
      </span>
    </template>

    <template #actions="{ record }">
      <BtnGroup
        v-if="
          canAnswer(record as InventoryTransfer) ||
          canCancel(record as InventoryTransfer)
        "
      >
        <Btn
          v-if="canAnswer(record as InventoryTransfer)"
          :size="BtnSizesEnum.SM"
          :disabled="busy"
          :data-test="`transfer-accept-${(record as InventoryTransfer).id}`"
          @click="emit('accept', record as InventoryTransfer)"
        >
          {{ t("actions.logistics.acceptTransfer") }}
        </Btn>
        <Btn
          v-if="canAnswer(record as InventoryTransfer)"
          :size="BtnSizesEnum.SM"
          :tone="BtnTonesEnum.DANGER"
          :disabled="busy"
          :data-test="`transfer-decline-${(record as InventoryTransfer).id}`"
          @click="emit('decline', record as InventoryTransfer)"
        >
          {{ t("actions.logistics.declineTransfer") }}
        </Btn>
        <Btn
          v-if="canAnswer(record as InventoryTransfer)"
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.BARE"
          :aria-label="t('actions.logistics.reportTransfer')"
          :title="t('actions.logistics.reportTransfer')"
          :disabled="busy"
          :data-test="`transfer-report-${(record as InventoryTransfer).id}`"
          @click="emit('report', record as InventoryTransfer)"
        >
          <i class="fa-duotone fa-flag" />
        </Btn>
        <Btn
          v-if="canCancel(record as InventoryTransfer)"
          :size="BtnSizesEnum.SM"
          :tone="BtnTonesEnum.DANGER"
          :disabled="busy"
          :data-test="`transfer-cancel-${(record as InventoryTransfer).id}`"
          @click="emit('cancel', record as InventoryTransfer)"
        >
          {{ t("actions.logistics.cancelTransfer") }}
        </Btn>
      </BtnGroup>
    </template>
  </BaseTable>
</template>

<style lang="scss" scoped>
.transfer-contents {
  padding: 0;
  margin: 0;
  list-style: none;

  li {
    display: flex;
    gap: 1rem;
    justify-content: space-between;
    padding: 0.1rem 0;
  }
}

.transfer-party {
  display: block;
}

.transfer-place {
  display: block;
  font-size: 0.85em;
  opacity: 0.7;
}

.transfer-date {
  white-space: nowrap;
}

.transfer-contents-amount {
  white-space: nowrap;
  opacity: 0.7;
}
</style>
