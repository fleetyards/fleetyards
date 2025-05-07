<template>
  <BtnDropdown v-if="mobile" :size="BtnSizesEnum.SMALL" inline>
    <Items :model-paint="props.modelPaint" with-labels />
  </BtnDropdown>
  <BtnGroup v-else inline>
    <Items :model-paint="props.modelPaint" />
  </BtnGroup>
</template>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Items from "@/admin/components/ModelPaints/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type ModelPaint } from "@/services/fyAdminApi";

type Props = {
  modelPaint: ModelPaint;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<script lang="ts">
export default {
  name: "ModelActions",
};
</script>
