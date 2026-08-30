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
import debounce from "lodash.debounce";
import { v4 as uuidv4 } from "uuid";
import { FilterGroupSizesEnum } from "./types";
import Option from "./Option/index.vue";
import {
  UseQueryReturnType,
  keepPreviousData,
  useQuery,
} from "@tanstack/vue-query";
import { type BaseList, type FilterOption } from "@/services/fyApi";
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
  nullable?: boolean;
  paginated?: boolean;
  noLabel?: boolean;
  bigIcon?: boolean;
  hideSelected?: boolean;
  inline?: boolean;
  size?: `${FilterGroupSizesEnum}`;
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
  nullable: true,
  paginated: false,
  noLabel: false,
  bigIcon: false,
  hideSelected: false,
  inline: false,
  size: FilterGroupSizesEnum.DEFAULT,
});

type FilterOptionValue = FilterOption["value"];

const { t, tExists } = useI18n();

const id = ref<string>(uuidv4());

const visible = ref(false);

const fetchMoreVisible = ref(props.paginated);

const search = ref<string | undefined>();

const missing = ref<ValueType<T> | undefined>();

const page = ref(1);

const internalOptions = ref<FilterOption[]>([]);

const internalValue = ref<ValueType<T> | undefined>(props.modelValue);

watch(
  () => props.modelValue,
  () => {
    internalValue.value = props.modelValue;
  },
);

