<script lang="ts">
export default {
  name: "HangarBuybacksList",
};
</script>

<script lang="ts" setup>
import RowList from "@/shared/components/RowList/index.vue";
import RowListItem from "@/shared/components/RowListItem/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import {
  RowListItemTonesEnum,
  type RowListItemBadge,
  type RowListItemTag,
} from "@/shared/components/RowListItem/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useCurrencyFormat } from "@/shared/composables/useCurrencyFormat";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";
import { errorTypeFrom } from "@/shared/utils/ErrorTypes";
import { ErrorTypesEnum } from "@/shared/components/AsyncData.types";
import {
  BuybackPledgeKindEnum,
  getHangarBuybacksQueryKey,
  useDestroyHangarBuyback,
  type BuybackPledge,
} from "@/services/fyApi";

type Props = {
  buybacks: BuybackPledge[];
  emptyVisible?: boolean;
};

const props = defineProps<Props>();

const { t, l } = useI18n();

const { formatCents } = useCurrencyFormat();

const route = useRoute();

const router = useRouter();

const filterLink = (key: string, value: string) => ({
  name: route.name as string,
  query: { ...route.query, page: undefined, [key]: value },
});

// An upgrade's buy-back is a modal on RSI's list page, with no address of its
// own, so it links to the list.
const rsiUrl = (buyback: BuybackPledge) =>
  buyback.kind === BuybackPledgeKindEnum.UPGRADE
    ? `${window.RSI_ENDPOINT}/account/buy-back-pledges`
    : `${window.RSI_ENDPOINT}/pledge/buyback/${buyback.rsiPledgeId}`;

const insurance = (buyback: BuybackPledge) => {
  if (buyback.lifetimeInsurance) {
    return t("labels.buybacks.lifetimeInsurance");
  }

  return buyback.insuranceMonths
    ? t("labels.buybacks.insuranceMonths", { count: buyback.insuranceMonths })
    : undefined;
};

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
  ...(buyback.available
    ? []
    : [
        {
          key: "notAvailable",
          label: t("labels.buybacks.notAvailable"),
          tone: RowListItemTonesEnum.DANGER,
        },
      ]),
];

const queryClient = useQueryClient();

const { displayAlert, displayConfirm } = useAppNotifications();

const removingId = ref<string>();

const destroyMutation = useDestroyHangarBuyback();

const remove = (buyback: BuybackPledge) => {
  displayConfirm({
    text: t("messages.confirm.buyback.destroy"),
    confirmText: t("actions.remove"),
    onConfirm: async () => {
      removingId.value = buyback.id;

      try {
        await destroyMutation.mutateAsync({ id: buyback.id });
      } catch (error) {
        // Already gone - a sync or another tab removed it - so the row is
        // stale rather than the removal failed.
        if (errorTypeFrom(error) !== ErrorTypesEnum.NOT_FOUND) {
          displayAlert({ text: t("messages.buyback.destroy.failure") });
          return;
        }
      } finally {
        removingId.value = undefined;
      }

      const page = Number(route.query.page) || 1;

      if (props.buybacks.length === 1 && page > 1) {
        await router.replace({
          query: { ...route.query, page: page > 2 ? page - 1 : undefined },
        });
      }

      await queryClient.invalidateQueries({
        queryKey: getHangarBuybacksQueryKey(),
      });
    },
  });
};

const badges = (buyback: BuybackPledge): RowListItemBadge[] => {
  const result: RowListItemBadge[] = [];
  const insuranceLabel = insurance(buyback);

  if (insuranceLabel) {
    result.push({
      key: "insurance",
      label: t("labels.buybacks.insurance"),
      value: insuranceLabel,
    });
  }

  if (buyback.price !== undefined) {
    result.push({
      key: "price",
      label: t("labels.buybacks.price"),
      value: formatCents(Math.round(buyback.price * 100), "USD"),
    });
  }

  if (buyback.reclaimedOn) {
    result.push({
      key: "reclaimedOn",
      label: t("labels.buybacks.reclaimedOn"),
      value: l(buyback.reclaimedOn, "datetime.formats.date"),
    });
  }

  return result;
};
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

        <template #actions>
          <Btn
            v-if="record.available"
            :href="rsiUrl(record)"
            :variant="BtnVariantsEnum.GHOST"
            :aria-label="t('labels.buybacks.openOnRsi')"
            mobile-icon-only
            data-test="buyback-rsi-link"
          >
            <i class="fa-light fa-arrow-up-right-from-square" />
            <span>{{ t("labels.buybacks.openOnRsi") }}</span>
          </Btn>
          <Btn
            :variant="BtnVariantsEnum.GHOST"
            :aria-label="t('labels.buybacks.remove')"
            :loading="removingId === record.id"
            mobile-icon-only
            data-test="buyback-remove"
            @click="remove(record)"
          >
            <i class="fa-light fa-trash" />
            <span>{{ t("labels.buybacks.remove") }}</span>
          </Btn>
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
