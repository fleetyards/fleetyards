<script lang="ts">
export default {
  name: "LocationInput",
};
</script>

<script lang="ts" setup>
import { useDebounceFn } from "@vueuse/core";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type Location, locations as fetchLocations } from "@/services/fyApi";

type Props = {
  name: string;
  // The text, as the record keeps it: what a reader sees.
  modelValue?: string | null;
  // The place the text names, where it is one of ours.
  locationId?: string | null;
  // The linked place, as the record's response carries it, so the field can
  // say what it is linked to before anything is typed.
  linked?: { name?: string | null; slug: string } | null;
  translationKey?: string;
  label?: string;
  noLabel?: boolean;
  placeholder?: string;
  icon?: string;
  disabled?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  locationId: undefined,
  linked: undefined,
  translationKey: undefined,
  label: undefined,
  noLabel: false,
  placeholder: undefined,
  icon: undefined,
  disabled: false,
});

const emit = defineEmits<{
  (e: "update:modelValue", value: string | null | undefined): void;
  (e: "update:locationId", value: string | null): void;
}>();

const { t } = useI18n();

const suggestions = ref<Location[]>([]);
const open = ref(false);
const active = ref(-1);
const pickedName = ref<string | null>(props.linked?.name ?? null);
const pickedSlug = ref<string | null>(props.linked?.slug ?? null);

watch(
  () => props.linked,
  (value) => {
    pickedName.value = value?.name ?? null;
    pickedSlug.value = value?.slug ?? null;
  },
);

const SUGGESTIONS = 8;

// Only the latest search may answer: an older request finishing last would
// offer places for text the field no longer holds.
let latestSearch = 0;

const search = useDebounceFn(async (text: string) => {
  const request = ++latestSearch;

  if (text.trim().length < 2) {
    suggestions.value = [];
    return;
  }

  const query = text.trim();

  // The names that start with the text first, then the ones that only contain
  // it: "Port" means Port Tressler before a Transport Hub.
  const [starting, containing] = await Promise.all([
    fetchLocations({
      perPage: String(SUGGESTIONS),
      q: { nameStart: query },
    }).catch(() => undefined),
    fetchLocations({
      perPage: String(SUGGESTIONS),
      q: { nameCont: query },
    }).catch(() => undefined),
  ]);

  if (request !== latestSearch) return;

  const seen = new Set<string>();

  suggestions.value = [...(starting?.items ?? []), ...(containing?.items ?? [])]
    .filter((location) => !seen.has(location.id) && seen.add(location.id))
    .slice(0, SUGGESTIONS);
  active.value = -1;
}, 250);

// Typing keeps the text the field holds. A text that no longer reads as the
// linked place's name is no longer that place, so the link goes with it.
const onInput = (value?: string | number | null) => {
  const text = value === undefined || value === null ? value : String(value);

  emit("update:modelValue", text);

  if (props.locationId && text !== pickedName.value) {
    emit("update:locationId", null);
    pickedName.value = null;
    pickedSlug.value = null;
  }

  open.value = true;
  void search(text ?? "");
};

const pick = (location: Location) => {
  emit("update:modelValue", location.name);
  emit("update:locationId", location.id);
  pickedName.value = location.name ?? null;
  pickedSlug.value = location.slug;
  open.value = false;
};

const onKeydown = (event: KeyboardEvent) => {
  if (!open.value || !suggestions.value.length) return;

  if (event.key === "ArrowDown") {
    event.preventDefault();
    active.value = (active.value + 1) % suggestions.value.length;
  } else if (event.key === "ArrowUp") {
    event.preventDefault();
    active.value =
      (active.value - 1 + suggestions.value.length) % suggestions.value.length;
  } else if (event.key === "Enter" && active.value >= 0) {
    event.preventDefault();
    pick(suggestions.value[active.value]);
  } else if (event.key === "Escape") {
    open.value = false;
  }
};

// Closed after the click on a suggestion lands, not before it.
const onBlur = () => {
  window.setTimeout(() => {
    open.value = false;
  }, 150);
};

const linkedLabel = computed(() =>
  props.locationId && pickedName.value ? pickedName.value : undefined,
);
</script>

<!-- A place, typed or picked. Picking one of ours links the record to it; any
     other text is kept as it is, for a place the starmap does not carry. -->
<template>
  <div
    class="location-input"
    @keydown="onKeydown"
    @focusout="onBlur"
    data-test="location-input"
  >
    <FormInput
      :model-value="modelValue"
      :name="name"
      :translation-key="translationKey"
      :label="label"
      :no-label="noLabel"
      :placeholder="placeholder"
      :icon="icon"
      :disabled="disabled"
      autocomplete="off"
      clearable
      @update:model-value="onInput"
    >
      <template v-if="linkedLabel" #subline>
        <span class="location-input__linked" data-test="location-input-linked">
          <i class="fa-duotone fa-planet-ringed" aria-hidden="true" />
          {{ t("labels.locationInput.linked") }}
          <router-link
            v-if="pickedSlug"
            :to="{ name: 'location', params: { slug: pickedSlug } }"
            target="_blank"
          >
            {{ linkedLabel }}
          </router-link>
        </span>
      </template>
    </FormInput>

    <ul
      v-if="open && suggestions.length"
      class="location-input__suggestions"
      role="listbox"
    >
      <li
        v-for="(location, index) in suggestions"
        :key="location.id"
        role="option"
        :aria-selected="index === active"
        class="location-input__suggestion"
        :class="{ 'location-input__suggestion--active': index === active }"
        @mousedown.prevent="pick(location)"
      >
        <span class="location-input__name">{{ location.name }}</span>
        <span v-if="location.parent?.name" class="location-input__parent">
          {{ location.parent.name }}
        </span>
      </li>
    </ul>
  </div>
</template>

<style lang="scss" scoped>
.location-input {
  position: relative;

  &__linked {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    font-size: 12px;
    color: var(--color-text-dim, #959595);
  }

  &__suggestions {
    position: absolute;
    top: calc(100% - 4px);
    left: 0;
    right: 0;
    z-index: 2100;
    margin: 0;
    padding: 4px 0;
    list-style: none;
    // Solid, as a popover is: the fields behind it must not show through.
    background-color: var(--color-gray-darker, #272b30);
    border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
    border-radius: 8px;
    box-shadow: 0 8px 24px rgb(0 0 0 / 0.4);
  }

  &__suggestion {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    gap: 12px;
    padding: 6px 12px;
    cursor: pointer;
    color: var(--color-text, #c8c8c8);

    &:hover,
    &--active {
      background-color: rgb(66 139 202 / 0.18);
      color: #fff;
    }
  }

  &__name {
    font-weight: 600;
  }

  &__parent {
    font-size: 12px;
    color: var(--color-text-dim, #959595);
  }
}
</style>