const prompt = computed(() => {
  if (!props.multiple && selectedOptions.value.length > 0) {
    return selectedOptions.value[0].label;
  }

  /*
   * A multi-select used to fall straight through to the generic prompt, so a
   * group with two things chosen still read "No Option selected" and the only
   * place the selection appeared was the list below. That is wrong in any
   * layout and plainly wrong once the popover detaches.
   */
  if (props.multiple && selectedOptions.value.length > 0) {
    return t("filterGroup.labels.selectedCount", {
      count: selectedOptions.value.length,
    });
  }

  if (props.translationKey) {
    if (props.nullable) {
      if (tExists(`filterGroup.${props.translationKey}.nullablePrompt`)) {
        return t(`filterGroup.${props.translationKey}.nullablePrompt`);
      } else {
        return t(`filterGroup.labels.nullablePrompt`);
      }
    }

    if (tExists(`filterGroup.${props.translationKey}.prompt`)) {
      return t(`filterGroup.${props.translationKey}.prompt`);
    } else {
      return t(`filterGroup.labels.prompt`);
    }
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

/* eslint-disable @tanstack/query/exhaustive-deps */
const { isLoading, isFetching, data, refetch } = useQuery({
  refetchOnWindowFocus: false,
  queryKey: [
    "filterGroupOptions",
    id.value,
    props.name,
    page.value,
    search.value,
    missing.value as unknown,
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
/* eslint-enable @tanstack/query/exhaustive-deps */

watch(
  () => data.value,
  async () => {
    if (data.value) {
      addOptions(data.value);
      await fetchMissingOption();
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
    return t(`filterGroup.${props.translationKey}.label`);
  }

  return t(`filterGroup.${props.name}.label`);
});

const triggerId = computed(() => `${props.name}-trigger-${id.value}`);

const listboxId = computed(() => `${props.name}-listbox-${id.value}`);

const optionId = (index: number) => `${listboxId.value}-option-${index}`;

/*
 * The label points at a real control now. It used to point at the collapsed
 * container's id -- a div -- for every group that is not searchable, which is
 * 68 of the component's 135 call sites: clicking the label did nothing and a
 * screen reader announced nothing.
 */
const labelFor = computed(() => {
  if (props.searchable) {
    return `${props.name}-searchInput-${id.value}`;
  }

  return triggerId.value;
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
        internalValue.value &&
        (internalValue.value as FilterOptionValue[]).includes(item.value),
    );
  }

  const selectedOption = availableOptions.value.find(
    (item) => item.value === internalValue.value,
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
  inline: props.inline,
  "filter-group--medium": props.size === FilterGroupSizesEnum.MEDIUM,
}));

/*
 * The visually pointed-at row. Focus itself never leaves the trigger (or the
 * search box), so this is carried as an index and published through
 * aria-activedescendant rather than by moving focus into the list.
 */
const activeIndex = ref(-1);

const activeOption = computed(() => filteredOptions.value[activeIndex.value]);

const activeDescendant = computed(() =>
  visible.value && activeIndex.value >= 0
    ? optionId(activeIndex.value)
    : undefined,
);

// A list that shrank under the cursor -- by a search, or a page of results
// arriving -- must not leave the pointer past its end.
watch(filteredOptions, () => {
  if (activeIndex.value >= filteredOptions.value.length) {
    activeIndex.value = filteredOptions.value.length - 1;
  }
});

const moveActive = (delta: number) => {
  const count = filteredOptions.value.length;

  if (count === 0) {
    activeIndex.value = -1;
    return;
  }

  activeIndex.value =
    activeIndex.value < 0
      ? delta > 0
        ? 0
        : count - 1
      : (activeIndex.value + delta + count) % count;

  void scrollActiveIntoView();
};

const scrollActiveIntoView = async () => {
  await nextTick();

  if (activeIndex.value < 0 || !filterGroup.value) {
    return;
  }

  filterGroup.value
    .querySelector(`#${CSS.escape(optionId(activeIndex.value))}`)
    ?.scrollIntoView({ block: "nearest" });
};

/*
 * Type-ahead, for the groups that are not searchable. A native select gives
 * this for free; a custom combobox has to pay it back, and without it the only
 * way through the longer lists -- manufacturers, star systems -- is fifty
 * arrow presses.
 */
const typeAheadBuffer = ref("");

let typeAheadTimer: ReturnType<typeof setTimeout> | undefined;

const typeAhead = (character: string) => {
  clearTimeout(typeAheadTimer);
  typeAheadBuffer.value += character.toLowerCase();
  typeAheadTimer = setTimeout(() => {
    typeAheadBuffer.value = "";
  }, 500);

  const match = filteredOptions.value.findIndex((option) =>
    option.label.toLowerCase().startsWith(typeAheadBuffer.value),
  );

  if (match >= 0) {
    activeIndex.value = match;
    void scrollActiveIntoView();
  }
};

const focusTrigger = async () => {
  await nextTick();
  trigger.value?.focus();
};

const close = (returnFocus = false) => {
  visible.value = false;
  activeIndex.value = -1;

  if (returnFocus) {
    void focusTrigger();
  }
};

const onKeydown = async (event: KeyboardEvent) => {
  if (props.disabled) {
    return;
  }

  switch (event.key) {
    case "ArrowDown":
    case "ArrowUp": {
      event.preventDefault();

      if (!visible.value) {
        await toggle();
        activeIndex.value = event.key === "ArrowDown" ? 0 : -1;
        if (event.key === "ArrowUp") moveActive(-1);
        return;
      }

      moveActive(event.key === "ArrowDown" ? 1 : -1);
      return;
    }
    case "Home":
    case "End": {
      if (!visible.value) {
        return;
      }

      event.preventDefault();
      activeIndex.value =
        event.key === "Home" ? 0 : filteredOptions.value.length - 1;
      void scrollActiveIntoView();
      return;
    }
    case "Enter": {
      event.preventDefault();

      if (!visible.value) {
        await toggle();
        return;
      }

      if (activeOption.value) {
        await select(activeOption.value.value);
      }
      return;
    }
    case " ": {
      // In a searchable group a space is a character, not a command.
      if (props.searchable) {
        return;
      }

      event.preventDefault();

      if (!visible.value) {
        await toggle();
        return;
      }

      if (activeOption.value) {
        await select(activeOption.value.value);
      }
      return;
    }
    case "Escape": {
      if (!visible.value) {
        return;
      }

      event.preventDefault();
      close(true);
      return;
    }
    case "Tab": {
      close();
      return;
    }
    default: {
      if (
        !props.searchable &&
        event.key.length === 1 &&
        !event.metaKey &&
        !event.ctrlKey &&
        !event.altKey
      ) {
        if (!visible.value) {
          await toggle();
        }
        typeAhead(event.key);
      }
    }
  }
};

// A pointer click outside already closes the group; this is the same rule for
// focus, so tabbing out of an open group does not leave the popover hanging.
const onFocusout = (event: FocusEvent) => {
  const next = event.relatedTarget as Node | null;

  if (next && filterGroup.value?.contains(next)) {
    return;
  }

  close();
};

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

const trigger = ref<HTMLButtonElement | null>(null);

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

const debouncedOnSearch = async () => {
  if (search.value) {
    page.value = 1;

    await refetch();
  }
};

const onSearch = debounce(debouncedOnSearch, 500);

const fetchMissingOption = async () => {
  if (
    !internalValue.value ||
    (props.multiple &&
      selectedOptions.value.length ===
        (internalValue.value as string[]).length) ||
    (!props.multiple && selectedOptions.value[0]?.value === internalValue.value)
  ) {
    return;
  }

  missing.value = internalValue.value as string;

  await refetch();
};

const fetchMore = async () => {
  page.value += 1;

  await refetch();
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

const selected = (option: FilterOptionValue) => {
  if (props.multiple) {
    return ((internalValue.value as FilterOptionValue[]) || []).includes(
      option,
    );
  }

  return internalValue.value === option;
};

const emits = defineEmits(["update:modelValue"]);

const select = async (optionValue: FilterOptionValue) => {
  clearSearch();

  if (selected(optionValue)) {
    if (props.multiple) {
      emits(
        "update:modelValue",
        (internalValue.value as string[]).filter(
          (item: string) => item !== optionValue,
        ),
      );
    } else if (props.nullable) {
      emits("update:modelValue", null);
    }
  } else if (props.multiple) {
    const values: FilterOptionValue[] = JSON.parse(
      JSON.stringify(internalValue.value || []),
    );

    values.push(optionValue);

    emits("update:modelValue", values);

    await focusSearch();
  } else {
    emits("update:modelValue", optionValue);

    await toggle();
  }
};

const toggle = async () => {
  if (props.disabled) {
    return;
  }

  visible.value = !visible.value;

  await focusSearch();
};

const searchInput = ref<InstanceType<typeof FormInput> | null>(null);

const focusSearch = async () => {
  if (props.searchable && visible.value) {
    await nextTick(() => {
      if (searchInput.value) {
        /*
         * preventScroll matters here. The popover is still collapsed when this
         * runs -- Collapsed animates its height from 0 under overflow: hidden --
         * and an overflow: hidden box is still programmatically scrollable, so
         * focusing the field made the browser scroll it into view inside a box
         * of almost no height. That pushed the whole popover's content up behind
         * the trigger, and it unwound over the next 500ms as the box grew, which
         * read as the popover starting halfway under the control.
         *
         * Measured: scrollTop 21, content at -21px, against 0 and 0 with this.
         */
        searchInput.value.setFocus({ preventScroll: true });
      }
    });
  }
};

const clear = () => {
  internalValue.value = undefined;
};

const reset = () => {
  clear();
  clearSearch();
};

defineExpose({
  reset,
  clear,
  clearSearch,
});
</script>

<template>
  <div
    ref="filterGroup"
    class="filter-group"
    :class="cssClasses"
    :data-test="`filter-group-${name}`"
    @keydown="onKeydown"
    @focusout="onFocusout"
  >
    <transition name="fade">
      <label
        v-show="labelVisible"
        v-if="innerLabel && !noLabel"
        :for="labelFor"
      >
        {{ innerLabel }}
      </label>
    </transition>
    <button
      :id="triggerId"
      ref="trigger"
      v-tooltip.right="error"
      type="button"
      role="combobox"
      aria-haspopup="listbox"
      :aria-expanded="visible"
      :aria-controls="listboxId"
      :aria-activedescendant="activeDescendant"
      :disabled="disabled"
      :class="{
        active: visible,
        disabled,
        selected: selectedOptions.length > 0,
        hasLabel: labelVisible,
      }"
      class="filter-group-title"
      data-test="filter-group-title"
      @click="toggle"
    >
      <span class="filter-group-title-prompt">
        {{ prompt }}
      </span>
      <SmallLoader v-if="props.queryFn" :loading="loading" />
      <i class="fa fa-chevron-right" />
    </button>
    <Collapsed
      v-if="multiple && !hideSelected"
      :id="`${name}-selected-${id}`"
      :visible="selectedOptions.length > 0 && !visible"
      class="filter-group-selected"
    >
      <!--
        Same shape as the popover below, and for the same reason: Collapsed
        animates this element's height and drives its margin, padding and border
        to zero for the duration, so anything framing the segment -- including
        the gap that stands it off the trigger -- has to sit inside it or it
        snaps in at the end.
      -->
      <div class="filter-group-surface">
        <div class="filter-group-items">
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
        </div>
      </div>
    </Collapsed>
    <Collapsed
      :id="`${name}-options-${id}`"
      :visible="visible"
      class="filter-group-items-wrapper"
    >
      <!--
        Collapsed animates this wrapper's height, and its keyframes drive
        padding, border and margin to zero for the duration (it reads inline
        styles, which a stylesheet never sets, so the end keyframe resolves to
        0). Anything framing the popover therefore has to sit *inside* the
        animated element, or it stays collapsed for 500ms and snaps in at the
        end.
      -->
      <div class="filter-group-surface">
        <FormInput
          v-if="searchable"
          ref="searchInput"
          :id="labelFor"
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
          <div
            :id="listboxId"
            role="listbox"
            :aria-multiselectable="multiple"
            :aria-labelledby="triggerId"
          >
            <Option
              v-for="(option, index) in filteredOptions"
              :key="`${name}-options-${id}-${option.value}-${index}`"
              :option="option"
              :option-id="optionId(index)"
              :in-listbox="true"
              :active="index === activeIndex"
              :selected="selected(option.value)"
              :big-icon="bigIcon"
              :multiple="multiple"
              :nullable="nullable"
              @select="select(option.value)"
            />
          </div>

          <Btn
            v-if="fetchMoreVisible && paginated"
            :disabled="loading"
            class="fade-list-item filter-group-fetch-more"
            @click="fetchMore"
            :variant="BtnVariantsEnum.BARE"
            >{{ t("filterGroup.actions.fetchMore") }}</Btn
          >
        </div>
      </div>
    </Collapsed>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
