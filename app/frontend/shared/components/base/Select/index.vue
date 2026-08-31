<script lang="ts">
export default {
  name: "BaseSelect",
};
</script>

<script lang="ts" setup generic="T">
import Collapsed from "@/shared/components/Collapsed.vue";
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import debounce from "lodash.debounce";
import { v4 as uuidv4 } from "uuid";
import { BaseSelectSizesEnum, BaseSelectVariantsEnum } from "./types";
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

export interface BaseSelectOption<T> extends FilterOption {
  object: T;
}

export type ValueType<T> =
  | BaseSelectOption<T>
  | BaseSelectOption<T>[]
  | string[]
  | string
  | number[]
  | number
  | boolean
  | null;

export type BaseSelectParams<T> = {
  search?: string;
  missing?: ValueType<T>;
  page?: number;
};

type Props = {
  name: string;
  query?: (
    params: BaseSelectParams<T>,
  ) => UseQueryReturnType<FilterOption[], Error>;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  queryFn?: (params: BaseSelectParams<T>) => Promise<any>;
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
  size?: `${BaseSelectSizesEnum}`;
  variant?: `${BaseSelectVariantsEnum}`;
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
  size: BaseSelectSizesEnum.DEFAULT,
  variant: BaseSelectVariantsEnum.DEFAULT,
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
    return t("baseSelect.labels.selectedCount", {
      count: selectedOptions.value.length,
    });
  }

  if (props.translationKey) {
    if (props.nullable) {
      if (tExists(`baseSelect.${props.translationKey}.nullablePrompt`)) {
        return t(`baseSelect.${props.translationKey}.nullablePrompt`);
      } else {
        return t(`baseSelect.labels.nullablePrompt`);
      }
    }

    if (tExists(`baseSelect.${props.translationKey}.prompt`)) {
      return t(`baseSelect.${props.translationKey}.prompt`);
    } else {
      return t(`baseSelect.labels.prompt`);
    }
  }

  if (props.noLabel && props.label) {
    return props.label;
  }

  if (props.nullable) {
    return t(`baseSelect.labels.nullablePrompt`);
  }

  return t(`baseSelect.labels.prompt`);
});

/*
 * The name for assistive tech, whenever the visible label is not the thing
 * naming the trigger.
 *
 * Two ways it was not. 27 call sites pass `no-label`, which stops the label
 * element being rendered at all; and when the select is `searchable` the label's
 * `for` points at the search box instead, so the trigger was unnamed there too.
 * Its own text is the current selection, which names the value rather than the
 * control.
 *
 * Omitted when the label does name it, so the two cannot compete.
 */
const triggerNamedByLabel = computed(
  () =>
    Boolean(innerLabel.value) &&
    !props.noLabel &&
    labelVisible.value &&
    !props.searchable,
);

const triggerLabel = computed(() =>
  triggerNamedByLabel.value ? undefined : innerLabel.value || undefined,
);

const loading = computed(() => {
  return isLoading.value || isFetching.value;
});

/* eslint-disable @tanstack/query/exhaustive-deps */
const { isLoading, isFetching, data, refetch } = useQuery({
  refetchOnWindowFocus: false,
  queryKey: [
    "baseSelectOptions",
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
    return t(`baseSelect.${props.translationKey}.label`);
  }

  return t(`baseSelect.${props.name}.label`);
});

const triggerId = computed(() => `${props.name}-trigger-${id.value}`);

const listboxId = computed(() => `${props.name}-listbox-${id.value}`);

const errorId = computed(() => `${props.name}-error-${id.value}`);

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
  return t("baseSelect.labels.search");
});

/*
 * Declared above availableOptions on purpose: a const is in its temporal dead
 * zone until the line that defines it runs, and the watcher on filteredOptions
 * evaluates that chain during setup. Defined below, this threw
 * "Cannot access 'sort' before initialization" and nothing mounted.
 */
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

/*
 * Sorted, which it was not. `sort()` ran in availableOptions, but the popover
 * renders this -- so the selected rows came out alphabetical and the options a
 * user picks from stayed in whatever order the API returned them. Two lists in
 * one popover, ordered differently, from one sort that only half-ran.
 */
