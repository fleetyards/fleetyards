<script lang="ts">
export default {
  name: "HangarBuybacksList",
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
import { type BuybackPledge } from "@/services/fyApi";

type Props = {
  buybacks: BuybackPledge[];
  emptyVisible?: boolean;
};

defineProps<Props>();

const { t, l } = useI18n();

const route = useRoute();

const filterLink = (key: string, value: string) => ({
  name: route.name as string,
  query: { ...route.query, page: undefined, [key]: value },
});

const tags = (buyback: BuybackPledge): RowListItemTag[] => [
  {
    key: buyback.kind,
    label: t(`labels.buybacks.kinds.${buyback.kind}`),
    tone: RowListItemTonesEnum.PRIMARY,
    to: filterLink("kindEq", buyback.kind),
  },
  ...(buyback.upgraded
    ? [{ key: "upgraded", label: t("labels.buybacks.upgraded") }]
    : []),
];

const badges = (buyback: BuybackPledge): RowListItemBadge[] =>
  buyback.reclaimedOn
    ? [
        {
          key: "reclaimedOn",
          label: t("labels.buybacks.reclaimedOn"),
          value: l(buyback.reclaimedOn, "datetime.formats.date"),
        },
      ]
    : [];
</script>

<template>
  <RowList
    :records="buybacks"
    :empty-visible="emptyVisible"
    :empty-name="t('labels.buybacks.name')"
  >
    <template #default="{ record }">
      <RowListItem
        class="buyback-row"
        :tags="tags(record)"
        :badges="badges(record)"
        data-test="buyback-row"
      >
        <template #leading>
          <img
            v-if="record.image"
            class="buyback-row__image"
            :src="record.image"
            alt=""
            loading="lazy"
          />
          <span v-else class="buyback-row__image buyback-row__image--empty">
            <i class="fa-duotone fa-rotate-left" />
          </span>
        </template>

        <template #name>{{ record.name }}</template>

        <template v-if="record.contained" #sub>
          {{ record.contained }}
        </template>
      </RowListItem>
    </template>
  </RowList>
</template>

<style lang="scss" scoped>
.buyback-row__image {
  flex: 0 0 auto;
  width: 64px;
  height: 36px;
  object-fit: cover;
  border-radius: 4px;
}

.buyback-row__image--empty {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: var(--color-muted);
  background: var(--color-control);
}
</style>
