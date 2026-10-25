<script lang="ts">
export default {
  name: "InventoryLedgerTables",
};
</script>

<script lang="ts" setup>
import CatalogueItemPopover from "@/frontend/components/CatalogueItemPopover/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import BaseTable, {
  type BaseTableCol,
} from "@/shared/components/base/Table/index.vue";
import { BaseTableColAlignmentEnum } from "@/shared/components/base/Table/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import { catalogueItemRoute } from "@/frontend/utils/catalogueItemRoute";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { type InventoryCraftedRef } from "@/services/fyApi";
import { craftedGrades } from "@/frontend/components/Logistics/crafted";
import { lotKey } from "@/frontend/composables/useStockLots";
import type {
  InventoryLedgerRecord,
  InventoryRowImage,
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
  // Off where every row is the one item the page already pictures.
  showImage?: boolean;
  // Ticking stock rows, for an action that works on several positions at once.
  stockSelectable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  stockLoading: false,
  logLoading: false,
  showInventory: false,
  showMember: false,
  showAddedBy: false,
  showNotes: false,
  showImage: true,
  stockSelectable: false,
});

const { t, l } = useI18n();

const mobile = useMobile();

// The recipe and the grade in each slot, in slot order.
const craftedSummary = (crafted: InventoryCraftedRef) =>
  [
    crafted.blueprint.name,
    ...craftedGrades(crafted.qualities, (position, grade) =>
      t("labels.logistics.crafted.slotGrade", { position, quality: grade }),
    ),
  ].join(" · ");

const imageColumns = computed(() =>
  props.showImage
    ? [
        {
          name: "image",
          label: "",
          width: "80px",
          alignment: BaseTableColAlignmentEnum.CENTER,
          mobile: false,
        },
      ]
    : [],
);

const rowImage = (image?: InventoryRowImage) => image?.smallUrl || image?.url;

const stockColumns = computed<BaseTableCol<InventoryStockRecord>[]>(() => [
  ...imageColumns.value,
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
  ...imageColumns.value,
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
  {
    // A deposit somebody typed and one that arrived from another inventory are
    // the same row otherwise -- and "it came from a transfer" is not the
    // question the ledger is being asked. Which one is.
    name: "origin",
    label: t("labels.logistics.origin"),
    sortable: false,
    width: "200px",
    mobile: false,
  },
  {
    // A ledger without times is a list of things that happened in no
    // particular order.
    name: "createdAt",
    label: t("labels.logistics.recordedAt"),
    sortable: true,
    attributeKey: "createdAt",
    width: "170px",
    mobile: false,
  },
]);
</script>

