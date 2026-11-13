<script lang="ts">
export default {
  name: "AdminUserSelect",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import {
  adminUsers as fetchAdminUsers,
  type AdminUser,
  type AdminUsers,
} from "@/services/fyAdminApi";
import BaseSelect, {
  type BaseSelectParams,
} from "@/shared/components/base/Select/index.vue";

type Props = {
  name: string;
  multiple?: boolean;
  noLabel?: boolean;
};

withDefaults(defineProps<Props>(), {
  multiple: false,
  noLabel: true,
});

const { t } = useI18n();

const internalValue = defineModel<string | string[] | undefined>();

const formatter = (response: AdminUsers) => {
  return response.items.map((adminUser) => {
    return {
      label: adminUser.username,
      value: adminUser.username,
    };
  });
};

const fetch = async (params: BaseSelectParams<AdminUser>) => {
  return fetchAdminUsers({
    page: String(params.page || 1),
  });
};
</script>

<template>
  <BaseSelect
    v-model="internalValue"
    :label="t('labels.selectAdminUser')"
    :query-fn="fetch"
    :query-response-formatter="formatter"
    :name="name"
    :paginated="true"
    :multiple="multiple"
    :no-label="noLabel"
  />
</template>
