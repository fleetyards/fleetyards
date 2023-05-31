<template>
  <div ref="filterGroup" class="filter-group" :class="cssClasses">
    <transition name="fade">
      <label v-show="labelVisible" v-if="innerLabel && !noLabel" :for="id">
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
    <BCollapse
      v-if="multiple"
      :id="`${groupID}-${selectedId}`"
      :visible="selectedOptions.length > 0 && !visible"
      class="filter-group-items"
    >
      <FilterGroupOption
        v-for="(option, index) in selectedOptions"
        :key="`${groupID}-${selectedId}-${option.value}-${index}`"
        :option="option"
        :selected="selected(option)"
        :big-icon="bigIcon"
        :multiple="multiple"
        @select="select"
      />
    </BCollapse>
    <BCollapse
      :id="`${groupID}-${id}`"
      :visible="visible"
      class="filter-group-items-wrapper"
    >
      <FormInput
        v-if="searchable"
        id="search-input"
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
          :key="`${groupID}-${selectedId}-${option.value}-${index}`"
          :option="option"
          :selected="selected(option)"
          :big-icon="bigIcon"
          :multiple="multiple"
          @select="select"
        />

        <InfiniteLoading
          v-if="fetchedOptions.length && !search && paginated"
          ref="infiniteLoading"
          :distance="100"
          @infinite="fetchMore"
        >
          <template #no-more>
            <span />
          </template>
          <template #spinner>
            <span />
          </template>
        </InfiniteLoading>
      </div>
    </BCollapse>
  </div>
</template>

<script lang="ts" setup>
// import { BCollapse } from "bootstrap-vue";
import SmallLoader from "@/frontend/core/components/SmallLoader/index.vue";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import debounce from "lodash.debounce";
import InfiniteLoading from "vue-infinite-loading";
import type { StateChanger } from "vue-infinite-loading";
import { useI18n } from "@/frontend/composables/useI18n";
import { v4 as uuidv4 } from "uuid";
import type { TFilterData } from "@/frontend/composables/useFilters";
import FilterGroupOption from "@/frontend/core/components/Form/FilterGroupOption/index.vue";
import type { TFilterGroupOption } from "@/frontend/core/components/Form/FilterGroupOption/index.vue";
import type BaseCollection from "@/frontend/api/collections/Base";

export type TFilterGroupFetchParams = {
  search?: string;
  missing?: string | string[];
  page?: number;
  cacheId?: string;
};

type Props = {
  name: string;
  fetch: (params: TFilterGroupFetchParams) => Promise<TFilterGroupOption[]>;
  value?: string[] | string;
  multiple?: boolean;
  disabled?: boolean;
  searchable?: boolean;
  nullable?: boolean;
  error?: string;
  paginated?: boolean;
  hideLabelOnEmpty?: boolean;
  label?: string;
  translationKey?: string;
  noLabel?: boolean;
  bigIcon?: boolean;
  searchLabel?: string;
};

const props = withDefaults(defineProps<Props>(), {
  value: undefined,
  multiple: false,
  disabled: false,
  searchable: false,
  nullable: false,
  error: undefined,
  paginated: false,
  hideLabelOnEmpty: false,
  label: undefined,
  translationKey: "filterGroup",
  noLabel: false,
  bigIcon: false,
  searchLabel: undefined,
});

const { t } = useI18n();

const visible = ref(false);

const search = ref<string | undefined>();

const page = ref(1);

const loading = ref(false);

const selectedId = ref<string | null>(null);

const id = uuidv4();

const fetchedOptions = ref<TFilterGroupOption[]>([]);

const prompt = computed(() => {
  if (props.multiple) {
    return props.label;
  }

  if (selectedOptions.value.length > 0) {
    return selectedOptions.value[0].label;
  }

  if (props.nullable) {
    return t(`labels.${props.translationKey}.nullablePrompt`);
  }

  return t(`labels.${props.translationKey}.prompt`);
});

const labelVisible = computed(() => {
  return !props.hideLabelOnEmpty || selectedOptions.value.length > 0;
});

const innerLabel = computed(() => {
  if (props.label) {
    return props.label;
  }

  if (props.translationKey && props.translationKey !== "filterGroup") {
    return t(`labels.${props.translationKey}.label`);
  }

  return t(`labels.${id}`);
});

