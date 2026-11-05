<script lang="ts">
export default {
  name: "HomeSearch",
};
</script>

<script lang="ts" setup>
import { useDebounceFn, useElementBounding, useWindowSize } from "@vueuse/core";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormInputGroup from "@/shared/components/base/FormInputGroup/index.vue";
import AppIcon from "@/shared/components/AppIcon/index.vue";
import Avatar from "@/shared/components/Avatar/index.vue";
import HomeSearchResultAction from "@/frontend/components/Home/Search/ResultAction/index.vue";
import HomeSearchResultLabel from "@/frontend/components/Home/Search/ResultLabel/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import { FLEET_GLYPH } from "@/shared/glyphs/fleets";
import { useI18n } from "@/shared/composables/useI18n";
import { useLowPowerDevice } from "@/shared/composables/useLowPowerDevice";
import { catalogueTokenIcon } from "@/shared/utils/CatalogueTokens";
import { catalogueItemRoute } from "@/frontend/utils/catalogueItemRoute";
import { SEARCH_GROUPS } from "@/frontend/components/Home/Search/groups";
import { useSearchResultAdd } from "@/frontend/components/Home/Search/useSearchResultAdd";
import {
  CATALOGUE_SCOPE,
  useSearchScopes,
} from "@/frontend/components/Home/Search/useSearchScopes";
import {
  type SearchGroup,
  type SearchResult,
  type SearchResults,
} from "@/services/fyApi";

type Props = {
  autofocus?: boolean;
  // Searches offered under the field to start from.
  suggestions?: string[];
  // The page header holds a medium field beside its other controls.
  compact?: boolean;
};

withDefaults(defineProps<Props>(), {
  autofocus: false,
  suggestions: () => [],
  compact: false,
});

const { t } = useI18n();
const router = useRouter();
const route = useRoute();

const {
  scopes,
  current: scope,
  select: selectScope,
  step: stepScope,
} = useSearchScopes();
const { canAdd, add } = useSearchResultAdd();

// A touch screen has no arrow keys to hint at.
const touch = useLowPowerDevice();

const MIN_LENGTH = 2;

const searchQuery = ref<string | undefined>();
const rankedGroups = ref<SearchGroup[]>([]);
const answeringFleet = ref<SearchResults["fleet"]>();
const failed = ref(false);
const searchedFor = ref<string | undefined>();
const open = ref(false);
const active = ref(-1);

const query = computed(() => searchQuery.value?.trim() ?? "");

const leads = (group: SearchGroup) =>
  !!SEARCH_GROUPS[group.type]?.listPages.includes(route.name as string);

const groups = computed(() => [
  ...rankedGroups.value.filter(leads),
  ...rankedGroups.value.filter((group) => !leads(group)),
]);

// A row of the list: a match, or a group standing for its "show more".
type Step = SearchResult | SearchGroup;

const hasMoreLink = (group: SearchGroup) =>
  group.hasMore && !!SEARCH_GROUPS[group.type];

// In list order, for the keyboard to step through across the groups.
const steps = computed<Step[]>(() =>
  groups.value.flatMap((group) => [
    ...group.items,
    ...(hasMoreLink(group) ? [group] : []),
  ]),
);

const indexOf = (step: Step) => steps.value.indexOf(step);

const answered = computed(() => searchedFor.value === query.value);

const list = ref<HTMLElement | null>(null);

// A match stepped to below the list's fold is scrolled to.
watch(active, async (index) => {
  if (index < 0) return;

  await nextTick();
  list.value
    ?.querySelector(".home-search__option--active")
    ?.scrollIntoView({ block: "nearest" });
});

// Only the latest search may answer: an older request finishing last would
// offer matches for text the field no longer holds.
let latestSearch = 0;

const forgetAnswer = () => {
  answeringFleet.value = undefined;
  failed.value = false;
  rankedGroups.value = [];
  searchedFor.value = undefined;
};

