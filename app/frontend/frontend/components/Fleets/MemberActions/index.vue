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
import type {
  FleetMember,
  FleetMembershipCapabilities,
} from "@/services/fyApi";

type Props = {
  member: FleetMember;
  capabilities?: FleetMembershipCapabilities;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile" :size="BtnSizesEnum.SMALL" inline>
    <Items
      :member="props.member"
      :capabilities="props.capabilities"
      with-labels
    />
  </BtnDropdown>
  <BtnGroup v-else inline>
    <Items :member="props.member" :capabilities="props.capabilities" />
  </BtnGroup>
</template>
