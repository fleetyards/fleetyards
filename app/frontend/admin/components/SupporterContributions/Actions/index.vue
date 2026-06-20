<script lang="ts">
export default {
  name: "SupporterContributionActions",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Items from "@/admin/components/SupporterContributions/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type SupporterContribution } from "@/services/fyAdminApi";

type Props = {
  supporterContribution: SupporterContribution;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile" :size="BtnSizesEnum.SMALL" inline>
    <Items :supporter-contribution="props.supporterContribution" with-labels />
  </BtnDropdown>
  <BtnGroup v-else inline>
    <Items :supporter-contribution="props.supporterContribution" />
  </BtnGroup>
</template>
