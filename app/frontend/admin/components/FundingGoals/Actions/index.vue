<script lang="ts">
export default {
  name: "FundingGoalActions",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Items from "@/admin/components/FundingGoals/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type FundingGoal } from "@/services/fyAdminApi";

type Props = {
  fundingGoal: FundingGoal;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile" :size="BtnSizesEnum.SMALL" inline>
    <Items :funding-goal="props.fundingGoal" with-labels />
  </BtnDropdown>
  <BtnGroup v-else inline>
    <Items :funding-goal="props.fundingGoal" />
  </BtnGroup>
</template>
