<template>
  <BtnDropdown v-if="mobile" :size="BtnSizesEnum.SMALL" inline>
    <Items :user="props.user" with-labels />
  </BtnDropdown>
  <BtnGroup v-else inline>
    <Items :user="props.user" />
  </BtnGroup>
</template>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Items from "@/admin/components/Users/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type User } from "@/services/fyAdminApi";

type Props = {
  user: User;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<script lang="ts">
export default {
  name: "UserActions",
};
</script>
