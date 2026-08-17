<script lang="ts">
export default {
  name: "ManufacturerActions",
};
</script>

<script lang="ts" setup>
import Items from "@/admin/components/Manufacturers/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type Manufacturer } from "@/services/fyAdminApi";

type Props = {
  manufacturer: Manufacturer;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile">
    <Items :manufacturer="props.manufacturer" with-labels />
  </BtnDropdown>
  <BtnGroup v-else>
    <Items :manufacturer="props.manufacturer" />
  </BtnGroup>
</template>
