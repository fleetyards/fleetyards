<script lang="ts">
export default {
  name: "UserFilterGroup",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import {
  userOptions as fetchUserOptions,
  type UserQuery,
  type UserOptions,
  type UserOption,
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

const formatter = (response: UserOptions) => {
  return response.items.map((user) => {
    return {
      label: user.username,
      value: user.username,
    };
  });
};

const fetch = async (params: FilterGroupParams<UserOption>) => {
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

  return fetchUserOptions({
    page: String(params.page || 1),
    q,
  });
};
</script>

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
