<template>
  <BtnDropdown v-if="mobile" :size="BtnSizesEnum.SMALL" inline>
    <Items :model="props.model" with-labels />
  </BtnDropdown>
  <BtnGroup v-else inline>
    <Items :model="props.model" />
  </BtnGroup>
</template>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Items from "@/admin/components/Models/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type Model } from "@/services/fyAdminApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<script lang="ts">
export default {
  name: "ModelActions",
};
</script>
