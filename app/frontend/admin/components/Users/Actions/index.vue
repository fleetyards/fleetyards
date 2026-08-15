<script lang="ts">
export default {
  name: "UserActions",
};
</script>

<script lang="ts" setup>
import Items from "@/admin/components/Users/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type User } from "@/services/fyAdminApi";

type Props = {
  user: User;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile">
    <Items :user="props.user" with-labels />
  </BtnDropdown>
  <BtnGroup v-else>
    <Items :user="props.user" />
  </BtnGroup>
</template>