const filteredOptions = computed(() => {
  if (search.value) {
    return availableOptions.value.filter((item) =>
      item.label.toLowerCase().includes(String(search.value?.toLowerCase())),
    );
  }

  return availableOptions.value;
});

const cssClasses = computed(() => ({
  "base-select--with-error": !!props.error,
  inline: props.inline,
  "base-select--medium": props.size === BaseSelectSizesEnum.MEDIUM,
  "base-select--affix": props.variant === BaseSelectVariantsEnum.AFFIX,
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

  if (activeIndex.value < 0 || !baseSelect.value) {
    return;
  }

  baseSelect.value
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

  if (next && baseSelect.value?.contains(next)) {
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
  stopFollowing();
});

const baseSelect = ref<HTMLElement | null>(null);

const trigger = ref<HTMLButtonElement | null>(null);

/*
 * A popover only has to be taken out of the layout when something would clip
 * it. Walking up for a scroller answers that, and the answer decides which of
 * the two modes it opens in.
 *
 * `hidden` and `clip` count alongside `auto` and `scroll`: a modal body is
 * `overflow: hidden auto`, and it was the hidden half of that pair that cut the
 * options off.
 */
const clippingAncestor = (element: HTMLElement) => {
  let node = element.parentElement;

  while (node && node !== document.body && node !== document.documentElement) {
    const style = window.getComputedStyle(node);

    if (
      /(auto|scroll|hidden|clip)/.test(
        `${style.overflow}${style.overflowX}${style.overflowY}`,
      )
    ) {
      return node;
    }

    node = node.parentElement;
  }

  return null;
};

const escapesClip = ref(false);
const opensAbove = ref(false);

/*
 * Puts the popover where it belongs, and -- only when asked -- reconsiders which
 * side of the trigger it opens on.
 *
 * The two are separate because they want different rhythms. Where it is has to
 * keep up with a scroll, frame by frame, in the fixed mode. Which side it is on
 * must not: re-deciding that per frame flips the popover over the trigger while
 * someone is reading it. So the side is settled on opening, when the group or
 * its options resize, and once a scroll has come to rest.
 */
const placePopover = (decideSide = false) => {
  const root = baseSelect.value;
  const anchor = root?.querySelector(".base-select-popover-anchor");
  const popover = root?.querySelector<HTMLElement>(
    ".base-select-items-wrapper",
  );

  if (!root || !anchor || !popover) {
    return;
  }

  // Measured, not assumed: the popover does not always hang off the trigger --
  // a multi-select puts the chosen options in between.
  const place = anchor.getBoundingClientRect();

  /*
   * Collapsed animates the wrapper, not the surface inside it, so the surface
   * has its full height from the first frame -- measuring the wrapper would
   * read whatever the animation is currently at. The gap is read from the
   * stylesheet for the same reason it is not written twice.
   */
  const surface = popover.querySelector<HTMLElement>(".base-select-surface");
  const gap = surface
    ? parseFloat(window.getComputedStyle(surface).marginTop) ||
      parseFloat(window.getComputedStyle(surface).marginBottom) ||
      0
    : 0;
  const height = (surface?.getBoundingClientRect().height ?? 0) + gap;

  const triggerRect = trigger.value?.getBoundingClientRect();
  const fitsBelow = place.top + height <= window.innerHeight;
  const fitsAbove = triggerRect != null && triggerRect.top - height >= 0;

  if (decideSide) {
    opensAbove.value = !fitsBelow && fitsAbove;
  }

  if (!escapesClip.value) {
    /*
     * Absolute: the stylesheet owns left and right, and the downward position is
     * the element's own place in the flow. Only opening upwards needs saying,
     * and it is said as an offset from the group's box -- which is what the
     * containing block is -- rather than as a coordinate.
     *
     * The other mode's coordinates come off first. They are viewport offsets and
     * they mean something else entirely against the group's box, and a select is
     * measured in both modes over its life -- one inside a modal escapes the clip
     * while the modal is open and not once it has gone. Left on, they open the
     * popover far down and to the right of its trigger.
     */
    popover.style.removeProperty("top");
    popover.style.removeProperty("left");
    popover.style.removeProperty("width");

    if (opensAbove.value && triggerRect) {
      popover.style.bottom = `${root.getBoundingClientRect().bottom - triggerRect.top}px`;
    } else {
      popover.style.removeProperty("bottom");
    }

    return;
  }

  /*
   * Fixed: a fixed element resolves against the viewport only while no ancestor
   * is transformed, and an open modal dialog is, which makes it the containing
   * block. Parking the popover at 0/0 and reading where it landed gives that
   * offset, whatever it turns out to be. Two synchronous writes, never painted
   * between -- an earlier version awaited a tick in the middle, which showed as
   * a frame in the top-left corner on every scroll event.
   */
  // Set only by the absolute mode, and a fixed box given both ends stretches
  // between them instead of taking its height from its content.
  popover.style.removeProperty("bottom");

  popover.style.top = "0px";
  popover.style.left = "0px";

  const origin = popover.getBoundingClientRect();
  const top =
    opensAbove.value && triggerRect ? triggerRect.top - height : place.top;

  popover.style.top = `${top - origin.top}px`;
  popover.style.left = `${place.left - origin.left}px`;
  /*
   * The affix variant is as narrow as a unit label, so its popover takes its
   * width from its options instead -- see the stylesheet. Every other select
   * matches its trigger.
   */
  if (props.variant === BaseSelectVariantsEnum.AFFIX) {
    popover.style.removeProperty("width");
  } else {
    popover.style.width = `${place.width}px`;
  }
};

let followGroup: ResizeObserver | null = null;
let queuedFrame: number | null = null;

// Scroll fires off the compositor's own cadence, so repositioning straight from
// the handler can land mid-frame. Folding every burst into one update on the
// next frame is as close as a scripted position gets to keeping up.
const followPopover = () => {
  if (queuedFrame !== null) {
    return;
  }

  queuedFrame = window.requestAnimationFrame(() => {
    queuedFrame = null;
    placePopover();
  });
};

/*
 * The side, re-checked after the scrolling stops. Scrolling changes how much
 * room is left below the trigger, so a popover that opened downwards can end up
 * hanging off the bottom of the window -- but moving it while the scroll is
 * still running is the flip nobody asked for. Waiting for the rest gives both.
 */
const reconsiderSide = debounce(() => placePopover(true), 150);

const stopFollowing = () => {
  window.removeEventListener("scroll", followPopover, true);
  window.removeEventListener("scroll", reconsiderSide, true);
  window.removeEventListener("resize", reconsiderSide);
  reconsiderSide.cancel();
  followGroup?.disconnect();
  followGroup = null;

  if (queuedFrame !== null) {
    window.cancelAnimationFrame(queuedFrame);
    queuedFrame = null;
  }
};

watch(visible, async (isVisible) => {
  if (!isVisible) {
    stopFollowing();

    /*
     * The mode is deliberately left standing. Collapsed animates the close over
     * its own duration, and dropping --escapes-clip here handed a popover still
     * carrying fixed coordinates back to `position: absolute`, which read them
     * against the group's box and threw it into the bottom-right corner for the
     * length of the animation. Both flags are recomputed on open below.
     */
    return;
  }

  const root = baseSelect.value;

  // Reset here rather than on close, where it would flip the mode out from under
  // the closing animation. placePopover() settles it again a tick from now.
  opensAbove.value = false;
  escapesClip.value = root != null && clippingAncestor(root) != null;

  await nextTick();

  placePopover(true);

  window.addEventListener("resize", reconsiderSide);

  // Both modes reconsider the side once a scroll settles; `true` catches the
  // scrollers on the way up, which do not bubble.
  window.addEventListener("scroll", reconsiderSide, true);

  /*
   * Only the fixed popover is carried by the script, so only it has to be
   * dragged along a scroll frame by frame. The absolute one is laid out with
   * the page and follows it exactly by doing nothing, which is the whole reason
   * it is the default.
   */
  if (escapesClip.value) {
    window.addEventListener("scroll", followPopover, true);
  }

  /*
   * Two things move under an open popover: a multi-select collapses its chosen
   * options as it opens, over half a second, and a page of results can arrive
   * after it. Both change where the popover belongs and whether it still fits
   * below -- measuring once on open left it starting under the chosen options
   * until a scroll happened to move it.
   *
   * The callback never resizes what it observes: it moves a popover that is out
   * of flow either way.
   *
   * Guarded on availability -- the browserslist still reaches KaiOS 2.5, which
   * has no ResizeObserver, and jsdom defines none either. Without it the popover
   * still opens in the right place; it just does not follow.
   */
  if (typeof ResizeObserver === "undefined" || !root) {
    return;
  }

  // eslint-disable-next-line compat/compat -- guarded above
  followGroup = new ResizeObserver(() => placePopover(true));
  followGroup.observe(root);

  const surface = root.querySelector(".base-select-surface");

  if (surface) {
    followGroup.observe(surface);
  }
});

const documentClick = (event: Event) => {
  if (!baseSelect.value) {
    return;
  }

  const element = baseSelect.value;
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
    ref="baseSelect"
    class="base-select"
    :class="cssClasses"
    :data-test="`base-select-${name}`"
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
      type="button"
      role="combobox"
      :aria-label="triggerLabel"
      :aria-invalid="!!error || undefined"
      :aria-describedby="error ? errorId : undefined"
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
      class="base-select-title"
      data-test="base-select-title"
      @click="toggle"
    >
      <span class="base-select-title-prompt">
        {{ prompt }}
      </span>
      <SmallLoader v-if="props.queryFn" :loading="loading" />
      <i class="fa fa-chevron-down" />
    </button>
    <Collapsed
      v-if="multiple && !hideSelected"
      :id="`${name}-selected-${id}`"
      :visible="selectedOptions.length > 0 && !visible"
      class="base-select-selected"
    >
      <!--
        Same shape as the popover below, and for the same reason: Collapsed
        animates this element's height and drives its margin, padding and border
        to zero for the duration, so anything framing the segment -- including
        the gap that stands it off the trigger -- has to sit inside it or it
        snaps in at the end.
      -->
      <div class="base-select-surface">
        <div class="base-select-items">
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
    <div class="base-select-popover-anchor" aria-hidden="true" />
    <Collapsed
      :id="`${name}-options-${id}`"
      :visible="visible"
      class="base-select-items-wrapper"
      :class="{
        'base-select-items-wrapper--escapes-clip': escapesClip,
        'base-select-items-wrapper--above': opensAbove,
      }"
    >
      <!--
        Collapsed animates this wrapper's height, and its keyframes drive
        padding, border and margin to zero for the duration (it reads inline
        styles, which a stylesheet never sets, so the end keyframe resolves to
        0). Anything framing the popover therefore has to sit *inside* the
        animated element, or it stays collapsed for 500ms and snaps in at the
        end.
      -->
      <div class="base-select-surface">
        <FormInput
          v-if="searchable"
          ref="searchInput"
          :id="labelFor"
          v-model="search"
          :name="`${name}-searchInput-${id}`"
          :placeholder="searchPlaceholder"
          :label="searchLabelFallback"
          class="base-select-search"
          :variant="InputVariantsEnum.CLEAN"
          :no-label="true"
          :clearable="true"
          @input="onSearch"
        />
        <div class="base-select-items">
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
            class="fade-list-item base-select-fetch-more"
            @click="fetchMore"
            :variant="BtnVariantsEnum.BARE"
            >{{ t("baseSelect.actions.fetchMore") }}</Btn
          >
        </div>
      </div>
    </Collapsed>
    <!--
      The message, below the control, rendered only when there is one -- the same
      shape the other discrete controls use. This was the last state in the
      language still signalled by a hover tooltip alone: nothing to see without a
      mouse, and nothing at all for assistive tech.
    -->
    <p v-if="error" :id="errorId" class="base-select__error" role="alert">
      {{ error }}
    </p>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
