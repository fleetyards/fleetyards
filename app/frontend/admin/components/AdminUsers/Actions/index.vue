<script lang="ts">
export default {
  name: "AdminUserActions",
};
</script>

<script lang="ts" setup>
import Items from "@/admin/components/AdminUsers/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type AdminUser } from "@/services/fyAdminApi";

type Props = {
  adminUser: AdminUser;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile">
    <Items :admin-user="props.adminUser" with-labels />
  </BtnDropdown>
  <BtnGroup v-else>
    <Items :admin-user="props.adminUser" />
  </BtnGroup>
</template>
