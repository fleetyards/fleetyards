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
      <SmallLoader :loading="loading" />
      <i class="fa fa-chevron-right" />
    </div>
    <Collapsed
      :visible="selectedOptions.length > 0 && !visible"
      v-if="multiple"
      :id="`${name}-selected-${id}`"
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
      :visible="visible"
      :id="`${name}-options-${id}`"
      class="filter-group-items-wrapper"
    >
      <FormInput
        v-if="searchable"
        :id="`${name}-searchInput-${id}`"
        ref="searchInput"
        v-model="search"
        :placeholder="searchPlaceholder"
        :label="searchLabelFallback"
        class="filter-group-search"
        variant="clean"
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
          @click="fetchMore"
          variant="link"
          inline
          class="fade-list-item filter-group-fetch-more"
          >{{ i18n?.t("filterGroup.actions.fetchMore") }}</Btn
        >
      </div>
    </Collapsed>
  </div>
</template>

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import Btn from "@/shared/components/BaseBtn/index.vue";
import FormInput from "@/shared/components/Form/FormInput/index.vue";
import { debounce } from "ts-debounce";
import { v4 as uuidv4 } from "uuid";
import Option from "./Option/index.vue";
import type { FilterGroupOption } from "./Option/index.vue";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";
import { useQuery } from "@tanstack/vue-query";

export type FilterGroupParams = {
  search?: string;
  missing?: string | string[];
  page?: number;
};

type Props = {
  name: string;
  queryFn?: (params: FilterGroupParams) => Promise<any>;
  queryResponseFormatter?: (items: any[]) => FilterGroupOption[];
  modelValue?: string[] | string;
  options?: FilterGroupOption[];
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

const i18n = inject<I18nPluginOptions>("i18n");

const id = ref<string>(uuidv4());

const visible = ref(false);

const fetchMoreVisible = ref(props.paginated);

const search = ref<string | undefined>();

const missing = ref<string | string[] | undefined>();

const page = ref(1);

const internalOptions = ref<FilterGroupOption[]>([]);

const prompt = computed(() => {
  if (!props.multiple && selectedOptions.value.length > 0) {
    return selectedOptions.value[0].label;
  }

  if (props.translationKey) {
    if (props.nullable) {
      return i18n?.t(
        `.labels.filterGroup.${props.translationKey}.nullablePrompt`
      );
    }

    return i18n?.t(`labels.filterGroup.${props.translationKey}.prompt`);
  }

  if (props.nullable) {
    return i18n?.t(`filterGroup.labels.nullablePrompt`);
  }

  return i18n?.t(`filterGroup.labels.prompt`);
});

const loading = computed(() => {
  return isLoading.value || isFetching.value;
});

const { isLoading, isFetching, data, refetch } = useQuery({
  queryKey: [
    "filterGroupOptions",
    id.value,
    props.name,
    page.value,
    search.value,
    missing.value,
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

    let data = response;
    if (props.paginated) {
      data = response.items;
    }

    if (props.queryResponseFormatter) {
      data = props.queryResponseFormatter(data);
    }

    if (props.paginated) {
      fetchMoreVisible.value =
        response.meta?.pagination?.currentPage <
        response.meta?.pagination?.totalPages;
    }

    return data;
  },
  keepPreviousData: true,
  enabled: !!props.queryFn,
});

watch(
  () => data.value,
  () => {
    if (data.value) {
      addOptions(data.value);
      fetchMissingOption();
    }
  }
);

watch(
  () => props.options,
  () => {
    internalOptions.value = props.options || [];
  }
);

const labelVisible = computed(
  () => !props.hideLabelOnEmpty || selectedOptions.value.length > 0
);

const innerLabel = computed(() => {
  if (props.label) {
    return props.label;
  }

  if (props.translationKey) {
    return i18n?.t(`labels.filterGroup.${props.translationKey}.label`);
  }

  return i18n?.t(`labels.filterGroup.${props.name}.label`);
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
  return i18n?.t("filterGroup.labels.search");
});

const availableOptions = computed<FilterGroupOption[]>(() =>
  sort(internalOptions.value)
);

const selectedOptions = computed(() => {
  if (props.multiple) {
    return availableOptions.value.filter(
      (item) =>
        props.modelValue && (props.modelValue as string[]).includes(item.value)
    );
  }

  const selectedOption = availableOptions.value.find(
    (item) => item.value === props.modelValue
  );

  return selectedOption ? [selectedOption] : [];
});

const filteredOptions = computed(() => {
  if (search.value) {
    return internalOptions.value.filter((item) =>
      item.label.toLowerCase().includes(String(search.value?.toLowerCase()))
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

const sort = (options: FilterGroupOption[]) => {
  const sortedOptions = JSON.parse(JSON.stringify(options));
  return sortedOptions.sort((a: FilterGroupOption, b: FilterGroupOption) => {
    if (a.label < b.label) {
      return -1;
    }
    if (a.label > b.label) {
      return 1;
    }
    return 0;
  });
};

const addOptions = (newOptions: FilterGroupOption[]) => {
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
    return (props.modelValue || []).includes(option);
  }

  return props.modelValue === option;
};

const emit = defineEmits(["update:modelValue"]);

const select = (option: string) => {
  clearSearch();

  if (selected(option)) {
    if (props.multiple) {
      emit(
        "update:modelValue",
        (props.modelValue as string[]).filter((item: string) => item !== option)
      );
    } else if (props.nullable) {
      emit("update:modelValue", undefined);
    }
  } else if (props.multiple) {
    const value = JSON.parse(JSON.stringify(props.modelValue || []));

    value.push(option);

    emit("update:modelValue", value);

    focusSearch();
  } else {
    emit("update:modelValue", option);

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

<script lang="ts">
export default {
  name: "FilterGroup",
};
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
