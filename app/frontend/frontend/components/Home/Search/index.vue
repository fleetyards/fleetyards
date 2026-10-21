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
import HomeSearchResultLabel from "@/frontend/components/Home/Search/ResultLabel/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useLowPowerDevice } from "@/shared/composables/useLowPowerDevice";
import { catalogueTokenIcon } from "@/shared/utils/CatalogueTokens";
import { catalogueItemRoute } from "@/frontend/utils/catalogueItemRoute";
import {
  search as fetchSearch,
  type SearchGroup,
  type SearchResult,
} from "@/services/fyApi";

type Props = {
  autofocus?: boolean;
  // Searches offered under the field to start from.
  suggestions?: string[];
};

withDefaults(defineProps<Props>(), {
  autofocus: false,
  suggestions: () => [],
});

const { t } = useI18n();
const router = useRouter();

// A touch screen has no arrow keys to hint at.
const touch = useLowPowerDevice();

// What heads each catalogue's matches -- the catalogue's own name in the nav.
const GROUP_LABELS: Record<string, string> = {
  Model: "nav.ships.index",
  Component: "nav.catalogue.components",
  Equipment: "nav.catalogue.equipment",
  Commodity: "nav.catalogue.commodities",
  Blueprint: "nav.catalogue.blueprints",
  GameMission: "nav.catalogue.missions",
  Location: "nav.locations",
};

const MIN_LENGTH = 2;

const searchQuery = ref<string | undefined>();
const groups = ref<SearchGroup[]>([]);
const searchedFor = ref<string | undefined>();
const open = ref(false);
const active = ref(-1);

const query = computed(() => searchQuery.value?.trim() ?? "");

// In list order, for the keyboard to step through across the groups.
const results = computed(() => groups.value.flatMap((group) => group.items));

const indexOf = (result: SearchResult) => results.value.indexOf(result);

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

const searchNow = async (text: string) => {
  const request = ++latestSearch;
  const trimmed = text.trim();

  if (trimmed.length < MIN_LENGTH) {
    groups.value = [];
    searchedFor.value = undefined;
    return;
  }

  const response = await fetchSearch({ q: trimmed }).catch(() => undefined);

  if (request !== latestSearch) return;

  groups.value = response?.groups ?? [];
  searchedFor.value = trimmed;
  // The best match is highlighted from the start, so what Enter opens is
  // always on screen.
  active.value = results.value.length ? 0 : -1;
};

const runSearch = useDebounceFn(searchNow, 200);

const onInput = (value?: string | number | null) => {
  searchQuery.value =
    value === undefined || value === null ? undefined : String(value);
  open.value = true;
  void runSearch(searchQuery.value ?? "");
};

const pick = async (result: SearchResult) => {
  const target = catalogueItemRoute(result);
  if (!target) return;

  open.value = false;
  await router.push(target);
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

  const result = results.value[active.value];
  if (result) await pick(result);
};

const onKeydown = (event: KeyboardEvent) => {
  if (event.key === "Escape") {
    open.value = false;
    return;
  }

  if (!open.value || !results.value.length) return;

  if (event.key === "ArrowDown") {
    event.preventDefault();
    active.value = (active.value + 1) % results.value.length;
  } else if (event.key === "ArrowUp") {
    event.preventDefault();
    active.value =
      (active.value - 1 + results.value.length) % results.value.length;
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

// The hero sits the field halfway down the screen, so a height measured from
// the top of the viewport runs the list off the bottom of it.
const field = useTemplateRef<HTMLElement>("field");
const { bottom: fieldBottom } = useElementBounding(field);
const { height: windowHeight } = useWindowSize();

const popoverStyle = computed(() => ({
  maxHeight: `${Math.max(240, Math.min(560, windowHeight.value - fieldBottom.value - 22))}px`,
}));
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
      <FormInputGroup>
        <FormInput
          :model-value="searchQuery"
          name="search"
          :size="InputSizesEnum.LARGE"
          :autofocus="autofocus"
          translation-key="home.catalogueSearch"
          autocomplete="off"
          no-label
          clearable
          @update:model-value="onInput"
        />
        <Btn
          type="submit"
          :aria-label="t('labels.home.submitCatalogueSearch')"
          :size="BtnSizesEnum.LG"
          data-test="home-search-submit"
        >
          <i class="fa-light fa-search" />
        </Btn>
      </FormInputGroup>

      <div
        v-if="showList"
        class="home-search__popover"
        :style="popoverStyle"
        data-test="home-search-results"
      >
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
          v-else-if="!results.length"
          class="home-search__state home-search__state--empty"
          aria-live="polite"
          data-test="home-search-empty"
        >
          <i class="fa-duotone fa-telescope" aria-hidden="true" />
          <div>
            <div class="home-search__state-title">
              {{ t("home.landing.searchNoResults", { query: searchedFor }) }}
            </div>
            <div>{{ t("home.landing.searchNoResultsHint") }}</div>
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
                {{ t(GROUP_LABELS[group.type] || "nav.catalogue.index") }}
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
                    :result="result"
                    :query="searchedFor"
                  />
                </li>
              </ul>
            </li>
          </ul>
          <div v-if="!touch" class="home-search__keys" aria-hidden="true">
            <span>
              <kbd>↑</kbd><kbd>↓</kbd> {{ t("home.landing.searchKeys.move") }}
            </span>
            <span><kbd>↵</kbd> {{ t("home.landing.searchKeys.open") }}</span>
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
  font-size: 13px;
}

.home-search__try-separator {
  color: var(--color-muted, #7a8288);
  font-size: 13px;
}

// Links, not buttons: they brighten rather than turn blue, as the app's links do.
.home-search__try-term {
  padding: 2px 2px;
  color: var(--color-text, #c8c8c8);
  font-size: 13px;
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
  align-items: center;
  gap: 10px;
  padding: 14px 16px;
  color: var(--color-text-dim, #959595);
  font-size: 13px;

  &--empty {
    gap: 14px;
    padding: 18px 16px;

    > i {
      color: var(--color-muted, #7a8288);
      font-size: 24px;
    }
  }
}

.home-search__state-title {
  color: var(--color-lifted, #eee);
  font-weight: 600;
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
  font-size: 10px;
  letter-spacing: 0.16em;
  text-transform: uppercase;

  :deep(i),
  :deep(svg) {
    color: var(--color-muted, #7a8288);
    font-size: 11px;
  }
}

.home-search__option {
  padding: 6px 10px;
  border-radius: 6px;
  cursor: pointer;

  &--active {
    background: var(--color-control-hover, rgb(52 58 64 / 0.95));
  }
}

.home-search__keys {
  display: flex;
  flex: 0 0 auto;
  gap: 16px;
  padding: 8px 16px;
  color: var(--color-text-dim, #959595);
  font-size: 11.5px;
  border-top: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));

  kbd {
    display: inline-block;
    min-width: 18px;
    margin-right: 2px;
    padding: 1px 4px;
    color: var(--color-text, #c8c8c8);
    font-family: inherit;
    font-size: 11px;
    line-height: 1.3;
    text-align: center;
    background: var(--color-control, rgb(39 43 48 / 0.9));
    border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
    border-radius: 4px;
    box-shadow: none;
  }
}
</style>
