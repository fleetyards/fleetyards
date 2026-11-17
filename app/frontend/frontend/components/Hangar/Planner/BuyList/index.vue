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
import {
  buildBuyList,
  type BuyListGroup,
} from "@/frontend/components/Hangar/Planner/BuyList/buyList";
import { useI18n } from "@/shared/composables/useI18n";
import type { HangarPlanSlot } from "@/services/fyApi";

type Props = {
  slots: HangarPlanSlot[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const { money, amount } = usePlanMoney();

const groups = computed(() => buildBuyList(props.slots));

// Ships earned in game are paid in aUEC, which no store total takes in.
const priced = (group: BuyListGroup) => group.section !== "ingame";

const pricedGroups = computed(() => groups.value.filter(priced));

const total = computed(() =>
  pricedGroups.value.reduce((sum, group) => sum + group.total, 0),
);

const hasUnknownPrice = computed(() =>
  pricedGroups.value.some((group) => group.hasUnknownPrice),
);
</script>

<template>
  <Panel :variant="PanelVariantsEnum.SLIM" data-test="hangar-plan-buy-list">
    <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
      {{ t("hangarPlanner.buyList.title") }}
    </PanelHeading>
    <PanelBody>
      <p v-if="!groups.length" class="buy-list__muted">
        {{ t("hangarPlanner.buyList.empty") }}
      </p>

      <section
        v-for="group in groups"
        :key="group.section"
        class="buy-list__group"
        :data-test="`hangar-plan-buy-list-${group.section}`"
      >
        <h3 class="buy-list__group-title">
          <span>{{
            t(`hangarPlanner.buyList.sections.${group.section}`)
          }}</span>
          <span v-if="priced(group)" class="buy-list__muted">
            {{ amount(group.total) }}
          </span>
        </h3>
        <ul class="buy-list__entries">
          <li
            v-for="entry in group.entries"
            :key="entry.key"
            class="buy-list__entry"
          >
            <div class="buy-list__row">
              <span class="buy-list__name">
                <template v-if="entry.fromModel">
                  <ShipName :ship="entry.fromModel" />
                  <i class="fa-light fa-arrow-right" aria-hidden="true" />
                </template>
                <ShipName :ship="entry.model" />
                <span v-if="entry.quantity > 1" class="buy-list__muted">
                  ×{{ entry.quantity }}
                </span>
              </span>
              <span v-if="priced(group)" class="buy-list__price">
                {{ money(entry.price) }}
              </span>
            </div>
            <small class="buy-list__muted">
              {{ entry.slotLabels.join(", ") }}
            </small>
            <small v-if="entry.notOnSale" class="buy-list__warning">
              {{ t("hangarPlanner.buyList.notOnSale") }}
            </small>
            <small v-if="entry.usesBuybackToken" class="buy-list__muted">
              {{ t("hangarPlanner.buyList.usesToken") }}
            </small>
          </li>
        </ul>
      </section>

      <div
        v-if="pricedGroups.length"
        class="buy-list__total"
        data-test="hangar-plan-buy-list-total"
      >
        <span>{{ t("hangarPlanner.buyList.total") }}</span>
        <span>
          {{ amount(total) }}
          <small v-if="hasUnknownPrice" class="buy-list__warning">
            {{ t("hangarPlanner.buyList.unknownPrices") }}
          </small>
        </span>
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.buy-list__muted {
  color: var(--color-text-dim);
}

.buy-list__warning {
  color: var(--color-warning);
}

.buy-list__group + .buy-list__group {
  margin-top: 12px;
}

.buy-list__group-title {
  display: flex;
  justify-content: space-between;
  margin: 0 0 4px;
  font-size: 0.9rem;
  font-weight: 600;
}

.buy-list__entries {
  margin: 0;
  padding: 0;
  list-style: none;
}

.buy-list__entry {
  display: flex;
  flex-direction: column;
  padding: 4px 0;
}

.buy-list__row {
  display: flex;
  gap: 8px;
  align-items: baseline;
  justify-content: space-between;
}

.buy-list__name {
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

.buy-list__price {
  white-space: nowrap;
}

.buy-list__total {
  display: flex;
  justify-content: space-between;
  margin-top: 12px;
  padding-top: 8px;
  font-weight: 600;
  border-top: 1px solid var(--color-border);

  small {
    display: block;
    font-weight: 400;
    text-align: right;
  }
}
</style>
