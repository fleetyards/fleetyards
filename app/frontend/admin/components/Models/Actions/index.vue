<template>
  <BtnDropdown v-if="mobile" :size="BtnSizesEnum.SMALL" inline>
    <Items :record="props.record" with-labels />
  </BtnDropdown>
  <BtnGroup v-else inline>
    <Items :record="props.record" />
  </BtnGroup>
</template>

<script lang="ts" setup generic="T extends ModelActionsRecord">
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Items from "@/admin/components/Models/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { ModelActionsRecord } from "@/admin/components/Models/Actions/types";

type Props = {
  record: T;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<script lang="ts">
export default {
  name: "ModelActions",
};
</script>
