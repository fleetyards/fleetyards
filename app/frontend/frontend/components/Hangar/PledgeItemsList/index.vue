<script lang="ts">
export default {
  name: "HangarPledgeItemsList",
};
</script>

<script lang="ts" setup>
import RowList from "@/shared/components/RowList/index.vue";
import RowListItem from "@/shared/components/RowListItem/index.vue";
import {
  RowListItemTonesEnum,
  type RowListItemBadge,
  type RowListItemTag,
} from "@/shared/components/RowListItem/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useCurrencyFormat } from "@/shared/composables/useCurrencyFormat";
import { useImageViewer } from "@/shared/composables/useImageViewer";
import type { HangarPledgeItem } from "@/services/fyApi";

type Props = {
  items: HangarPledgeItem[];
  emptyVisible?: boolean;
  emptyName?: string;
  icon: string;
};

defineProps<Props>();

const { t, l } = useI18n();

const { formatCents } = useCurrencyFormat();

const { openImage } = useImageViewer();

const viewImage = (event: MouseEvent, name: string) => {
  const image = (event.currentTarget as HTMLElement).querySelector("img");

  if (image) {
    void openImage(image, name);
  }
};

const usd = (value: number) => formatCents(Math.round(value * 100), "USD");

const badges = (item: HangarPledgeItem): RowListItemBadge[] => {
  const result: RowListItemBadge[] = [];

  if (item.quantity > 1) {
    result.push({
      key: "quantity",
      label: t("labels.hangarPledgeItems.quantity"),
      value: `× ${item.quantity}`,
    });
  }

  if (item.meltValue !== undefined) {
    result.push({
      key: "meltValue",
      label: t("labels.hangarPledgeItems.meltValue"),
      value: usd(item.meltValue),
    });
  } else if (item.pledgeValue !== undefined) {
    result.push({
      key: "pledgeValue",
      label: t("labels.hangarPledgeItems.pledgeValue"),
      value: usd(item.pledgeValue),
      quiet: true,
    });
  }

  if (item.pledgeCreatedOn) {
    result.push({
      key: "pledgeCreatedOn",
      label: t("labels.hangarPledgeItems.createdOn"),
      value: l(item.pledgeCreatedOn, "datetime.formats.date"),
    });
  }

  return result;
};

const tags = (item: HangarPledgeItem): RowListItemTag[] =>
  item.meltable
    ? [
        {
          key: "meltable",
          label: t("labels.hangarPledgeItems.meltable"),
          tone: RowListItemTonesEnum.PRIMARY,
        },
      ]
    : [];

// Melting returns what the whole pledge is worth, so an item that came with
// others names the pledge its value belongs to.
const sub = (item: HangarPledgeItem) =>
  !item.standalone && item.pledgeName
    ? t("labels.hangarPledgeItems.partOf", { name: item.pledgeName })
    : t("labels.hangarPledgeItems.pledge", { id: item.rsiPledgeId });
</script>

<template>
  <RowList
    :records="items"
    :empty-visible="emptyVisible"
    :empty-name="emptyName"
  >
    <template #default="{ record }">
      <RowListItem
        class="pledge-item-row"
        :badges="badges(record)"
        :tags="tags(record)"
        data-test="pledge-item-row"
      >
        <template #leading>
          <button
            v-if="record.image"
            type="button"
            class="pledge-item-row__zoom"
            :aria-label="t('actions.viewImage', { name: record.name })"
            data-test="pledge-item-image"
            @click="viewImage($event, record.name)"
          >
            <img
              class="pledge-item-row__image"
              :src="record.image"
              alt=""
              loading="lazy"
            />
          </button>
          <span
            v-else
            class="pledge-item-row__image pledge-item-row__image--empty"
          >
            <i :class="icon" />
          </span>
        </template>

        <template #name>{{ record.name }}</template>

        <template #sub>
          {{ sub(record) }}
        </template>
      </RowListItem>
    </template>
  </RowList>
</template>

<style lang="scss" scoped>
// A paint is told apart by its colours and a piece of flair by its shape,
// neither of which a thumbnail is big enough to show.
.pledge-item-row__image {
  flex: 0 0 auto;
  width: 112px;
  height: 63px;
  object-fit: cover;
  border-radius: 4px;

  @media (min-width: 992px) {
    width: 192px;
    height: 108px;
  }
}

.pledge-item-row__zoom {
  flex: 0 0 auto;
  display: block;
  padding: 0;
  border: none;
  border-radius: 4px;
  background: none;
  cursor: zoom-in;

  &:focus-visible {
    outline: 2px solid var(--color-primary);
    outline-offset: 2px;
  }
}

.pledge-item-row__image--empty {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 1.5rem;
  color: var(--color-muted);
  background: var(--color-control);
}
</style>