const searchNow = async (text: string) => {
  const request = ++latestSearch;
  const trimmed = text.trim();

  if (trimmed.length < MIN_LENGTH) {
    forgetAnswer();
    return;
  }

  const response = await scope.value.search(trimmed).catch(() => undefined);

  if (request !== latestSearch) return;

  rankedGroups.value = response?.groups ?? [];
  answeringFleet.value = response?.fleet;
  failed.value = !response;
  searchedFor.value = trimmed;
  // The best match is highlighted from the start, so what Enter opens is
  // always on screen.
  active.value = steps.value.length ? 0 : -1;
};

// Whatever the field holds once the wait is over: it may have been cleared.
const runSearch = useDebounceFn(() => searchNow(query.value), 200);

// The answer on screen is the previous scope's, and until the new one lands the
// keys must not act on it.
watch(
  () => scope.value.key,
  () => {
    forgetAnswer();
    void searchNow(query.value);
  },
);

const clear = () => {
  latestSearch++;
  searchQuery.value = undefined;
  forgetAnswer();
};

// In the page header the field outlives every navigation, not just its own.
watch(() => route.path, clear);

const onInput = (value?: string | number | null) => {
  searchQuery.value =
    value === undefined || value === null ? undefined : String(value);
  open.value = true;
  void runSearch();
};

const listRoute = (group: SearchGroup, text?: string) => {
  const list = SEARCH_GROUPS[group.type]?.list;
  if (!list) return undefined;

  const fleetSlug = scope.value.fleetSlug;

  return {
    name: list.name,
    params: fleetSlug ? { slug: fleetSlug } : {},
    query: { ...list.view, ...(list.filter ? { [list.filter]: text } : {}) },
  };
};

// What has no page of its own opens on its list, narrowed to it.
const targetOf = (step: Step) => {
  if ("items" in step) return listRoute(step, searchedFor.value);

  const page = catalogueItemRoute({
    ...step,
    fleetSlug: scope.value.fleetSlug,
  });
  if (page) return page;

  const group = groups.value.find(({ items }) => items.includes(step));

  return group && listRoute(group, step.name);
};

const pick = async (step: Step) => {
  const target = targetOf(step);
  if (!target) return;

  open.value = false;
  await router.push(target);

  clear();
};

// Enter opens the highlighted match and nothing else. Pressed before the list
// has answered, it answers it -- the reader sees the matches before anything
// opens -- and with no match at all it stays where it is.
const submit = async () => {
  if (query.value.length < MIN_LENGTH) return;

  open.value = true;

  if (!answered.value) {
    await searchNow(query.value);
    return;
  }

  if (offersCatalogue.value) {
    selectScope(CATALOGUE_SCOPE);
    return;
  }

  const step = steps.value[active.value];
  if (step) await pick(step);
};

// Until the field's text has its answer, the rows held are for older text.
const activeResult = computed(() => {
  if (!answered.value) return undefined;

  const step = steps.value[active.value];

  return step && !("items" in step) ? step : undefined;
});

const addable = computed(
  () => !!activeResult.value && canAdd(activeResult.value),
);

const addActive = async () => {
  const result = activeResult.value;
  if (!result || !addable.value) return;

  const outcome = await add(result);

  if (outcome === "opened") open.value = false;
  if (outcome === "unavailable") await pick(result);
};

// A saved scope can otherwise pass for an empty catalogue.
const offersCatalogue = computed(
  () =>
    answered.value &&
    !failed.value &&
    !steps.value.length &&
    scope.value.key !== CATALOGUE_SCOPE,
);

// The button goes as soon as it has answered, and focus must not go with it:
// leaving the search closes it.
const searchCatalogue = () => {
  form.value?.querySelector("input")?.focus();
  selectScope(CATALOGUE_SCOPE);
};

const canSwitchScope = computed(() => scopes.value.length > 1);