const groupID = computed(() => {
  return `${props.name}-${uuidv4()}`;
});

const availableOptions = computed(() => {
  if (props.paginated) {
    return sort(fetchedOptions.value);
  }
  return fetchedOptions.value;
});

const selectedOptions = computed(() => {
  if (props.multiple) {
    return availableOptions.value.filter(
      (item) => props.value && props.value.includes(item.value)
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
      item.label.toLowerCase().includes((search.value || "").toLowerCase())
    );
  }
  return availableOptions.value;
});

const cssClasses = computed(() => {
  return {
    "has-error has-feedback": props.error,
  };
});

watch(
  () => props.disabled,
  () => fetchOptions()
);

const queryParams = (args: {
  search?: string;
  missingValue?: string | string[];
  page?: number;
}) => {
  const query = {} as TFilterGroupFetchParams;
  if (args.search && props.searchable) {
    query.search = args.search;
  } else if (args.missingValue && props.paginated) {
    query.missing = args.missingValue;
  } else if (args.page && props.paginated) {
    query.page = args.page;
  }

  return query;
};

onBeforeMount(() => {
  selectedId.value = uuidv4();

  document.addEventListener("click", documentClick);
});

onMounted(() => {
  fetchOptions();
});

onUnmounted(() => {
  document.removeEventListener("click", documentClick);
});

const filterGroup = ref<HTMLElement | null>(null);

const documentClick = (event: Event) => {
  const element = filterGroup.value as HTMLElement;
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

const onSearch = debounce(debouncedOnSearch, 500);

const emit = defineEmits(["loaded", "input"]);

const infiniteLoading = ref<InstanceType<typeof InfiniteLoading> | null>(null);

const fetchOptions = async () => {
  if (props.disabled) {
    fetchMissingOption();
    return;
  }

  loading.value = true;

  const options = await props.fetch({
    ...queryParams({
      page: page.value,
      search: search.value,
    }),
    cacheId: groupID.value,
  });

  emit("loaded", options);

  loading.value = false;

  if (infiniteLoading.value) {
    infiniteLoading.value.stateChanger.reset();
  }

  if (options.length) {
    addOptions(options);
    fetchMissingOption();
  }
};

const fetchMissingOption = async () => {
  if (
    !props.value ||
    (props.multiple && selectedOptions.value.length === props.value.length) ||
    (!props.multiple && selectedOptions.value[0].value === props.value)
  ) {
    return;
  }

  loading.value = true;

  const options = await props.fetch({
    ...queryParams({
      missingValue: props.value,
    }),
    cacheId: `${groupID.value}-missing`,
  });

  loading.value = false;

  if (options.length) {
    addOptions(options);
  }
};

const fetchMore = async ($state: StateChanger) => {
  loading.value = true;
  page.value += 1;

  const options = await props.fetch({
    ...queryParams({
      page: page.value,
    }),
  });

  $state.loaded();

  loading.value = false;

  if (options.length) {
    addOptions(options);
  } else {
    $state.complete();
  }
};

const sort = (options: TFilterGroupOption[]) => {
  const sortedOptions = JSON.parse(
    JSON.stringify(options)
  ) as TFilterGroupOption[];
  return sortedOptions.sort((a, b) => {
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
    if (!availableOptions.value.find((option) => option.value === item.value)) {
      fetchedOptions.value.push(item);
    }
  });
};

const clearSearch = () => {
  search.value = undefined;
};

const selected = (option: TFilterGroupOption) => {
  if (props.multiple && props.value) {
    return props.value?.includes(option.value);
  }

  return props.value === option.value;
};

const select = (option: TFilterGroupOption) => {
  clearSearch();

  if (selected(option)) {
    if (props.multiple) {
      emit(
        "input",
        (props.value as string[]).filter((item) => item !== option.value)
      );
    } else if (props.nullable) {
      emit("input", null);
    }
  } else if (props.multiple) {
    const newSelected = JSON.parse(
      JSON.stringify(props.value || [])
    ) as string[];
    newSelected.push(option.value);
    emit("input", newSelected);
    focusSearch();
  } else {
    emit("input", option.value);
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
  name: "CollectionFilterGroup",
};
</script>
