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
      <a
        v-for="(option, index) in selectedOptions"
        :key="`${groupID}-${selectedId}-${option[valueAttr]}-${index}`"
        :class="{
          active: selected(option[valueAttr]),
          bigIcon,
        }"
        class="filter-group-item fade-list-item"
        @click="select(option[valueAttr])"
      >
        <div v-if="option[iconAttr]" class="filter-group-item-icon">
          <img :src="option[iconAttr]" :alt="`icon-${iconAttr}`" />
        </div>
        <span v-html="option[labelAttr]" />
        <span v-if="multiple">
          <i class="fal fa-plus" />
        </span>
      </a>
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
        :placeholder="searchLabel || $t('actions.find')"
        :label="$t('actions.find')"
        class="filter-group-search"
        variant="clean"
        :no-label="true"
        :clearable="true"
        @input="onSearch"
      />
      <div class="filter-group-items">
        <a
          v-for="(option, index) in filteredOptions"
          :key="`${groupID}-${id}-${option[valueAttr]}-${index}`"
          :class="{
            active: selected(option[valueAttr]),
            bigIcon,
          }"
          class="filter-group-item fade-list-item"
          @click="select(returnObject ? option : option[valueAttr])"
        >
          <div v-if="option[iconAttr]" class="filter-group-item-icon">
            <img :src="option[iconAttr]" :alt="`icon-${iconAttr}`" />
          </div>
          <span v-html="option[labelAttr]" />
          <span v-if="multiple">
            <i class="fal fa-plus" />
          </span>
        </a>

        <InfiniteLoading
          v-if="shouldFetch && fetchedOptions.length && !search && paginated"
          ref="infiniteLoading"
          :distance="100"
          @infinite="fetchMore"
        >
          <span slot="no-more" />
          <span slot="spinner" />
        </InfiniteLoading>
      </div>
    </BCollapse>
  </div>
</template>

<script lang="ts" setup>
import { BCollapse } from "bootstrap-vue";
import SmallLoader from "@/frontend/core/components/SmallLoader/index.vue";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import { debounce } from "ts-debounce";
import InfiniteLoading from "vue-infinite-loading";
import { v4 as uuidv4 } from "uuid";
import { useI18n } from "@/frontend/composables/useI18n";

type Props = {
  name: string;
  options: any[];
  value?: string[] | string | number | any | null;
  valueAttr?: string;
  labelAttr?: string;
  iconAttr?: string;
  multiple?: boolean;
  disabled?: boolean;
  searchable?: boolean;
  error?: string;
  returnObject?: boolean;
  nullable?: boolean;
  paginated?: boolean;
  hideLabelOnEmpty?: boolean;
  label?: string;
  translationKey?: string;
  noLabel?: boolean;
  bigIcon?: boolean;
  fetch?: any;
  fetchPath?: string;
  searchLabel?: string;
  newSearchQuery?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  options: [],
  value: undefined,
  valueAttr: "value",
  labelAttr: "name",
  iconAttr: "icon",
  multiple: false,
  disabled: false,
  searchable: false,
  error: undefined,
  returnObject: false,
  nullable: false,
  paginated: false,
  hideLabelOnEmpty: false,
  label: undefined,
  translationKey: "filterGroup",
  noLabel: false,
  bigIcon: false,
  fetch: undefined,
  fetchPath: undefined,
  searchLabel: undefined,
  newSearchQuery: false,
});

const visible = ref(false);

const search = ref<string>("");

const page = ref(1);

const loading = ref(false);

const fetchedOptions = ref<any[]>([]);

const selectedId = ref<string>("");

const id = uuidv4();

const onSearch = debounce(debouncedOnSearch, 500);

const { t } = useI18n();