const onKeydown = (event: KeyboardEvent) => {
  if (event.key === "Escape") {
    open.value = false;
    return;
  }

  if (
    event.key === "Tab" &&
    showList.value &&
    canSwitchScope.value &&
    (event.target as HTMLElement).tagName === "INPUT"
  ) {
    event.preventDefault();
    stepScope(event.shiftKey ? -1 : 1);
    return;
  }

  if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) {
    event.preventDefault();
    if (open.value) void addActive();
    return;
  }

  if (!open.value || !steps.value.length) return;

  if (event.key === "ArrowDown") {
    event.preventDefault();
    active.value = (active.value + 1) % steps.value.length;
  } else if (event.key === "ArrowUp") {
    event.preventDefault();
    active.value = (active.value - 1 + steps.value.length) % steps.value.length;
  }
};

const form = ref<HTMLFormElement | null>(null);

// A suggestion is searched for as if typed, with the field focused so the
// keyboard carries on from there.
const trySuggestion = async (suggestion: string) => {
  searchQuery.value = suggestion;
  open.value = true;
  form.value?.querySelector("input")?.focus();
  await searchNow(suggestion);
};

// Closed after the click on a match lands, not before it -- and only once
// focus has left the search: a suggestion's button is part of it.
const onBlur = () => {
  window.setTimeout(() => {
    if (!form.value?.contains(document.activeElement)) open.value = false;
  }, 150);
};

const showList = computed(() => open.value && query.value.length >= MIN_LENGTH);

const addKey = /Mac|iPhone|iPad/.test(navigator.platform) ? "⌘" : "Ctrl";

// The hero sits the field halfway down the screen, so a height measured from
// the top of the viewport runs the list off the bottom of it.
const field = useTemplateRef<HTMLElement>("field");
const { bottom: fieldBottom } = useElementBounding(field);
const { height: windowHeight } = useWindowSize();

const popoverStyle = computed(() => {
  const maxHeight = `${Math.max(240, Math.min(560, windowHeight.value - fieldBottom.value - 22))}px`;

  return {
    maxHeight,
    "--scope-count": scopes.value.length,
    "--popover-max-height": maxHeight,
  };
});
</script>

