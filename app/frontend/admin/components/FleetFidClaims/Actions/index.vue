<script lang="ts">
export default {
  name: "FleetFidClaimActions",
};
</script>

<script lang="ts" setup>
import Items from "@/admin/components/FleetFidClaims/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type AdminFleetFidClaim } from "@/services/fyAdminApi";

type Props = {
  claim: AdminFleetFidClaim;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile">
    <Items :claim="props.claim" with-labels />
  </BtnDropdown>
  <BtnGroup v-else>
    <Items :claim="props.claim" />
  </BtnGroup>
</template>
