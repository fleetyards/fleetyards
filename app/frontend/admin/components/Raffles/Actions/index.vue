<script lang="ts">
export default {
  name: "RaffleActions",
};
</script>

<script lang="ts" setup>
import Items from "@/admin/components/Raffles/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type Raffle } from "@/services/fyAdminApi";

type Props = {
  raffle: Raffle;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile">
    <Items :raffle="props.raffle" with-labels />
  </BtnDropdown>
  <BtnGroup v-else>
    <Items :raffle="props.raffle" />
  </BtnGroup>
</template>