<template>
  <form
    ref="form"
    role="search"
    class="home-search"
    @submit.prevent="submit"
    @keydown="onKeydown"
    @focusin="open = true"
    @focusout="onBlur"
  >
    <div ref="field" class="home-search__field">
      <FormInputGroup :inline="compact">
        <FormInput
          :model-value="searchQuery"
          name="search"
          :size="compact ? InputSizesEnum.MEDIUM : InputSizesEnum.LARGE"
          :autofocus="autofocus"
          translation-key="home.catalogueSearch"
          :placeholder="scope.placeholderKey && t(scope.placeholderKey)"
          autocomplete="off"
          no-label
          clearable
          @update:model-value="onInput"
        />
        <Btn
          type="submit"
          :aria-label="t('labels.home.submitCatalogueSearch')"
          :size="compact ? BtnSizesEnum.MD : BtnSizesEnum.LG"
          data-test="home-search-submit"
        >
          <i class="fa-light fa-search" />
        </Btn>
      </FormInputGroup>

      <div
        v-if="showList"
        class="home-search__popover"
        :class="{ 'home-search__popover--tabbed': canSwitchScope }"
        :style="popoverStyle"
        data-test="home-search-results"
      >
        <div
          v-if="canSwitchScope"
          class="home-search__scopes"
          role="tablist"
          :aria-label="t('home.landing.searchResults')"
        >
          <button
            v-for="option in scopes"
            :key="option.key"
            type="button"
            role="tab"
            class="home-search__scope"
            :class="{ 'home-search__scope--active': option.key === scope.key }"
            :aria-selected="option.key === scope.key"
            :aria-label="t(option.labelKey)"
            v-tooltip.right="t(option.labelKey)"
            data-test="home-search-scope"
            @mousedown.prevent
            @click="selectScope(option.key)"
          >
            <AppIcon :icon="option.icon" aria-hidden="true" />
          </button>
        </div>

        <div
          v-if="answered && answeringFleet"
          class="home-search__source"
          data-test="home-search-fleet"
        >
          <Avatar
            :avatar="answeringFleet.logo?.smallUrl"
            size="small"
            :icon="FLEET_GLYPH"
            aria-hidden="true"
          />
          {{ answeringFleet.name }}
        </div>

        <div
          v-if="!answered"
          class="home-search__state"
          aria-live="polite"
          data-test="home-search-searching"
        >
          <i class="fa-light fa-spinner-third fa-spin" aria-hidden="true" />
          {{ t("home.landing.searching") }}
        </div>

        <div
          v-else-if="failed"
          class="home-search__state home-search__state--empty"
          aria-live="polite"
          data-test="home-search-failed"
        >
          <i class="fa-duotone fa-triangle-exclamation" aria-hidden="true" />
          <div class="home-search__state-title">
            {{ t("home.landing.searchFailed") }}
          </div>
        </div>

        <div
          v-else-if="!steps.length"
          class="home-search__state home-search__state--empty"
          aria-live="polite"
          data-test="home-search-empty"
        >
          <i class="fa-duotone fa-telescope" aria-hidden="true" />
          <div>
            <div class="home-search__state-title">
              {{ t("home.landing.searchNoResults", { query: searchedFor }) }}
            </div>
            <Btn
              v-if="offersCatalogue"
              class="home-search__in-catalogue"
              :size="BtnSizesEnum.MD"
              data-test="home-search-in-catalogue"
              @mousedown.prevent
              @click="searchCatalogue"
            >
              {{ t("home.landing.searchInCatalogue") }}
              <span aria-hidden="true">↵</span>
            </Btn>
            <div v-else>{{ t("home.landing.searchNoResultsHint") }}</div>
          </div>
        </div>

        <template v-else>
          <ul
            ref="list"
            class="home-search__list"
            role="listbox"
            :aria-label="t('home.landing.searchResults')"
          >
            <li
              v-for="group in groups"
              :key="group.type"
              class="home-search__group"
              role="presentation"
            >
              <div class="home-search__group-label" role="presentation">
                <AppIcon
                  :icon="catalogueTokenIcon(group.type)"
                  aria-hidden="true"
                />
                {{
                  t(
                    SEARCH_GROUPS[group.type]?.labelKey ||
                      "nav.catalogue.index",
                  )
                }}
              </div>
              <ul class="home-search__options" role="group">
                <li
                  v-for="result in group.items"
                  :key="`${result.type}-${result.slug}`"
                  role="option"
                  :aria-selected="indexOf(result) === active"
                  class="home-search__option"
                  :class="{
                    'home-search__option--active': indexOf(result) === active,
                  }"
                  data-test="home-search-result"
                  @mousedown.prevent="pick(result)"
                  @mouseenter="active = indexOf(result)"
                >
                  <HomeSearchResultLabel
                    class="home-search__option-label"
                    :result="result"
                    :query="searchedFor"
                  />
                  <HomeSearchResultAction
                    :result="result"
                    @opened="open = false"
                    @unavailable="pick(result)"
                  />
                </li>
                <li
                  v-if="hasMoreLink(group)"
                  role="option"
                  :aria-selected="indexOf(group) === active"
                  class="home-search__option home-search__more"
                  :class="{
                    'home-search__option--active': indexOf(group) === active,
                  }"
                  data-test="home-search-more"
                  @mousedown.prevent="pick(group)"
                  @mouseenter="active = indexOf(group)"
                >
                  {{ t("home.landing.searchShowMore") }}
                  <i class="fa-light fa-arrow-right" aria-hidden="true" />
                </li>
              </ul>
            </li>
          </ul>
          <div v-if="!touch" class="home-search__keys" aria-hidden="true">
            <span>
              <kbd>↑</kbd><kbd>↓</kbd> {{ t("home.landing.searchKeys.move") }}
            </span>
            <span><kbd>↵</kbd> {{ t("home.landing.searchKeys.open") }}</span>
            <span v-if="addable" data-test="home-search-key-add">
              <kbd>{{ addKey }}</kbd
              ><kbd>↵</kbd> {{ t("home.landing.searchKeys.add") }}
            </span>
            <span v-if="canSwitchScope" data-test="home-search-key-scope">
              <kbd>tab</kbd> {{ t("home.landing.searchKeys.scope") }}
            </span>
            <span><kbd>esc</kbd> {{ t("home.landing.searchKeys.close") }}</span>
          </div>
        </template>
      </div>
    </div>

    <div
      v-if="suggestions.length"
      class="home-search__try"
      data-test="home-search-suggestions"
    >
      <span class="home-search__try-label">{{
        t("home.landing.searchTry")
      }}</span>
      <template v-for="(suggestion, index) in suggestions" :key="suggestion">
        <span
          v-if="index > 0"
          class="home-search__try-separator"
          aria-hidden="true"
          >·</span
        >
        <button
          type="button"
          class="home-search__try-term"
          data-test="home-search-suggestion"
          @click="trySuggestion(suggestion)"
        >
          {{ suggestion }}
        </button>
      </template>
    </div>
  </form>
