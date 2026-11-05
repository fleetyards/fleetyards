<script lang="ts">
export default {
  name: "HangarPlannerPledgeInfo",
};
</script>

<script lang="ts" setup>
import BasePopover from "@/shared/components/Popover/index.vue";
import MeltContents from "@/frontend/components/Hangar/Planner/MeltContents/index.vue";
import {
  type PledgeDetails,
  pledgeUnlisted,
} from "@/frontend/components/Hangar/Planner/format";
import type { HangarPlanPledgeShip } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  // The ship the pledge is shown for, which is part of what it holds.
  ship: HangarPlanPledgeShip;
  pledge: PledgeDetails;
};

const props = defineProps<Props>();

const { t } = useI18n();

const title = computed(
  () => props.pledge.pledgeName || t("hangarPlanner.pledge.package"),
);
</script>

<template>
  <BasePopover :label="title" click-toggles>
    <button
      type="button"
      class="pledge-info__btn"
      :aria-label="t('hangarPlanner.pledge.showContents', { name: title })"
      data-test="hangar-plan-pledge-info"
    >
      <i class="fa-regular fa-circle-info" aria-hidden="true" />
    </button>

    <template #content>
      <div class="pledge-info__card" data-test="hangar-plan-pledge-contents">
        <strong class="pledge-info__title">{{ title }}</strong>
        <MeltContents
          :ships="[ship, ...pledge.pledgeShips]"
          :items="pledge.pledgeItems"
          :unlisted="pledgeUnlisted(pledge)"
        />
      </div>
    </template>
  </BasePopover>
</template>

<style lang="scss" scoped>
.pledge-info__btn {
  position: relative;
  display: inline-flex;
  flex: none;
  align-items: center;
  justify-content: center;
  width: 22px;
  height: 22px;
  margin: 0;
  padding: 0;
  border: 0;
  background: transparent;
  font-size: 12px;
  color: var(--color-text-dim);
  cursor: help;

  // A finger's reach, beyond what the icon needs to be seen.
  &::before {
    content: "";
    position: absolute;
    inset: -7px;
  }

  &:hover {
    color: var(--color-lifted);
  }

  &:focus-visible {
    outline: 2px solid var(--color-primary);
    outline-offset: 1px;
  }
}

.pledge-info__card {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 12px 14px;
}

.pledge-info__title {
  color: var(--color-lifted);
}
</style>
