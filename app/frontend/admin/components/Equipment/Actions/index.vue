<script lang="ts">
export default {
  name: "EquipmentActions",
};
</script>

<script lang="ts" setup>
import Items from "@/admin/components/Equipment/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type Equipment } from "@/services/fyAdminApi";

type Props = {
  equipment: Equipment;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile">
    <Items :equipment="props.equipment" with-labels />
  </BtnDropdown>
  <BtnGroup v-else>
    <Items :equipment="props.equipment" />
  </BtnGroup>
</template>
