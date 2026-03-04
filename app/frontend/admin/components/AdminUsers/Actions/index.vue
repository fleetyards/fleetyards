<script lang="ts">
export default {
  name: "AdminUserActions",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
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
  <BtnDropdown v-if="mobile" :size="BtnSizesEnum.SMALL" inline>
    <Items :admin-user="props.adminUser" with-labels />
  </BtnDropdown>
  <BtnGroup v-else inline>
    <Items :admin-user="props.adminUser" />
  </BtnGroup>
</template>
