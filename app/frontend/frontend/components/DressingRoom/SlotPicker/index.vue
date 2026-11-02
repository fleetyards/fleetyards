<script lang="ts">
export default {
  name: "DressingRoomSlotPicker",
};
</script>

<script lang="ts" setup>
import { keepPreviousData, useQuery } from "@tanstack/vue-query";
import debounce from "lodash.debounce";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { INVENTORY_EQUIPMENT_TYPES } from "@/frontend/composables/useInventoryOptions";
import { WEAPON_SUB_TYPES, isWeaponSlot } from "@/frontend/utils/dressingRoom";
import { type SlotFit, fitsSlot } from "@/frontend/utils/dressingRoomFit";
import {
  type Equipment,
  type EquipmentSlotEnum,
  type OutfitSlotEnum,
  equipment as fetchEquipment,
} from "@/services/fyApi";

type Props = {
  slot: OutfitSlotEnum;
  selectedSlug?: string;
  // What the worn pieces leave room for: anything else is shown, but greyed
  // out with the reason.
  fit?: SlotFit;
};

const props = withDefaults(defineProps<Props>(), {
  selectedSlug: undefined,
  fit: () => ({ kind: "open" }),
});

const fits = (item: Equipment) => fitsSlot(props.fit, item);

const misfitReason = computed(() =>
  props.fit.kind === "open"
    ? ""
    : t("dressingRoom.fit.doesNotFit", {
        item: props.fit.providers.map((provider) => provider.name).join(", "),
      }),
);

const emit = defineEmits<{
  select: [item: Equipment];
  close: [];
}>();

const PER_PAGE = "30";

const { t } = useI18n();

const search = ref("");
const searchTerm = ref("");
const page = ref(1);
const records = ref<Equipment[]>([]);

// A weapon slot takes weapons of its size; an armour slot the armour and
// undersuits made for it.
const slotQuery = computed(() =>
  isWeaponSlot(props.slot)
    ? {
        equipmentTypeIn: ["weapon"],
        subTypeIn: WEAPON_SUB_TYPES[props.slot],
      }
    : {
        slotIn: [props.slot as EquipmentSlotEnum],
        equipmentTypeIn: INVENTORY_EQUIPMENT_TYPES.armor,
      },
);

const { data, isFetching, isPlaceholderData } = useQuery({
  queryKey: computed(() => [
    "dressing-room-slot-picker",
    PER_PAGE,
    slotQuery.value,
    searchTerm.value,
    page.value,
  ]),
  queryFn: () =>
    fetchEquipment({
      page: String(page.value),
      perPage: PER_PAGE,
      q: {
        ...slotQuery.value,
        nameOrSlugCont: searchTerm.value || undefined,
      },
    }),
  refetchOnWindowFocus: false,
  placeholderData: keepPreviousData,
});

const totalPages = ref(1);

// A page extends the list or replaces it by what the response says it is, so
// a stale second page cannot land on a list a new search already reset.
watch(
  [data, isPlaceholderData],
  ([response, placeholder]) => {
    if (!response || placeholder) return;

    const current = response.meta?.pagination?.currentPage ?? 1;
    totalPages.value = response.meta?.pagination?.totalPages ?? 1;

    if (current <= 1) {
      records.value = response.items;
      return;
    }

    const known = new Set(records.value.map((item) => item.id));
    records.value = [
      ...records.value,
      ...response.items.filter((item) => !known.has(item.id)),
    ];
  },
  { immediate: true },
);

const hasMore = computed(
  () => !isPlaceholderData.value && page.value < totalPages.value,
);

const applySearch = debounce((value: string) => {
  searchTerm.value = value;
  page.value = 1;
}, 300);

watch(search, applySearch);

watch(
  () => props.slot,
  () => {
    search.value = "";
    searchTerm.value = "";
    records.value = [];
    page.value = 1;
  },
);

onUnmounted(() => applySearch.cancel());
</script>

<template>
  <div class="slot-picker" data-test="dressing-room-slot-picker">
    <div class="slot-picker__header">
      <FormInput
        v-model="search"
        class="slot-picker__search"
        name="dressing-room-search"
        icon="fa-light fa-magnifying-glass"
        :label="
          t('dressingRoom.search', { slot: t(`dressingRoom.slots.${slot}`) })
        "
        :placeholder="
          t('dressingRoom.search', { slot: t(`dressingRoom.slots.${slot}`) })
        "
        no-label
        clearable
        autofocus
      />
      <Btn
        :size="BtnSizesEnum.SM"
        :aria-label="t('actions.close')"
        data-test="dressing-room-slot-picker-close"
        @click="emit('close')"
      >
        <i class="fa-light fa-xmark" />
      </Btn>
    </div>
    <Loader v-if="isFetching && !records.length" :loading="true" />
    <p
      v-else-if="!records.length"
      class="slot-picker__empty"
      data-test="dressing-room-slot-picker-empty"
    >
      {{ t("dressingRoom.noResults") }}
    </p>
    <ul
      v-else
      class="slot-picker__list"
      :class="{ 'slot-picker__list--stale': isPlaceholderData }"
    >
      <li v-for="item in records" :key="item.id">
        <button
          type="button"
          class="slot-picker__item"
          :class="{
            'slot-picker__item--selected': item.slug === selectedSlug,
            'slot-picker__item--misfit': !fits(item),
          }"
          :disabled="!fits(item)"
          :data-test="`dressing-room-option-${item.slug}`"
          @click="emit('select', item)"
        >
          <img
            v-if="item.media?.angledView?.smallUrl"
            class="slot-picker__image"
            :src="item.media.angledView.smallUrl"
            alt=""
            loading="lazy"
          />
          <span v-else class="slot-picker__image slot-picker__image--empty">
            <i class="fa-duotone fa-shirt" />
          </span>
          <span class="slot-picker__label">
            <span class="slot-picker__name">{{ item.name }}</span>
            <span v-if="item.manufacturer" class="slot-picker__sub">
              {{ item.manufacturer.name }}
            </span>
            <span
              v-if="!fits(item)"
              class="slot-picker__sub slot-picker__sub--misfit"
            >
              {{ misfitReason }}
            </span>
          </span>
        </button>
      </li>
    </ul>
    <Btn
      v-if="hasMore"
      class="slot-picker__more"
      :disabled="isFetching"
      data-test="dressing-room-slot-picker-more"
      @click="page += 1"
    >
      {{ t("actions.loadMore") }}
    </Btn>
  </div>
</template>

<style lang="scss" scoped>
.slot-picker {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.slot-picker__header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.slot-picker__search {
  flex: 1;
  margin-bottom: 0;
}

.slot-picker__empty {
  margin: 0;
  color: $gray-lighter;
}

.slot-picker__list {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  max-height: 28rem;
  margin: 0;
  padding: 0;
  overflow-y: auto;
  list-style: none;
  transition: opacity 0.2s;
}

.slot-picker__list--stale {
  opacity: 0.5;
}

.slot-picker__item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  width: 100%;
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

.slot-picker__item--misfit {
  cursor: not-allowed;
  opacity: 0.45;
}

.slot-picker__sub--misfit {
  color: $warning;
}

.slot-picker__item--selected {
  border-color: $primary;
}

.slot-picker__image {
  flex: none;
  width: 3rem;
  height: 3rem;
  object-fit: contain;
}

.slot-picker__image--empty {
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0.4;
}

.slot-picker__label {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.slot-picker__name {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.slot-picker__sub {
  font-size: 0.85em;
  opacity: 0.6;
}

.slot-picker__more {
  align-self: center;
}
</style>