</template>

<style lang="scss" scoped>
.home-search {
  text-align: left;
}

.home-search__field {
  position: relative;
}

.home-search__try {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: var(--home-search-try-justify, center);
  gap: 8px;
  margin-top: 14px;
}

.home-search__try-label {
  margin-right: 4px;
  color: var(--color-text-dim, #959595);
  font-size: 0.8125rem;
}

.home-search__try-separator {
  color: var(--color-muted, #7a8288);
  font-size: 0.8125rem;
}

// Links, not buttons: they brighten rather than turn blue, as the app's links do.
.home-search__try-term {
  padding: 2px 2px;
  color: var(--color-text, #c8c8c8);
  font-size: 0.8125rem;
  background: none;
  border: 0;
  border-bottom: 1px dotted var(--color-muted, #7a8288);
  cursor: pointer;

  &:hover,
  &:focus-visible {
    color: #fff;
    border-bottom-color: currentColor;
  }
}

/* The material of a dropdown menu -- opaque, edged, with its end caps -- so
   the matches read as the same family as every other popover. */
.home-search__popover {
  position: absolute;
  top: calc(100% + 6px);
  right: 0;
  left: 0;
  z-index: 2100;
  display: flex;
  flex-direction: column;
  background-color: var(--color-gray-darker, #272b30);
  border: 1px solid var(--color-edge, rgb(122 130 136 / 0.5));
  border-radius: var(--radius-control, 8px);
  box-shadow: 0 12px 32px rgb(0 0 0 / 0.45);

  &::before,
  &::after {
    position: absolute;
    right: max(10px, 14%);
    left: max(10px, 14%);
    height: 2px;
    background-color: var(--color-endcap, #7a8288);
    border-radius: 1px;
    content: "";
  }

  &::before {
    top: -1px;
  }

  &::after {
    bottom: -1px;
  }
}

.home-search__state {
  display: flex;
  flex: 1 1 auto;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 14px 16px;
  color: var(--color-text-dim, #959595);
  font-size: 0.8125rem;

  &--empty {
    flex-direction: column;
    gap: 14px;
    padding: 24px 16px;
    text-align: center;

    > i {
      color: var(--color-muted, #7a8288);
      font-size: 2.5rem;
    }
  }
}

.home-search__source {
  display: flex;
  flex: 0 0 auto;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  color: var(--color-lifted, #eee);
  font-size: 0.8125rem;
  font-weight: 600;
  border-bottom: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
}

.home-search__state-title {
  margin-bottom: 4px;
  color: var(--color-lifted, #eee);
  font-size: 0.9375rem;
  font-weight: 600;
}

.home-search__in-catalogue {
  margin-top: 12px;
}

.home-search__list {
  flex: 1 1 auto;
  margin: 0;
  padding: 6px;
  overflow-y: auto;
  list-style: none;
}

.home-search__options {
  margin: 0;
  padding: 0;
  list-style: none;
}

.home-search__group + .home-search__group {
  margin-top: 6px;
  padding-top: 6px;
  border-top: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
}

.home-search__group-label {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 10px 4px;
  color: var(--color-text-dim, #959595);
  font-family: Orbitron, sans-serif;
  font-size: 0.625rem;
  letter-spacing: 0.16em;
  text-transform: uppercase;

  :deep(i),
  :deep(svg) {
    color: var(--color-muted, #7a8288);
    font-size: 0.6875rem;
  }
}

.home-search__option {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 10px;
  border-radius: 6px;
  cursor: pointer;

  &--active {
    background: var(--color-control-hover, rgb(52 58 64 / 0.95));
  }
}

.home-search__option-label {
  flex: 1 1 auto;
}

.home-search__more {
  color: var(--color-text-dim, #959595);
  font-size: 0.8125rem;

  &.home-search__option--active {
    color: var(--color-lifted, #eee);
  }
}

// Register cards on the overlay's edge. The chosen one takes the overlay's own
// material and overlaps its frame, so the two read as one sheet.
.home-search__popover--tabbed {
  --scope-tab-height: 64px;
  --scope-tab-gap: 4px;
  --scope-tabs-top: 12px;

  // Tall enough that the tabs never hang below a short answer.
  min-height: min(
    calc(
      var(--scope-count) * (var(--scope-tab-height) + var(--scope-tab-gap)) +
        var(--scope-tabs-top) * 2
    ),
    var(--popover-max-height)
  );
}

.home-search__scopes {
  position: absolute;
  top: var(--scope-tabs-top);
  // Past the card's border, not on it: `left` counts from inside the border.
  left: calc(100% + 1px);
  display: flex;
  flex-direction: column;
  gap: var(--scope-tab-gap);
}

.home-search__scope {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  min-height: var(--scope-tab-height);
  color: var(--color-text-dim, #959595);
  font-size: 1.125rem;
  background: color-mix(in srgb, var(--color-gray-darker, #272b30) 70%, #000);
  // The card's shadow falling on it: what is not chosen lies behind the sheet.
  box-shadow: inset 8px 0 8px -6px rgb(0 0 0 / 0.65);
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-left: 0;
  border-radius: 0 6px 6px 0;
  cursor: pointer;

  &:hover {
    color: var(--color-lifted, #eee);
  }

  &--active {
    width: 41px;
    margin-left: -1px;
    color: var(--color-lifted, #eee);
    background: var(--color-gray-darker, #272b30);
    border-color: var(--color-edge, rgb(122 130 136 / 0.5));
    box-shadow: 4px 2px 8px rgb(0 0 0 / 0.35);
    // Outward only: on the card's side a shadow draws the seam it should hide.
    clip-path: inset(-12px -12px -12px 0);
  }
}

// No room beside the overlay on a phone: it gives up the width its tabs take.
@media (max-width: $desktop-breakpoint) {
  .home-search__popover--tabbed {
    right: 42px;
  }
}

.home-search__keys {
  display: flex;
  flex: 0 0 auto;
  flex-wrap: wrap;
  gap: 8px 16px;
  padding: 8px 16px;
  color: var(--color-text-dim, #959595);
  font-size: 0.71875rem;
  border-top: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));

  kbd {
    display: inline-block;
    min-width: 18px;
    margin-right: 2px;
    padding: 1px 4px;
    color: var(--color-text, #c8c8c8);
    font-family: inherit;
    font-size: 0.6875rem;
    line-height: 1.3;
    text-align: center;
    background: var(--color-control, rgb(39 43 48 / 0.9));
    border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
    border-radius: 4px;
    box-shadow: none;
  }
}
</style>
