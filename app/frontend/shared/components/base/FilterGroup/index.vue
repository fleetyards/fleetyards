<script lang="ts">
export default {
  name: "FilterGroup",
};
</script>

<script lang="ts" setup generic="T">
import Collapsed from "@/shared/components/Collapsed.vue";
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { debounce } from "ts-debounce";
import { v4 as uuidv4 } from "uuid";
import Option from "./Option/index.vue";
import {
  UseQueryReturnType,
  keepPreviousData,
  useQuery,
} from "@tanstack/vue-query";
import type { BaseList, FilterOption } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import { InputVariantsEnum } from "@/shared/components/base/FormInput/types";

export interface FilterGroupOption<T> extends FilterOption {
  object: T;
}

export type ValueType<T> =
  | FilterGroupOption<T>
  | FilterGroupOption<T>[]
  | string[]
  | string
  | number[]
  | number
  | boolean
  | null;

export type FilterGroupParams<T> = {
  search?: string;
  missing?: ValueType<T>;
  page?: number;
};

type Props = {
  name: string;
  query?: (
    params: FilterGroupParams<T>,
  ) => UseQueryReturnType<FilterOption[], Error>;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  queryFn?: (params: FilterGroupParams<T>) => Promise<any>;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  queryResponseFormatter?: (response: any) => FilterOption[];
  modelValue?: ValueType<T>;
  options?: FilterOption[];
  error?: string;
  label?: string;
  searchLabel?: string;
  translationKey?: string;
  hideLabelOnEmpty?: boolean;
  multiple?: boolean;
  disabled?: boolean;
  searchable?: boolean;
  returnObject?: boolean;
  nullable?: boolean;
  paginated?: boolean;
  noLabel?: boolean;
  bigIcon?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  query: undefined,
  queryFn: undefined,
  queryResponseFormatter: (items: FilterOption[]) => items,
  modelValue: undefined,
  options: undefined,
  error: undefined,
  label: undefined,
  searchLabel: undefined,
  translationKey: undefined,
  hideLabelOnEmpty: false,
  multiple: false,
  disabled: false,
  searchable: false,
  returnObject: false,
  nullable: true,
  paginated: false,
  noLabel: false,
  bigIcon: false,
});

const { t } = useI18n();

const id = ref<string>(uuidv4());

const visible = ref(false);

const fetchMoreVisible = ref(props.paginated);

const search = ref<string | undefined>();

const missing = ref<ValueType<T> | undefined>();

const page = ref(1);

const internalOptions = ref<FilterOption[]>([]);

const prompt = computed(() => {
  if (!props.multiple && selectedOptions.value.length > 0) {
    return selectedOptions.value[0].label;
  }

  if (props.translationKey) {
    if (props.nullable) {
      return t(`.labels.filterGroup.${props.translationKey}.nullablePrompt`);
    }

    return t(`labels.filterGroup.${props.translationKey}.prompt`);
  }

  if (props.noLabel && props.label) {
    return props.label;
  }

  if (props.nullable) {
    return t(`filterGroup.labels.nullablePrompt`);
  }

  return t(`filterGroup.labels.prompt`);
});

const loading = computed(() => {
  return isLoading.value || isFetching.value;
});

const { isLoading, isFetching, data, refetch } = useQuery({
  refetchOnWindowFocus: false,
  queryKey: [
    "filterGroupOptions",
    id.value,
    props.name,
    page.value,
    search.value,
    missing.value as string,
  ],
  queryFn: async () => {
    if (!props.queryFn) {
      return;
    }

    const response = await props.queryFn({
      page: page.value,
      search: search.value,
      missing: missing.value,
    });

    const data = props.queryResponseFormatter(response);

    if (
      props.paginated &&
      (response as BaseList).meta &&
      (response as BaseList).meta.pagination
    ) {
      fetchMoreVisible.value =
        (response as BaseList).meta.pagination!.currentPage <
        (response as BaseList).meta.pagination!.totalPages;
    }

    return data;
  },
  placeholderData: keepPreviousData,
  enabled: !!props.queryFn,
});

watch(
  () => data.value,
  () => {
    if (data.value) {
      addOptions(data.value);
      fetchMissingOption();
    }
  },
);

watch(
  () => props.options,
  () => {
    internalOptions.value = props.options || [];
  },
);

const labelVisible = computed(
  () => !props.hideLabelOnEmpty || selectedOptions.value.length > 0,
);

const innerLabel = computed(() => {
  if (props.label) {
    return props.label;
  }

  if (props.translationKey) {
    return t(`labels.filterGroup.${props.translationKey}.label`);
  }

  return t(`labels.filterGroup.${props.name}.label`);
});

const labelFor = computed(() => {
  if (props.searchable) {
    return `${props.name}-searchInput-${id}`;
  }

  return `${props.name}-options-${id}`;
});

const searchPlaceholder = computed(() => {
  return props.searchLabel || searchLabelFallback.value;
});

const searchLabelFallback = computed(() => {
  return t("filterGroup.labels.search");
});

const availableOptions = computed<FilterOption[]>(() =>
  sort(internalOptions.value),
);

const selectedOptions = computed(() => {
  if (props.multiple) {
    return availableOptions.value.filter(
      (item) =>
        props.modelValue && (props.modelValue as string[]).includes(item.value),
    );
  }

  const selectedOption = availableOptions.value.find(
    (item) => item.value === props.modelValue,
  );

  return selectedOption ? [selectedOption] : [];
});

const filteredOptions = computed(() => {
  if (search.value) {
    return internalOptions.value.filter((item) =>
      item.label.toLowerCase().includes(String(search.value?.toLowerCase())),
    );
  }

  return internalOptions.value;
});

const cssClasses = computed(() => ({
  "has-error has-feedback": props.error,
}));