<template>
  <!-- On a desktop the name opens the catalogue card on hover. A phone opens
       it with a tap, which the name's own link would take for itself, so
       there the card hangs off an icon beside the name instead. -->
  <BaseTable
    v-if="activeTab === 'stock'"
    :records="stockRecords"
    :columns="stockColumns"
    primary-key="id"
    :row-key="lotKey"
    :loading="stockLoading"
    :selectable="stockSelectable"
    :empty-visible="!stockLoading && !stockRecords.length"
  >
    <template
      v-if="$slots['stock-selected-actions']"
      #selected-actions="{ selected }"
    >
      <slot name="stock-selected-actions" :selected="selected" />
    </template>

    <template #col-image="{ record }">
      <img
        v-if="rowImage(record.image)"
        :src="rowImage(record.image)"
        alt=""
        class="ledger-image"
        loading="lazy"
      />
    </template>
    <!-- The name opens the stock position, and hovering it shows the catalogue
         record the position holds -- with what it was crafted to, for a
         crafted lot. -->
    <template #col-name="{ record }">
      <CatalogueItemPopover
        v-if="!mobile && catalogueItemRoute(record.item)"
        :item="record.item ?? {}"
        :crafted="record.crafted"
        :link="false"
      >
        <slot name="stock-name" :record="record">{{ record.name }}</slot>
      </CatalogueItemPopover>
      <template v-else>
        <slot name="stock-name" :record="record">{{ record.name }}</slot>
        <span
          v-if="catalogueItemRoute(record.item)"
          class="ledger-catalogue-link"
        >
          <CatalogueItemPopover
            :item="record.item ?? {}"
            :crafted="record.crafted"
            :link-label="t('labels.logistics.openInCatalogue')"
          >
            <i class="fa-light fa-book-open" />
          </CatalogueItemPopover>
        </span>
      </template>
    </template>
    <template #col-inventory="{ record }">
      <span class="text-muted">{{ record.inventory?.name }}</span>
    </template>
    <template #col-category="{ record }">
      {{ t(`labels.logistics.categories.${record.category}`) }}
    </template>
    <template #col-quality="{ record }">
      <span
        v-if="record.crafted"
        v-tooltip="craftedSummary(record.crafted)"
        class="ledger-crafted"
      >
        {{ t("labels.logistics.crafted.lot") }}
      </span>
      <template v-else-if="record.qualityMin != null">
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
    <template v-if="$slots['stock-actions']" #actions="{ record }">
      <slot name="stock-actions" :record="record" />
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

    <template #col-origin="{ record }">
      <!-- One element: the cell is a flex row with `space-between`. -->
      <span v-if="record.transfer" class="ledger-origin">
        <i
          class="fa-duotone ledger-origin-mark"
          :class="
            record.transfer.direction === 'in'
              ? 'fa-arrow-right-to-bracket'
              : 'fa-arrow-right-from-bracket'
          "
        />
        <span :data-test="`ledger-origin-${record.id}`">
          {{ record.transfer.counterparty?.name }}
          <span v-if="record.transfer.inventory" class="ledger-origin-place">
            {{ record.transfer.inventory.name }}
          </span>
        </span>
      </span>
    </template>

    <template #col-createdAt="{ record }">
      <span v-if="record.createdAt" class="ledger-date">
        {{ l(record.createdAt, "datetime.formats.short") }}
      </span>
    </template>
    <template #col-image="{ record }">
      <img
        v-if="rowImage(record.image)"
        :src="rowImage(record.image)"
        alt=""
        class="ledger-image"
        loading="lazy"
      />
    </template>
    <template #col-name="{ record }">
      <CatalogueItemPopover
        v-if="!mobile && catalogueItemRoute(record.item)"
        :item="record.item ?? {}"
        :crafted="record.crafted"
        :link="false"
      >
        <slot name="log-name" :record="record">{{ record.name }}</slot>
      </CatalogueItemPopover>
      <template v-else>
        <slot name="log-name" :record="record">{{ record.name }}</slot>
        <span
          v-if="catalogueItemRoute(record.item)"
          class="ledger-catalogue-link"
        >
          <CatalogueItemPopover
            :item="record.item ?? {}"
            :crafted="record.crafted"
            :link-label="t('labels.logistics.openInCatalogue')"
          >
            <i class="fa-light fa-book-open" />
          </CatalogueItemPopover>
        </span>
      </template>
      <BasePill
        v-if="record.item && record.item.available === false"
        :variant="PillVariantsEnum.WARNING"
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
    <!-- A crafted part has no single grade; what it was made from is the
         recipe and a grade per slot, which the tooltip spells out. -->
    <template #col-quality="{ record }">
      <span
        v-if="record.crafted"
        v-tooltip="craftedSummary(record.crafted)"
        class="ledger-crafted"
        :data-test="`ledger-crafted-${record.id}`"
      >
        {{ t("labels.logistics.crafted.lot") }}
      </span>
      <template v-else-if="record.quality != null">
        {{ record.quality }}
      </template>
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

<style lang="scss" scoped>
.ledger-image {
  display: block;
  width: 64px;
  height: 36px;
  object-fit: contain;
}

.ledger-origin {
  display: inline-flex;
  gap: 0.4rem;
  align-items: baseline;
}

.ledger-origin-mark {
  opacity: 0.6;
}

.ledger-origin-place {
  font-size: 0.85em;
  opacity: 0.7;

  &::before {
    padding-right: 0.3rem;
    content: "·";
  }
}

.ledger-date {
  white-space: nowrap;
}

.ledger-catalogue-link {
  margin-left: 0.4rem;
  color: var(--color-muted);

  // The link is rendered by the catalogue popover, outside this scope.
  :deep(a) {
    color: inherit;
  }

  &:hover,
  &:focus-within {
    color: var(--color-text);
  }
}
</style>
