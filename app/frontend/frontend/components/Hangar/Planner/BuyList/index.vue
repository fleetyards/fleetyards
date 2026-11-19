<script lang="ts">
export default {
  name: "HangarPlannerBuyList",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import ShipName from "@/frontend/components/Hangar/Planner/ShipName/index.vue";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import {
  RSI_CART_URL,
  useRsiCart,
  type RsiCartEntry,
} from "@/frontend/composables/useRsiCart";
import type { FleetyardsSyncCartResult } from "@/frontend/lib/FleetyardsSyncHandler";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type HangarPlanCartItem,
  type HangarPlanPurchase,
  HangarPlanPurchaseKindEnum,
  type HangarPlanSlot,
} from "@/services/fyApi";

type Props = {
  purchases?: HangarPlanPurchase[];
  slots: HangarPlanSlot[];
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  purchases: undefined,
  loading: false,
});

const { t } = useI18n();
const { money, amount } = usePlanMoney();
const { displayAlert } = useAppNotifications();
const cart = useRsiCart();

const slotLabels = computed(
  () => new Map(props.slots.map((slot) => [slot.id, slot.label])),
);

const labelsOf = (purchase: HangarPlanPurchase) =>
  purchase.slotIds
    .map((id) => slotLabels.value.get(id))
    .filter(Boolean)
    .join(", ");

// Ships earned in game are paid in aUEC, which no store price covers.
const priced = (kind: HangarPlanPurchaseKindEnum) =>
  kind !== HangarPlanPurchaseKindEnum.INGAME;

// A buy-back is only ever bought alone: adding one empties the RSI cart, and
// RSI refuses anything next to it.
const alone = (kind: HangarPlanPurchaseKindEnum) =>
  kind === HangarPlanPurchaseKindEnum.BUYBACK;

// Named by what it adds rather than by its place in the list, so a summary
// fetched again after an edit keeps what is already in the cart marked.
const entryKey = (item: HangarPlanCartItem, unit: number) =>
  [
    item.kind,
    item.skuId,
    item.fromShipId,
    item.toShipId,
    item.toSkuId,
    item.pledgeId,
  ]
    .filter((part) => part !== undefined && part !== null)
    .join("-") + `:${unit}`;

const entriesOf = (purchase: HangarPlanPurchase): RsiCartEntry[] =>
  purchase.cartItems.map((item, unit) => ({ key: entryKey(item, unit), item }));

const results = ref<Record<string, FleetyardsSyncCartResult>>({});
const busy = ref<string>();
const added = ref(false);

// What is already in the cart is never sent again: RSI would add a second one.
const pendingOf = (entries: RsiCartEntry[]) =>
  entries.filter(({ key }) => !results.value[key]?.ok);

const addToCart = async (
  allEntries: RsiCartEntry[],
  busyKey: string,
  kind: HangarPlanPurchaseKindEnum,
) => {
  const entries = pendingOf(allEntries);
  if (!entries.length) return;

  busy.value = busyKey;
  const answer = await cart.add(entries);
  busy.value = undefined;

  if (!answer.ok) {
    displayAlert({
      text: t(
        answer.noSession
          ? "hangarPlanner.buyList.cart.noSession"
          : "hangarPlanner.buyList.cart.failure",
      ),
    });
    return;
  }

  const anyAdded = answer.results.some((result) => result.ok);
  // What the cart held before a buy-back is gone from it.
  if (alone(kind) && anyAdded) results.value = {};

  answer.results.forEach((result) => {
    results.value[result.id] = result;
  });
  added.value ||= anyAdded;
};

type RowStatus = { ok: boolean; text: string; detail?: string };

const statusOf = (entries: RsiCartEntry[]): RowStatus | undefined => {
  const rowResults = entries.flatMap(({ key }) => results.value[key] ?? []);
  if (!rowResults.length) return undefined;

  const failure = rowResults.find((result) => !result.ok);
  if (!failure) {
    return { ok: true, text: t("hangarPlanner.buyList.cart.added") };
  }

  return {
    ok: false,
    text: t(`hangarPlanner.buyList.cart.errors.${failure.error ?? "failed"}`),
    detail: failure.message,
  };
};

