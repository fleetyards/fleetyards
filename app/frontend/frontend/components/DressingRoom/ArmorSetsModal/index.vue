<script lang="ts">
export default {
  name: "DressingRoomArmorSetsModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import PickerCard from "@/shared/components/PickerCard/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import CataloguePickerLayout from "@/frontend/components/CataloguePicker/Layout/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type OutfitSelection,
  wearsArmorSet,
} from "@/frontend/utils/dressingRoom";
import {
  type ArmorSet,
  type FilterOption,
  useArmorSets,
} from "@/services/fyApi";

interface Props {
  selection: OutfitSelection;
}

defineProps<Props>();

const emit = defineEmits<{
  select: [set: ArmorSet];
}>();

// The whole list comes at once, so paging only keeps the grid light.
const PER_PAGE = 48;

const SIZE_ORDER = ["light_armor", "medium_armor", "heavy_armor"];

const { t } = useI18n();

const comlink = useComlink();

const search = ref("");
const sizes = ref<string[]>([]);
const shown = ref(PER_PAGE);

const { data: sets, isLoading } = useArmorSets({
  query: { refetchOnWindowFocus: false, staleTime: 5 * 60 * 1000 },
});

const sizeRank = (itemType: string) => {
  const rank = SIZE_ORDER.indexOf(itemType);

  return rank === -1 ? SIZE_ORDER.length : rank;
};

const sizeOptions = computed<FilterOption[]>(() => {
  const labels = new Map<string, string>();

  (sets.value ?? []).forEach((set) => {
    if (set.itemType && !labels.has(set.itemType)) {
      labels.set(set.itemType, set.itemTypeLabel ?? set.itemType);
    }
  });

  return [...labels]
    .sort(([a], [b]) => sizeRank(a) - sizeRank(b))
    .map(([value, label]) => ({ value, label }));
});

const filtered = computed(() => {
  const terms = search.value.toLowerCase().split(/\s+/).filter(Boolean);

  return (sets.value ?? []).filter((set) => {
    if (sizes.value.length && !sizes.value.includes(set.itemType ?? "")) {
      return false;
    }

    const haystack = [set.name, set.manufacturerName, set.itemTypeLabel]
      .filter(Boolean)
      .join(" ")
      .toLowerCase();

    return terms.every((term) => haystack.includes(term));
  });
});

const visible = computed(() => filtered.value.slice(0, shown.value));

watch([search, sizes], () => {
  shown.value = PER_PAGE;
});

const setKey = (set: ArmorSet) => `${set.manufacturerName ?? ""}/${set.name}`;

const subtitleOf = (set: ArmorSet) =>
  [set.manufacturerName, set.itemTypeLabel].filter(Boolean).join(" · ");

const slotsOf = (set: ArmorSet) =>
  set.pieces.map((piece) => t(`dressingRoom.slots.${piece.slot}`)).join(", ");

const imageOf = (set: ArmorSet) =>
  set.image?.mediumUrl || set.image?.smallUrl || undefined;

const pick = (set: ArmorSet) => {
  emit("select", set);
  comlink.emit("close-modal", true);
};
</script>

<template>
  <Modal :title="t('dressingRoom.armorSets.open')" flush>
    <CataloguePickerLayout
      v-model:search="search"
      :count-label="
        t('dressingRoom.armorSets.count', { count: filtered.length })
      "
      :loading="isLoading"
      :empty="!filtered.length"
      data-test="dressing-room-armor-sets"
    >
      <template #filters>
        <BaseSelect
          v-model="sizes"
          class="armor-sets-modal__size"
          name="dressing-room-armor-sets-size"
          :options="sizeOptions"
          :label="t('dressingRoom.armorSets.size')"
          no-label
          multiple
          unsorted
        />
      </template>

      <PickerCard
        v-for="set in visible"
        :key="setKey(set)"
        :name="set.name"
        :subtitle="subtitleOf(set)"
        :image="imageOf(set)"
        image-fit="contain"
        :selected="wearsArmorSet(selection, set)"
        :data-test="`dressing-room-armor-set-${set.pieces[0]?.slug}`"
        @toggle="pick(set)"
      >
        <template #placeholder>
          <i class="fa-duotone fa-shirt" />
        </template>
        <span class="armor-sets-modal__slots">{{ slotsOf(set) }}</span>
      </PickerCard>

      <template v-if="visible.length < filtered.length" #more>
        <Btn
          :variant="BtnVariantsEnum.BARE"
          data-test="dressing-room-armor-sets-more"
          @click="shown += PER_PAGE"
        >
          {{ t("actions.loadMore") }}
        </Btn>
      </template>
    </CataloguePickerLayout>
  </Modal>
</template>

<style lang="scss" scoped>
.armor-sets-modal__size {
  min-width: 200px;
}

.armor-sets-modal__slots {
  font-size: 0.85em;
  opacity: 0.6;
}
</style>
