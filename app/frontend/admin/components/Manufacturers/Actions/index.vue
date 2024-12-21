<template>
  <BtnDropdown v-if="mobile" :size="BtnSizesEnum.SMALL" inline>
    <Items :manufacturer="props.manufacturer" with-labels />
  </BtnDropdown>
  <BtnGroup v-else inline>
    <Items :manufacturer="props.manufacturer" />
  </BtnGroup>
</template>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Items from "@/admin/components/Manufacturers/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type Manufacturer } from "@/services/fyAdminApi";

type Props = {
  manufacturer: Manufacturer;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<script lang="ts">
export default {
  name: "ManufacturerActions",
};
</script>
