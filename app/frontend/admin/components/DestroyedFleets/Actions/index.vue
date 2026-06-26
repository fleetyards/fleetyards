<script lang="ts">
export default {
  name: "DestroyedFleetActions",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Items from "@/admin/components/DestroyedFleets/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type DestroyedFleet } from "@/services/fyAdminApi";

type Props = {
  destroyedFleet: DestroyedFleet;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile" :size="BtnSizesEnum.SMALL" inline>
    <Items :destroyed-fleet="props.destroyedFleet" with-labels />
  </BtnDropdown>
  <BtnGroup v-else inline>
    <Items :destroyed-fleet="props.destroyedFleet" />
  </BtnGroup>
</template>
