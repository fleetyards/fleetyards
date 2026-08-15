<script lang="ts">
export default {
  name: "ImageActions",
};
</script>

<script lang="ts" setup>
import Items from "@/admin/components/Images/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type Image } from "@/services/fyAdminApi";

type Props = {
  image: Image;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile">
    <Items :image="props.image" with-labels />
  </BtnDropdown>
  <BtnGroup v-else>
    <Items :image="props.image" />
  </BtnGroup>
</template>
