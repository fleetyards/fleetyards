<script lang="ts">
export default {
  name: "SupporterContributionActions",
};
</script>

<script lang="ts" setup>
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
  <BtnDropdown v-if="mobile">
    <Items :supporter-contribution="props.supporterContribution" with-labels />
  </BtnDropdown>
  <BtnGroup v-else>
    <Items :supporter-contribution="props.supporterContribution" />
  </BtnGroup>
</template>