const groups = computed(() =>
  Object.values(HangarPlanPurchaseKindEnum)
    .map((kind) => {
      const purchases = (props.purchases ?? []).filter(
        (purchase) => purchase.kind === kind,
      );
      const prices = purchases.map((purchase) => purchase.price);
      const rows = purchases.map((purchase, index) => ({
        purchase,
        key: `${kind}:${index}`,
        entries: entriesOf(purchase),
      }));

      return {
        kind,
        rows,
        entries: rows.flatMap((row) => row.entries),
        subtotal: prices.some((price) => price === null || price === undefined)
          ? undefined
          : prices.reduce<number>((sum, price) => sum + (price ?? 0), 0),
      };
    })
    .filter((group) => group.rows.length),
);

const statuses = computed(
  () =>
    new Map(
      groups.value.flatMap((group) =>
        group.rows.map((row) => [row.key, statusOf(row.entries)] as const),
      ),
    ),
);
</script>

<template>
  <Panel
    :variant="PanelVariantsEnum.SLIM"
    :loading="loading"
    data-test="hangar-plan-buy-list"
  >
    <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
      {{ t("hangarPlanner.buyList.title") }}
    </PanelHeading>
    <PanelBody>
      <p v-if="purchases && !groups.length" class="buy-list-muted">
        {{ t("hangarPlanner.buyList.empty") }}
      </p>

      <section
        v-for="group in groups"
        :key="group.kind"
        class="buy-list-group"
        :data-test="`hangar-plan-buy-list-${group.kind}`"
      >
        <h3 class="buy-list-group-title">
          <span>{{ t(`hangarPlanner.buyList.kinds.${group.kind}`) }}</span>
          <span
            v-if="priced(group.kind) && group.subtotal !== undefined"
            class="buy-list-muted"
          >
            {{ amount(group.subtotal) }}
          </span>
        </h3>
        <template v-if="cart.available.value && group.entries.length">
          <p
            v-if="alone(group.kind)"
            class="buy-list-muted buy-list-note"
            data-test="hangar-plan-buy-list-buyback-alone"
          >
            {{ t("hangarPlanner.buyList.cart.buybackAlone") }}
          </p>
          <Btn
            v-else-if="pendingOf(group.entries).length"
            :size="BtnSizesEnum.XS"
            :variant="BtnVariantsEnum.GHOST"
            :loading="busy === group.kind"
            :disabled="!!busy"
            class="buy-list-add-all"
            :data-test="`hangar-plan-buy-list-add-all-${group.kind}`"
            @click="addToCart(group.entries, group.kind, group.kind)"
          >
            <i class="fa-light fa-cart-plus" />
            {{ t("hangarPlanner.buyList.cart.addAll") }}
          </Btn>
        </template>
        <ul class="buy-list-entries">
          <li v-for="row in group.rows" :key="row.key" class="buy-list-entry">
            <div class="buy-list-row">
              <span class="buy-list-name">
                <template v-if="row.purchase.model">
                  <template v-if="row.purchase.fromModel">
                    <ShipName :ship="row.purchase.fromModel" />
                    <i class="fa-light fa-arrow-right" aria-hidden="true" />
                  </template>
                  <ShipName :ship="row.purchase.model" />
                </template>
                <span v-else>{{ row.purchase.name }}</span>
                <span v-if="row.purchase.quantity > 1" class="buy-list-muted">
                  ×{{ row.purchase.quantity }}
                </span>
              </span>
              <span v-if="priced(row.purchase.kind)" class="buy-list-price">
                {{ money(row.purchase.price) }}
              </span>
            </div>
            <small class="buy-list-muted">{{ labelsOf(row.purchase) }}</small>
            <small v-if="row.purchase.notOnSale" class="buy-list-warning">
              {{ t("hangarPlanner.buyList.notOnSale") }}
            </small>
            <small v-if="row.purchase.tokenCount" class="buy-list-muted">
              {{
                t("hangarPlanner.buyList.usesToken", {
                  count: row.purchase.tokenCount,
                })
              }}
            </small>
            <div
              v-if="cart.available.value && row.entries.length"
              class="buy-list-cart"
            >
              <template v-if="alone(group.kind)">
                <template v-for="(entry, unit) in row.entries" :key="entry.key">
                  <Btn
                    v-if="!results[entry.key]?.ok"
                    :size="BtnSizesEnum.XS"
                    :variant="BtnVariantsEnum.BARE"
                    :loading="busy === entry.key"
                    :disabled="!!busy"
                    :data-test="`hangar-plan-buy-list-add-${row.key}-${unit}`"
                    @click="addToCart([entry], entry.key, group.kind)"
                  >
                    <i class="fa-light fa-cart-plus" />
                    {{
                      row.entries.length > 1
                        ? t("hangarPlanner.buyList.cart.addUnit", {
                            number: unit + 1,
                          })
                        : t("hangarPlanner.buyList.cart.add")
                    }}
                  </Btn>
                </template>
              </template>
              <Btn
                v-else-if="pendingOf(row.entries).length"
                :size="BtnSizesEnum.XS"
                :variant="BtnVariantsEnum.BARE"
                :loading="busy === row.key"
                :disabled="!!busy"
                :data-test="`hangar-plan-buy-list-add-${row.key}`"
                @click="addToCart(row.entries, row.key, group.kind)"
              >
                <i class="fa-light fa-cart-plus" />
                {{ t("hangarPlanner.buyList.cart.add") }}
              </Btn>
              <small
                v-if="statuses.get(row.key)"
                :class="
                  statuses.get(row.key)?.ok
                    ? 'buy-list-success'
                    : 'buy-list-warning'
                "
                :title="statuses.get(row.key)?.detail"
                :data-test="`hangar-plan-buy-list-status-${row.key}`"
              >
                {{ statuses.get(row.key)?.text }}
              </small>
            </div>
          </li>
        </ul>
      </section>

      <a
        v-if="added"
        :href="RSI_CART_URL"
        target="_blank"
        rel="noopener"
        class="buy-list-cart-link"
        data-test="hangar-plan-buy-list-open-cart"
      >
        {{ t("hangarPlanner.buyList.cart.open") }}
        <i class="fa-light fa-arrow-up-right-from-square" aria-hidden="true" />
      </a>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.buy-list-muted {
  color: var(--color-text-dim);
}

.buy-list-warning {
  color: var(--color-warning);
}

.buy-list-success {
  color: var(--color-success);
}

.buy-list-note {
  margin: 0 0 4px;
  font-size: 0.8rem;
}

.buy-list-add-all {
  margin-bottom: 4px;
}

.buy-list-cart {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 8px;
  align-items: center;
}

.buy-list-cart-link {
  display: inline-flex;
  gap: 4px;
  align-items: center;
  margin-top: 12px;
}

.buy-list-group + .buy-list-group {
  margin-top: 12px;
}

.buy-list-group-title {
  display: flex;
  justify-content: space-between;
  margin: 0 0 4px;
  font-size: 0.9rem;
  font-weight: 600;
}

.buy-list-entries {
  margin: 0;
  padding: 0;
  list-style: none;
}

.buy-list-entry {
  display: flex;
  flex-direction: column;
  padding: 4px 0;
}

.buy-list-row {
  display: flex;
  gap: 8px;
  align-items: baseline;
  justify-content: space-between;
}

.buy-list-name {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  align-items: baseline;
  min-width: 0;

  i {
    font-size: 0.8rem;
    color: var(--color-text-dim);
  }
}

.buy-list-price {
  white-space: nowrap;
}
</style>
