<script lang="ts">
export default {
  name: "AdminUserFilterGroup",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import {
  adminUsers as fetchAdminUsers,
  type AdminUser,
  type AdminUsers,
} from "@/services/fyAdminApi";
import FilterGroup, {
  type FilterGroupParams,
} from "@/shared/components/base/FilterGroup/index.vue";

type Props = {
  name: string;
  modelValue?: string | string[];
  multiple?: boolean;
  noLabel?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  multiple: false,
  noLabel: true,
});

const { t } = useI18n();

const internalValue = ref<string | string[] | undefined>(props.modelValue);

onMounted(() => {
  internalValue.value = props.modelValue;
});

watch(
  () => props.modelValue,
  () => {
    internalValue.value = props.modelValue;
  },
);

const emit = defineEmits(["update:modelValue"]);

watch(
  () => internalValue.value,
  () => {
    emit("update:modelValue", internalValue.value);
  },
);

const formatter = (response: AdminUsers) => {
  return response.items.map((adminUser) => {
    return {
      label: adminUser.username,
      value: adminUser.username,
    };
  });
};

const fetch = async (params: FilterGroupParams<AdminUser>) => {
  return fetchAdminUsers({
    page: String(params.page || 1),
  });
};
</script>

<template>
  <FilterGroup
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