const prompt = computed(() => {
  if (props.multiple) {
    return props.label;
  }

  if (selectedOptions.value.length > 0) {
    return selectedOptions.value.at(0)[props.labelAttr];
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

const shouldFetch = computed(() => {
  return props.fetch || props.fetchPath;
});

const groupID = computed(() => {
  return `${props.name}-${uuidv4()}`;
});

const availableOptions = computed(() => {
  if (shouldFetch.value) {
    if (props.paginated) {
      return sort(fetchedOptions.value);
    }

    return fetchedOptions.value;
  }
  if (props.paginated) {
    return sort(props.options);
  }
  return props.options;
});

const selectedOptions = computed(() => {
  if (props.multiple) {
    return availableOptions.value.filter(
      (item) => props.value && props.value.includes(item[props.valueAttr])
    );
  }
  const selectedOption = availableOptions.value.find(
    (item) => item[props.valueAttr] === props.value
  );
  return selectedOption ? [selectedOption] : [];
});

const filteredOptions = computed(() => {
  if (search.value) {
    return availableOptions.value.filter((item) =>
      item[props.labelAttr].toLowerCase().includes(search.value.toLowerCase())
    );
  }
  return availableOptions.value;
});

const cssClasses = computed(() => {
  return {
    "has-error has-feedback": props.error,
  };
});

onMounted(() => {
  document.addEventListener("click", documentClick);

  selectedId.value = uuidv4();

  if (shouldFetch.value) {
    fetchOptions();
  }
});

onUnmounted(() => {
  document.removeEventListener("click", documentClick);
});

const documentClick = (event: Event) => {
  const element = this.$refs.filterGroup;
  const { target } = event;

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

const internalFetch = (args) => {
  if (props.fetch) {
    return props.fetch(args);
  }

  let query = buildQuery(args);
  if (props.newSearchQuery) {
    query = buildNewQuery(args);
  }

  return this.$api.get(props.fetchPath, query);
};

const buildQuery = (args) => {
  const query = {
    q: {},
  };
  if (args.search && this.searchable) {
    query.q.nameCont = args.search;
  } else if (args.missingValue && this.paginated) {
    query.q.nameIn = args.missingValue;
  } else if (args.page && this.paginated) {
    query.page = args.page;
  }

  return query;
};

const buildNewQuery = (args) => {
  const query = {
    filters: {},
  };
  if (args.search && props.searchable) {
    query.search = args.search;
  } else if (args.missingValue && props.paginated) {
    query.filters.name = args.missingValue;
  } else if (args.page && props.paginated) {
    query.page = args.page;
  }
};

const infiniteLoading = ref<HTMLElement | null>(null);

const fetchOptions = async () => {
  if (!shouldFetch.value) {
    return;
  }

  loading.value = true;

  const response = await internalFetch({
    page: page.value,
    search: search.value,
  });

  loading.value = false;

  if (infiniteLoading.value) {
    infiniteLoading.value.$emit("infinite-loading-reset");
  }

  if (!response.error) {
    addOptions(response.data);
    fetchMissingOption();
  }
};

const fetchMissingOption = async () => {
  if (
    !props.value ||
    (props.multiple && this.selectedOptions.length === props.value.length) ||
    (!props.multiple && this.selectedOptions[0] === props.value)
  ) {
    return;
  }

  loading.value = true;

  const response = await internalFetch({ missingValue: props.value });

  loading.value = false;

  if (!response.error) {
    addOptions(response.data);
  }
};

const fetchMore = async ($state) => {
  loading.value = true;

  page.value += 1;

  const response = await internalFetch({ page: page.value });

  $state.loaded();

  loading.value = false;

  if (!response.error) {
    if (response.data.length === 0) {
      $state.complete();
    }
    addOptions(response.data);
  }
};

const sort = (options: any[]) => {
  const sortedOptions = JSON.parse(JSON.stringify(options));
  return sortedOptions.sort((a: any, b: any) => {
    if (a[props.labelAttr] < b[props.labelAttr]) {
      return -1;
    }
    if (a[props.labelAttr] > b[props.labelAttr]) {
      return 1;
    }
    return 0;
  });
};

const addOptions = (newOptions: any[]) => {
  newOptions.forEach((item: any) => {
    if (
      !availableOptions.value.find(
        (option: any) => option[props.valueAttr] === item[props.valueAttr]
      )
    ) {
      fetchedOptions.value.push(item);
    }
  });
};

const clearSearch = () => {
  search.value = "";
};

const selected = (option: any) => {
  if (props.multiple) {
    return props.value && props.value.includes(option);
  }

  return props.value === option;
};

const emit = defineEmits(["input"]);

const select = (option: any) => {
  clearSearch();

  if (selected(option)) {
    if (props.multiple) {
      emit(
        "input",
        props.value.filter((item: any) => item !== option)
      );
    } else if (props.nullable) {
      emit("input", null);
    }
  } else if (props.multiple) {
    const selectedValue = JSON.parse(JSON.stringify(props.value));
    selectedValue.push(option);
    emit("input", selectedValue);
    focusSearch();
  } else {
    emit("input", option);
    toggle();
  }
};

const unselect = (option: any) => {
  emit(
    "input",
    props.value.filter((item: any) => item !== option)
  );
};

const toggle = () => {
  if (props.disabled) {
    return;
  }

  visible.value = !visible.value;
  focusSearch();
};

const focusSearch = () => {
  if (props.searchable && visible.value) {
    this.$nextTick(() => {
      if (this.$refs.searchInput) {
        this.$refs.searchInput.setFocus();
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
