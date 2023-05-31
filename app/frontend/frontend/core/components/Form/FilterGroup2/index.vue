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
      <i class="fa fa-chevron-right" />
    </div>
    <BCollapse
      v-if="multiple"
      :id="`${groupID}-selected`"
      :visible="selectedOptions.length > 0 && !visible"
      class="filter-group-items"
    >
      <a
        v-for="(option, index) in selectedOptions"
        :key="`${groupID}-selected-${option.value}-${index}`"
        :class="{
          active: selected(option.value),
          bigIcon,
        }"
        class="filter-group-item fade-list-item"
        @click="select(option.value)"
      >
        <div v-if="option.icon" class="filter-group-item-icon">
          <img :src="option.icon" alt="option-icon" />
        </div>
        <span v-html="option.label" />
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
        :placeholder="searchLabel || t('actions.find')"
        :label="t('actions.find')"
        class="filter-group-search"
        variant="clean"
        :no-label="true"
        :clearable="true"
        @input="onSearch"
      />
      <div class="filter-group-items">
        <a
          v-for="(option, index) in filteredOptions"
          :key="`${groupID}-${id}-${option.value}-${index}`"
          :class="{
            active: selected(option.value),
            bigIcon,
          }"
          class="filter-group-item fade-list-item"
          @click="select(returnObject ? option : option.value)"
        >
          <div v-if="option.icon" class="filter-group-item-icon">
            <img :src="option.icon" alt="option-icon" />
          </div>
          <span v-html="option.label" />
          <span v-if="multiple">
            <i class="fal fa-plus" />
          </span>
        </a>
      </div>
    </BCollapse>
  </div>
</template>

<script lang="ts" setup>
import { BCollapse } from "bootstrap-vue";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import { v4 as uuidv4 } from "uuid";
import { useI18n } from "@/frontend/composables/useI18n";

type TFilterGroupOption = {
  value: string | number;
  label: string;
  icon?: string;
};

type Props = {
  name: string;
  options: TFilterGroupOption[];
  modelValue?: TFilterGroupOption | TFilterGroupOption[];
  multiple?: boolean;
  disabled?: boolean;
  searchable?: boolean;
  error?: string;
  returnObject?: boolean;
  nullable?: boolean;
  hideLabelOnEmpty?: boolean;
  label?: string;
  noLabel?: boolean;
  bigIcon?: boolean;
  searchLabel?: string;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  multiple: false,
  disabled: false,
  searchable: false,
  error: undefined,
  returnObject: false,
  nullable: false,
  hideLabelOnEmpty: false,
  label: undefined,
  noLabel: false,
  bigIcon: false,
  searchLabel: undefined,
});

const visible = ref(false);

const search = ref<string>("");

const id = uuidv4();

const { t } = useI18n();

const prompt = computed(() => {
  if (props.multiple) {
    return props.label;
  }

  if (props.modelValue.length > 0) {
    return selectedOptions.value.at(0).label;
  }

  if (props.nullable) {
    return t(`labels.filterGroup.nullablePrompt`);
  }

  return t(`labels.filterGroup.prompt`);
});

const labelVisible = computed(() => {
  return !props.hideLabelOnEmpty || selectedOptions.value.length > 0;
});

const innerLabel = computed(() => {
  if (props.label) {
    return props.label;
  }

  return t(`labels.filterGroup.label`);
});

const groupID = computed(() => {
  return `${props.name}-${uuidv4()}`;
});

const selectedOptions = computed(() => {
  if (props.multiple) {
    return props.options.filter(
      (item) =>
        props.modelValue &&
        (props.modelValue as TFilterGroupOption[]).includes(item)
    );
  }
  const selectedOption = props.options.find(
    (item) => item.value === (props.modelValue as TFilterGroupOption).value
  );
  return selectedOption ? [selectedOption] : [];
});

const filteredOptions = computed(() => {
  if (search.value) {
    return props.options.filter((item) =>
      item.label.toLowerCase().includes(search.value.toLowerCase())
    );
  }

  return props.options;
});

const cssClasses = computed(() => {
  return {
    "has-error has-feedback": props.error,
  };
});

onMounted(() => {
  document.addEventListener("click", documentClick);
});

onUnmounted(() => {
  document.removeEventListener("click", documentClick);
});

const documentClick = (event: Event) => {
  // const element = this.$refs.filterGroup;
  // const { target } = event;
  // if (element !== target && !element.contains(target)) {
  //   visible.value = false;
  // }
};

const sort = (options: any[]) => {
  const sortedOptions = JSON.parse(JSON.stringify(options));
  return sortedOptions.sort((a: any, b: any) => {
    if (a.label < b.label) {
      return -1;
    }
    if (a.label > b.label) {
      return 1;
    }
    return 0;
  });
};

const clearSearch = () => {
  search.value = "";
};

const selected = (option: any) => {
  if (props.multiple) {
    return (
      props.modelValue &&
      (props.modelValue as TFilterGroupOption[]).includes(option)
    );
  }

  return props.modelValue === option;
};

const emit = defineEmits(["input"]);

const select = (option: any) => {
  clearSearch();

  if (selected(option)) {
    if (props.multiple) {
      emit(
        "input",
        (props.modelValue as TFilterGroupOption[]).filter(
          (item: any) => item !== option
        )
      );
    } else if (props.nullable) {
      emit("input", null);
    }
  } else if (props.multiple) {
    const selectedValue = JSON.parse(JSON.stringify(props.modelValue));
    selectedValue.push(option);
    emit("input", selectedValue);
    focusSearch();
  } else {
    emit("input", option);
    toggle();
  }
};

const unselect = (option: TFilterGroupOption) => {
  if (!props.modelValue) {
    return;
  }

  emit(
    "input",
    (props.modelValue as TFilterGroupOption[]).filter(
      (item: TFilterGroupOption) => item !== option
    )
  );
};

const toggle = () => {
  if (props.disabled) {
    return;
  }

  visible.value = !visible.value;
  focusSearch();
};

const searchInput = ref<HTMLInputElement | null>(null);

const focusSearch = () => {
  if (props.searchable && visible.value) {
    nextTick(() => {
      if (searchInput.value) {
        searchInput.value.focus();
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
