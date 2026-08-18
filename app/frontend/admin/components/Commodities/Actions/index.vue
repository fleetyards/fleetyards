<script lang="ts">
export default {
  name: "CommodityActions",
};
</script>

<script lang="ts" setup>
import Items from "@/admin/components/Commodities/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type Commodity } from "@/services/fyAdminApi";

type Props = {
  commodity: Commodity;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile">
    <Items :commodity="props.commodity" with-labels />
  </BtnDropdown>
  <BtnGroup v-else>
    <Items :commodity="props.commodity" />
  </BtnGroup>
</template>
