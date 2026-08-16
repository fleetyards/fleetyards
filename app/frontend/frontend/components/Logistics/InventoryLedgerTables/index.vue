<script lang="ts">
export default {
  name: "InventoryLedgerTables",
};
</script>

<script lang="ts" setup>
import BasePill from "@/shared/components/base/Pill/index.vue";
import BaseTable, {
  type BaseTableCol,
} from "@/shared/components/base/Table/index.vue";
import { BaseTableColAlignmentEnum } from "@/shared/components/base/Table/types";
import { useI18n } from "@/shared/composables/useI18n";
import type {
  InventoryLedgerRecord,
  InventoryStockRecord,
} from "@/frontend/types/logistics";

type Props = {
  activeTab: "stock" | "log";
  stockRecords: InventoryStockRecord[];
  logRecords: InventoryLedgerRecord[];
  stockLoading?: boolean;
  logLoading?: boolean;
  showInventory?: boolean;
  showMember?: boolean;
  showAddedBy?: boolean;
  showNotes?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  stockLoading: false,
  logLoading: false,
  showInventory: false,
  showMember: false,
  showAddedBy: false,
  showNotes: false,
});

const { t } = useI18n();

const stockColumns = computed<BaseTableCol<InventoryStockRecord>[]>(() => [
  {
    name: "name",
    label: t("labels.logistics.itemName"),
    sortable: true,
    attributeKey: "name",
  },
  ...(props.showInventory
    ? [
        {
          name: "inventory",
          label: t("labels.logistics.inventory"),
          sortable: false,
          width: "180px",
          mobile: false,
        },
      ]
    : []),
  {
    name: "category",
    label: t("labels.logistics.category"),
    sortable: true,
    attributeKey: "category",
    width: "140px",
    mobile: !props.showInventory,
  },
  {
    name: "quality",
    label: t("labels.logistics.quality"),
    sortable: true,
    attributeKey: "quality",
    width: "100px",
    alignment: BaseTableColAlignmentEnum.RIGHT,
    mobile: false,
  },
  {
    name: "netQuantity",
    label: t("labels.logistics.quantity"),
    sortable: true,
    attributeKey: "netQuantity",
    width: "140px",
    alignment: BaseTableColAlignmentEnum.RIGHT,
  },
]);

const logColumns = computed<BaseTableCol<InventoryLedgerRecord>[]>(() => [
  {
    name: "entryType",
    label: t("labels.logistics.entryType"),
    sortable: true,
    attributeKey: "entryType",
    width: "100px",
  },
  {
    name: "name",
    label: t("labels.logistics.itemName"),
    sortable: true,
    attributeKey: "name",
  },
  ...(props.showInventory
    ? [
        {
          name: "inventory",
          label: t("labels.logistics.inventory"),
          sortable: false,
          width: "160px",
          mobile: false,
        },
      ]
    : []),
  {
    name: "category",
    label: t("labels.logistics.category"),
    sortable: true,
    attributeKey: "category",
    width: "120px",
    mobile: false,
  },
  {
    name: "quality",
    label: t("labels.logistics.quality"),
    sortable: true,
    attributeKey: "quality",
    width: "100px",
    alignment: BaseTableColAlignmentEnum.RIGHT,
    mobile: false,
  },
  {
    name: "quantity",
    label: t("labels.logistics.quantity"),
    sortable: true,
    attributeKey: "quantity",
    width: "120px",
    alignment: BaseTableColAlignmentEnum.RIGHT,
  },
  ...(props.showMember
    ? [
        {
          name: "member",
          label: t("labels.logistics.member"),
          sortable: false,
          width: "120px",
          mobile: false,
        },
      ]
    : []),
  ...(props.showAddedBy
    ? [
        {
          name: "addedBy",
          label: t("labels.logistics.addedBy"),
          sortable: false,
          width: "120px",
          mobile: false,
        },
      ]
    : []),
  ...(props.showNotes
    ? [
        {
          name: "notes",
          label: t("labels.logistics.notes"),
          sortable: false,
          mobile: false,
        },
      ]
    : []),
]);
</script>

<template>
  <BaseTable
    v-if="activeTab === 'stock'"
    :records="stockRecords"
    :columns="stockColumns"
    primary-key="id"
    :loading="stockLoading"
    :empty-visible="!stockLoading && !stockRecords.length"
  >
    <template #col-name="{ record }">
      <slot name="stock-name" :record="record">{{ record.name }}</slot>
    </template>
    <template #col-inventory="{ record }">
      <span class="text-muted">{{ record.inventory?.name }}</span>
    </template>
    <template #col-category="{ record }">
      {{ t(`labels.logistics.categories.${record.category}`) }}
    </template>
    <template #col-quality="{ record }">
      <template v-if="record.qualityMin != null">
        <template v-if="record.qualityMin === record.qualityMax">
          {{ record.qualityMin }}
        </template>
        <template v-else>
          {{ record.qualityMin }} - {{ record.qualityMax }}
        </template>
      </template>
      <template v-else-if="record.quality != null">
        {{ record.quality }}
      </template>
    </template>
    <template #col-netQuantity="{ record }">
      {{ record.netQuantity }}
      {{ t(`labels.logistics.units.${record.unit}`) }}
    </template>
  </BaseTable>

  <BaseTable
    v-if="activeTab === 'log'"
    :records="logRecords"
    :columns="logColumns"
    primary-key="id"
    :loading="logLoading"
    :empty-visible="!logLoading && !logRecords.length"
  >
    <template #col-entryType="{ record }">
      <span
        :class="record.entryType === 'deposit' ? 'text-success' : 'text-danger'"
      >
        {{ t(`labels.logistics.entryTypes.${record.entryType}`) }}
      </span>
    </template>
    <template #col-name="{ record }">
      <slot name="log-name" :record="record">{{ record.name }}</slot>
      <BasePill
        v-if="record.item && record.item.available === false"
        variant="warning"
        :title="t('labels.logistics.itemUnavailableHint')"
      >
        {{ t("labels.logistics.itemUnavailable") }}
      </BasePill>
    </template>
    <template #col-inventory="{ record }">
      <span class="text-muted">{{ record.inventory?.name }}</span>
    </template>
    <template #col-category="{ record }">
      {{ t(`labels.logistics.categories.${record.category}`) }}
    </template>
    <template #col-quantity="{ record }">
      {{ record.quantity }}
      {{ t(`labels.logistics.units.${record.unit}`) }}
    </template>
    <template #col-member="{ record }">
      <slot name="member" :record="record" />
    </template>
    <template #col-addedBy="{ record }">
      <slot name="addedBy" :record="record" />
    </template>
    <template #col-notes="{ record }">
      <span class="text-muted">{{ record.notes }}</span>
    </template>
    <template v-if="$slots['log-actions']" #actions="{ record }">
      <slot name="log-actions" :record="record" />
    </template>
  </BaseTable>
</template>
