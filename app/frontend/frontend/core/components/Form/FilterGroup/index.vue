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
      <FilterGroupOption
        v-for="(option, index) in selectedOptions"
        :key="`${groupID}-selected-${option.value}-${index}`"
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
      />
      <div class="filter-group-items">
        <FilterGroupOption
          v-for="(option, index) in filteredOptions"
          :key="`${groupID}-selected-${option.value}-${index}`"
          :option="option"
          :selected="selected(option)"
          :big-icon="bigIcon"
          :multiple="multiple"
          @select="select"
        />
      </div>
    </BCollapse>
  </div>
</template>

<script lang="ts" setup>
// import { BCollapse } from "bootstrap-vue";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import { v4 as uuidv4 } from "uuid";
import { useI18n } from "@/frontend/composables/useI18n";
import FilterGroupOption from "@/frontend/core/components/Form/FilterGroupOption/index.vue";
import type { TFilterGroupOption } from "@/frontend/core/components/Form/FilterGroupOption/index.vue";

type Props = {
  name: string;
  options: TFilterGroupOption[];
  value?: string | string[];
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
  value: undefined,
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
  if (!props.multiple) {
    const selectedOption = props.options.find(
      (item) => item.value === props.value
    )?.label;

    if (selectedOption) {
      return selectedOption;
    }
  }

  if (props.label) {
    return props.label;
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

  return t("labels.filterGroup.label");
});

const groupID = computed(() => {
  return `${props.name}-${uuidv4()}`;
});

const selectedOptions = computed(() => {
  if (props.multiple) {
    return props.options.filter((item) =>
      ((props.value || []) as string[]).includes(item.value)
    );
  }

  const selectedOption = props.options.find(
    (item) => item.value === props.value
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

const filterGroup = ref<HTMLElement | null>(null);

const documentClick = (event: Event) => {
  const target = event.target as HTMLElement;
  if (filterGroup.value !== target && !filterGroup.value?.contains(target)) {
    visible.value = false;
  }
};

const clearSearch = () => {
  search.value = "";
};

const selected = (option: TFilterGroupOption) => {
  if (props.multiple) {
    return ((props.value || []) as string[]).includes(option.value);
  }

  return props.value === option.value;
};

const emit = defineEmits(["input"]);

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
    const selectedValue = JSON.parse(JSON.stringify(props.value || []));
    selectedValue.push(option);
    emit("input", selectedValue);
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
  name: "FilterGroup",
};
</script>
