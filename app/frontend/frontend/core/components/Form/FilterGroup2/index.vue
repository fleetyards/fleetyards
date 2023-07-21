<template>
  <div ref="filterGroup" class="filter-group2" :class="cssClasses">
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
    <div
      v-if="multiple"
      :id="`${name}-selected-${id}`"
      v-show-slide:400:ease-in-out="selectedOptions.length > 0 && !visible"
      class="filter-group-items"
    >
      <FilterGroupOption
        v-for="(option, index) in selectedOptions"
        :key="`${name}-selected-${id}-${option.value}-${index}`"
        :option="option"
        :selected="selected(option.value)"
        :big-icon="bigIcon"
        :multiple="multiple"
        :nullable="nullable"
        @select="select(option.value)"
      />
    </div>
    <div
      :id="`${name}-options-${id}`"
      v-show-slide:400:ease-in-out="visible"
      class="filter-group-items-wrapper"
    >
      <FormInput
        v-if="searchable"
        :id="`${name}-searchInput-${id}`"
        ref="searchInput"
        v-model="search"
        :placeholder="searchLabel || t('actions.find')"
        :label="t('actions.find')"
        class="filter-group-search"
        variant="clean"
        :no-label="true"
        :clearable="true"
        @input="onSearch"
      />
      <div class="filter-group-items">
        <FilterGroupOption
          v-for="(option, index) in filteredOptions"
          :key="`${name}-options-${id}-${option.value}-${index}`"
          :option="option"
          :selected="selected(option.value)"
          :big-icon="bigIcon"
          :multiple="multiple"
          :nullable="nullable"
          @select="select(option.value)"
        />

        <InfiniteLoading
          v-if="!options && internalOptions.length && !search && paginated"
          ref="infiniteLoading"
          :distance="100"
          @infinite="fetchMore"
        >
          <span slot="no-more" />
          <span slot="spinner" />
        </InfiniteLoading>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import { debounce } from "ts-debounce";
import InfiniteLoading from "vue-infinite-loading";
import type { StateChanger } from "vue-infinite-loading";
import { v4 as uuidv4 } from "uuid";
import { useI18n } from "@/frontend/composables/useI18n";
import FilterGroupOption from "@/frontend/core/components/Form/FilterGroup2/Option/index.vue";

type Props = {
  name: string;
  value?: string[] | string;
  options?: TFilterGroupOption[];
  fetch?: (params: TFilterGroupParams) => Promise<TFilterGroupOption[]>;
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
  value: undefined,
  options: undefined,
  fetch: undefined,
  error: undefined,
  label: undefined,
  searchLabel: undefined,
  translationKey: undefined,
  hideLabelOnEmpty: false,
  multiple: false,
  disabled: false,
  searchable: false,
  returnObject: false,
  nullable: false,
  paginated: false,
  noLabel: false,
  bigIcon: false,
});

const { t } = useI18n();

const id = ref<string>(uuidv4());

const visible = ref(false);

const search = ref<string | undefined>(undefined);

const page = ref(1);

const loading = ref(false);

const internalOptions = ref<TFilterGroupOption[]>([]);

const prompt = computed(() => {
  if (!props.multiple && selectedOptions.value.length > 0) {
    return selectedOptions.value[0].label;
  }

  if (props.translationKey) {
    if (props.nullable) {
      return t(`labels.${props.translationKey}.nullablePrompt`);
    }

    return t(`labels.${props.translationKey}.prompt`);
  }

  if (props.nullable) {
    return t(`labels.filterGroup.nullablePrompt`);
  }

  return t(`labels.filterGroup.prompt`);
});

const labelVisible = computed(
  () => !props.hideLabelOnEmpty || selectedOptions.value.length > 0
);

const innerLabel = computed(() => {
  if (props.label) {
    return props.label;
  }

  if (props.translationKey) {
    return t(`labels.${props.translationKey}.label`);
  }

  return t(`labels.filterGroup.${props.name}.label`);
});

const labelFor = computed(() => {
  if (props.searchable) {
    return `${props.name}-searchInput-${id}`;
  }

  return `${props.name}-options-${id}`;
});

const availableOptions = computed<TFilterGroupOption[]>(() =>
  sort(internalOptions.value)
);

const selectedOptions = computed(() => {
  if (props.multiple) {
    return availableOptions.value.filter(
      (item) => props.value && (props.value as string[]).includes(item.value)
    );
  }

  const selectedOption = availableOptions.value.find(
    (item) => item.value === props.value
  );

  return selectedOption ? [selectedOption] : [];
});

const filteredOptions = computed(() => {
  if (search.value) {
    return availableOptions.value.filter((item) =>
      item.label.toLowerCase().includes(String(search.value?.toLowerCase()))
    );
  }

  return availableOptions.value;
});

const cssClasses = computed(() => ({
  "has-error has-feedback": props.error,
}));

onMounted(() => {
  document.addEventListener("click", documentClick);

  id.value = uuidv4();

  if (props.options) {
    internalOptions.value = props.options;
  } else {
    fetchOptions();
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
  if (props.paginated && search.value) {
    page.value = 1;

    fetchOptions();
  }
};

const onSearch = (_event: Event) => {
  debounce(debouncedOnSearch, 500);
};

const infiniteLoading = ref<InstanceType<typeof InfiniteLoading> | null>(null);

const fetchOptions = async () => {
  if (!props.fetch) {
    return;
  }

  loading.value = true;

  const data = await props.fetch({
    page: page.value,
    search: search.value,
  });

  loading.value = false;

  if (infiniteLoading.value) {
    infiniteLoading.value.$emit("infinite-loading-reset");
  }

  if (data) {
    addOptions(data);
    fetchMissingOption();
  }
};

const fetchMissingOption = async () => {
  if (!props.fetch) {
    return;
  }

  if (
    !props.value ||
    (props.multiple &&
      selectedOptions.value.length === (props.value as string[]).length) ||
    (!props.multiple && selectedOptions.value[0].value === props.value)
  ) {
    return;
  }

  loading.value = true;

  const data = await props.fetch({ missing: props.value });

  loading.value = false;

  if (data) {
    addOptions(data);
  }
};

const fetchMore = async (stateChanger: StateChanger) => {
  loading.value = true;

  page.value += 1;

  const data = await props.fetch({ page: page.value });

  stateChanger.loaded();

  loading.value = false;

  if (data) {
    if (data.length === 0) {
      stateChanger.complete();
    }

    addOptions(data);
  }
};

const sort = (options: TFilterGroupOption[]) => {
  const sortedOptions = JSON.parse(JSON.stringify(options));
  return sortedOptions.sort((a: TFilterGroupOption, b: TFilterGroupOption) => {
    if (a.label < b.label) {
      return -1;
    }
    if (a.label > b.label) {
      return 1;
    }
    return 0;
  });
};

const addOptions = (newOptions: TFilterGroupOption[]) => {
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
    return (props.value || []).includes(option);
  }

  return props.value === option;
};

const emit = defineEmits(["input"]);

const select = (option: string) => {
  clearSearch();

  if (selected(option)) {
    if (props.multiple) {
      emit(
        "input",
        (props.value as string[]).filter((item: string) => item !== option)
      );
    } else if (props.nullable) {
      emit("input", null);
    }
  } else if (props.multiple) {
    const value = JSON.parse(JSON.stringify(props.value));

    value.push(option);

    emit("input", value);

    focusSearch();
  } else {
    emit("input", option);

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
  name: "FilterGroup2",
};
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
```
