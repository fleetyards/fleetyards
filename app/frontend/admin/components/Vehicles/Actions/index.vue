<script lang="ts">
export default {
  name: "VehicleActions",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Items from "@/admin/components/Vehicles/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type Vehicle } from "@/services/fyAdminApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile" :size="BtnSizesEnum.SMALL" inline>
    <Items :vehicle="props.vehicle" with-labels />
  </BtnDropdown>
  <BtnGroup v-else inline>
    <Items :vehicle="props.vehicle" />
  </BtnGroup>
</template>
