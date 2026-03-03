<script lang="ts">
export default {
  name: "FleetMemberActions",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import Items from "@/frontend/components/Fleets/MemberActions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import type { FleetMember } from "@/services/fyApi";

type Props = {
  member: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile" :size="BtnSizesEnum.SMALL" inline>
    <Items
      :member="props.member"
      :resource-access="props.resourceAccess"
      with-labels
    />
  </BtnDropdown>
  <BtnGroup v-else inline>
    <Items :member="props.member" :resource-access="props.resourceAccess" />
  </BtnGroup>
</template>
