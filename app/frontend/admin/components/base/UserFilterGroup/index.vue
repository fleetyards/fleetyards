<template>
  <FilterGroup
    v-model="internalValue"
    :label="t('labels.selectUser')"
    :search-label="t('labels.findUser')"
    :query-fn="fetch"
    :query-response-formatter="formatter"
    :name="name"
    :paginated="true"
    :searchable="true"
    :multiple="multiple"
    :no-label="noLabel"
  />
</template>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import {
  users as fetchUsers,
  type UserQuery,
  type Users,
  type User,
} from "@/services/fyAdminApi";
import FilterGroup, {
  type FilterGroupParams,
} from "@/shared/components/base/FilterGroup/index.vue";

type Props = {
  name: string;
  modelValue?: string | string[];
  multiple?: boolean;
  noLabel?: boolean;
  returnObject?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  multiple: false,
  noLabel: true,
  returnObject: false,
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

const formatter = (response: Users) => {
  return response.items.map((user) => {
    return {
      label: user.username,
      value: user.username,
    };
  });
};

const fetch = async (params: FilterGroupParams<User>) => {
  const q: UserQuery = {};

  if (params.search) {
    q.usernameCont = params.search;
  }

  if (params.missing) {
    if (props.multiple) {
      q.usernameIn = params.missing as string[];
    } else {
      q.usernameEq = params.missing as string;
    }
  }

  return fetchUsers({
    page: String(params.page || 1),
    q,
  });
};
</script>

<script lang="ts">
export default {
  name: "UserFilterGroup",
};
</script>
