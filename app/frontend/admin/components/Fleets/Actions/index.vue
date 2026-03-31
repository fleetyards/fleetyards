<script lang="ts">
export default {
  name: "FleetActions",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Items from "@/admin/components/Fleets/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type Fleet } from "@/services/fyAdminApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile" :size="BtnSizesEnum.SMALL" inline>
    <Items :fleet="props.fleet" with-labels />
  </BtnDropdown>
  <BtnGroup v-else inline>
    <Items :fleet="props.fleet" />
  </BtnGroup>
</template>
