<script lang="ts">
export default {
  name: "ModelActions",
};
</script>

<script lang="ts" setup>
import Items from "@/admin/components/Models/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type Model } from "@/services/fyAdminApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile">
    <Items :model="props.model" with-labels />
  </BtnDropdown>
  <BtnGroup v-else>
    <Items :model="props.model" />
  </BtnGroup>
</template>