onMounted(() => {
  document.addEventListener("click", documentClick);

  id.value = uuidv4();

  if (props.options) {
    internalOptions.value = props.options;
  }
});

onUnmounted(() => {
  document.removeEventListener("click", documentClick);
});

const filterGroup = ref<HTMLElement | null>(null);

const documentClick = (event: Event) => {
  if (!filterGroup.value) {
    return;
  }

  const element = filterGroup.value;
  const target = event.target as HTMLElement;

  if (element !== target && !element.contains(target)) {
    visible.value = false;
  }
};

const debouncedOnSearch = () => {
  if (search.value) {
    page.value = 1;

    refetch();
  }
};

const onSearch = debounce(debouncedOnSearch, 500);

const fetchMissingOption = async () => {
  if (
    !props.modelValue ||
    (props.multiple &&
      selectedOptions.value.length === (props.modelValue as string[]).length) ||
    (!props.multiple && selectedOptions.value[0]?.value === props.modelValue)
  ) {
    return;
  }

  missing.value = props.modelValue;

  refetch();
};

const fetchMore = () => {
  page.value += 1;

  refetch();
};

const sort = (options: FilterOption[]) => {
  const sortedOptions = JSON.parse(JSON.stringify(options));
  return sortedOptions.sort((a: FilterOption, b: FilterOption) => {
    if (a.label < b.label) {
      return -1;
    }
    if (a.label > b.label) {
      return 1;
    }
    return 0;
  });
};

const addOptions = (newOptions: FilterOption[]) => {
  newOptions.forEach((item) => {
    if (!internalOptions.value.find((option) => option.value === item.value)) {
      internalOptions.value.push(item);
    }
  });
};

const clearSearch = () => {
  search.value = undefined;
};

const selected = (option: string) => {
  if (props.multiple) {
    return ((props.modelValue as string[]) || []).includes(option);
  }

  return props.modelValue === option;
};

const emit = defineEmits(["update:modelValue"]);

const select = (optionValue: string) => {
  clearSearch();

  if (selected(optionValue)) {
    if (props.multiple) {
      emit(
        "update:modelValue",
        (props.modelValue as string[]).filter(
          (item: string) => item !== optionValue,
        ),
      );
    } else if (props.nullable) {
      emit("update:modelValue", null);
    }
  } else if (props.multiple) {
    const values: string[] = JSON.parse(JSON.stringify(props.modelValue || []));

    values.push(optionValue);

    if (props.returnObject) {
      emit(
        "update:modelValue",
        values.map((value) => {
          return internalOptions.value.find((item) => item.value === value);
        }),
      );
    } else {
      emit("update:modelValue", values);
    }

    focusSearch();
  } else {
    if (props.returnObject) {
      emit(
        "update:modelValue",
        internalOptions.value.find((item) => item.value === optionValue),
      );
    } else {
      emit("update:modelValue", optionValue);
    }

    toggle();
  }
};

const toggle = () => {
  if (props.disabled) {
    return;
  }

  visible.value = !visible.value;

  focusSearch();
};

const searchInput = ref<InstanceType<typeof FormInput> | null>(null);

const focusSearch = () => {
  if (props.searchable && visible.value) {
    nextTick(() => {
      if (searchInput.value) {
        searchInput.value.setFocus();
      }
    });
  }
};
</script>

<template>
  <div ref="filterGroup" class="filter-group" :class="cssClasses">
    <transition name="fade">
      <label
        v-show="labelVisible"
        v-if="innerLabel && !noLabel"
        :for="labelFor"
      >
        {{ innerLabel }}
      </label>
    </transition>
    <div
      v-tooltip.right="error"
      :class="{
        active: visible,
        disabled,
        selected: selectedOptions.length > 0,
        hasLabel: labelVisible,
      }"
      class="filter-group-title"
      @click="toggle"
    >
      <span class="filter-group-title-prompt">
        {{ prompt }}
      </span>
      <SmallLoader v-if="queryFn" :loading="loading" />
      <i class="fa fa-chevron-right" />
    </div>
    <Collapsed
      v-if="multiple"
      :id="`${name}-selected-${id}`"
      :visible="selectedOptions.length > 0 && !visible"
      class="filter-group-items"
    >
      <Option
        v-for="(option, index) in selectedOptions"
        :key="`${name}-selected-${id}-${option.value}-${index}`"
        :option="option"
        :selected="selected(option.value)"
        :big-icon="bigIcon"
        :multiple="multiple"
        :nullable="nullable"
        @select="select(option.value)"
      />
    </Collapsed>
    <Collapsed
      :id="`${name}-options-${id}`"
      :visible="visible"
      class="filter-group-items-wrapper"
    >
      <FormInput
        v-if="searchable"
        ref="searchInput"
        v-model="search"
        :name="`${name}-searchInput-${id}`"
        :placeholder="searchPlaceholder"
        :label="searchLabelFallback"
        class="filter-group-search"
        :variant="InputVariantsEnum.CLEAN"
        :no-label="true"
        :clearable="true"
        @input="onSearch"
      />
      <div class="filter-group-items">
        <Option
          v-for="(option, index) in filteredOptions"
          :key="`${name}-options-${id}-${option.value}-${index}`"
          :option="option"
          :selected="selected(option.value)"
          :big-icon="bigIcon"
          :multiple="multiple"
          :nullable="nullable"
          @select="select(option.value)"
        />

        <Btn
          v-if="fetchMoreVisible && paginated"
          :disabled="loading"
          :variant="BtnVariantsEnum.LINK"
          inline
          class="fade-list-item filter-group-fetch-more"
          @click="fetchMore"
          >{{ t("filterGroup.actions.fetchMore") }}</Btn
        >
      </div>
    </Collapsed>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
