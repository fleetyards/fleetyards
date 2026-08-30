<script lang="ts">
export default {
  name: "FleetMemberActions",
};
</script>

<script lang="ts" setup>
import Items from "@/admin/components/Fleets/Members/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type Fleet, type AdminFleetMember } from "@/services/fyAdminApi";

type Props = {
  fleet: Fleet;
  member: AdminFleetMember;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile">
    <Items :fleet="props.fleet" :member="props.member" with-labels />
  </BtnDropdown>
  <BtnGroup v-else>
    <Items :fleet="props.fleet" :member="props.member" />
  </BtnGroup>
</template>
