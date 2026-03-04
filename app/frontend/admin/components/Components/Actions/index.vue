<script lang="ts">
export default {
  name: "ComponentActions",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Items from "@/admin/components/Components/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type Component } from "@/services/fyAdminApi";

type Props = {
  component: Component;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile" :size="BtnSizesEnum.SMALL" inline>
    <Items :component="props.component" with-labels />
  </BtnDropdown>
  <BtnGroup v-else inline>
    <Items :component="props.component" />
  </BtnGroup>
</template>
