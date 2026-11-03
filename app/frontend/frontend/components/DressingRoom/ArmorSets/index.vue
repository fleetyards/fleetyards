<script lang="ts">
export default {
  name: "DressingRoomArmorSets",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type OutfitSelection,
  wearsArmorSet,
} from "@/frontend/utils/dressingRoom";
import { type ArmorSet, useArmorSets } from "@/services/fyApi";

type Props = {
  selection: OutfitSelection;
};

const props = defineProps<Props>();

const emit = defineEmits<{
  select: [set: ArmorSet];
  close: [];
}>();

const { t } = useI18n();

const search = ref("");

const { data: sets, isLoading } = useArmorSets({
  query: { refetchOnWindowFocus: false, staleTime: 5 * 60 * 1000 },
});

const setKey = (set: ArmorSet) => `${set.manufacturerName ?? ""}/${set.name}`;

const filtered = computed(() => {
  const terms = search.value.toLowerCase().split(/\s+/).filter(Boolean);

  return (sets.value ?? []).filter((set) => {
    const haystack = [set.name, set.manufacturerName, set.itemTypeLabel]
      .filter(Boolean)
      .join(" ")
      .toLowerCase();

    return terms.every((term) => haystack.includes(term));
  });
});

const byline = (set: ArmorSet) =>
  [set.manufacturerName, set.itemTypeLabel].filter(Boolean).join(" · ");

const slots = (set: ArmorSet) =>
  set.pieces.map((piece) => t(`dressingRoom.slots.${piece.slot}`)).join(", ");
</script>

<template>
  <div class="armor-sets" data-test="dressing-room-armor-sets">
    <div class="armor-sets__header">
      <FormInput
        v-model="search"
        class="armor-sets__search"
        name="dressing-room-armor-set-search"
        icon="fa-light fa-magnifying-glass"
        :label="t('dressingRoom.armorSets.search')"
        :placeholder="t('dressingRoom.armorSets.search')"
        no-label
        clearable
        autofocus
      />
      <Btn
        :size="BtnSizesEnum.SM"
        :aria-label="t('actions.close')"
        data-test="dressing-room-armor-sets-close"
        @click="emit('close')"
      >
        <i class="fa-light fa-xmark" />
      </Btn>
    </div>
    <Loader v-if="isLoading" :loading="true" />
    <p
      v-else-if="!filtered.length"
      class="armor-sets__empty"
      data-test="dressing-room-armor-sets-empty"
    >
      {{ t("dressingRoom.armorSets.noResults") }}
    </p>
    <ul v-else class="armor-sets__list">
      <li v-for="set in filtered" :key="setKey(set)">
        <button
          type="button"
          class="armor-sets__item"
          :class="{
            'armor-sets__item--selected': wearsArmorSet(props.selection, set),
          }"
          :data-test="`dressing-room-armor-set-${set.pieces[0]?.slug}`"
          @click="emit('select', set)"
        >
          <span class="armor-sets__name">{{ set.name }}</span>
          <span v-if="byline(set)" class="armor-sets__sub">
            {{ byline(set) }}
          </span>
          <span class="armor-sets__sub">{{ slots(set) }}</span>
        </button>
      </li>
    </ul>
  </div>
</template>

<style lang="scss" scoped>
.armor-sets {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.armor-sets__header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.armor-sets__search {
  flex: 1;
  margin-bottom: 0;
}

.armor-sets__empty {
  margin: 0;
  color: $gray-lighter;
}

.armor-sets__list {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  max-height: 28rem;
  margin: 0;
  padding: 0;
  overflow-y: auto;
  list-style: none;
}

.armor-sets__item {
  display: flex;
  flex-direction: column;
  width: 100%;
  min-height: $tap-target-min;
  padding: 0.375rem 0.5rem;
  border: 1px solid transparent;
  border-radius: 4px;
  background: none;
  color: inherit;
  text-align: left;
  cursor: pointer;

  &:hover,
  &:focus-visible {
    background: $gray-black-hover;
  }
}

.armor-sets__item--selected {
  border-color: $primary;
}

.armor-sets__name {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.armor-sets__sub {
  font-size: 0.85em;
  opacity: 0.6;
}
</style>
