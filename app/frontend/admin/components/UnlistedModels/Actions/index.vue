<script lang="ts">
export default {
  name: "UnlistedModelActions",
};
</script>

<script lang="ts" setup>
import Items from "@/admin/components/UnlistedModels/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type ScDataUnlistedModel } from "@/services/fyAdminApi";

type Props = {
  unlistedModel: ScDataUnlistedModel;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile">
    <Items :unlisted-model="props.unlistedModel" with-labels />
  </BtnDropdown>
  <BtnGroup v-else>
    <Items :unlisted-model="props.unlistedModel" />
  </BtnGroup>
</template>
