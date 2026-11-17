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
import ShipName from "@/frontend/components/Hangar/Planner/ShipName/index.vue";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import { useI18n } from "@/shared/composables/useI18n";
import {
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

const groups = computed(() =>
  Object.values(HangarPlanPurchaseKindEnum)
    .map((kind) => {
      const purchases = (props.purchases ?? []).filter(
        (purchase) => purchase.kind === kind,
      );
      const prices = purchases.map((purchase) => purchase.price);

      return {
        kind,
        purchases,
        subtotal: prices.some((price) => price === null || price === undefined)
          ? undefined
          : prices.reduce<number>((sum, price) => sum + (price ?? 0), 0),
      };
    })
    .filter((group) => group.purchases.length),
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
        <ul class="buy-list-entries">
          <li
            v-for="(purchase, index) in group.purchases"
            :key="index"
            class="buy-list-entry"
          >
            <div class="buy-list-row">
              <span class="buy-list-name">
                <template v-if="purchase.model">
                  <template v-if="purchase.fromModel">
                    <ShipName :ship="purchase.fromModel" />
                    <i class="fa-light fa-arrow-right" aria-hidden="true" />
                  </template>
                  <ShipName :ship="purchase.model" />
                </template>
                <span v-else>{{ purchase.name }}</span>
                <span v-if="purchase.quantity > 1" class="buy-list-muted">
                  ×{{ purchase.quantity }}
                </span>
              </span>
              <span v-if="priced(purchase.kind)" class="buy-list-price">
                {{ money(purchase.price) }}
              </span>
            </div>
            <small class="buy-list-muted">{{ labelsOf(purchase) }}</small>
            <small v-if="purchase.notOnSale" class="buy-list-warning">
              {{ t("hangarPlanner.buyList.notOnSale") }}
            </small>
            <small v-if="purchase.tokenCount" class="buy-list-muted">
              {{
                t("hangarPlanner.buyList.usesToken", {
                  count: purchase.tokenCount,
                })
              }}
            </small>
          </li>
        </ul>
      </section>
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
