<script lang="ts">
export default {
  name: "DressingRoomWornStorage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Equipment,
  type OutfitHolderEnum,
  type OutfitSlotEnum,
} from "@/services/fyApi";
import {
  HOLDERS,
  MAX_STORED_QUANTITY,
  type StoredEntry,
  type StoredSelection,
  holderProblem,
  storeProblem,
  usedSpace,
  wornInventory,
} from "@/frontend/utils/dressingRoomStorage";

type Props = {
  stored: StoredSelection;
  worn: Partial<Record<OutfitSlotEnum, Equipment | undefined>>;
  storedItems: Record<string, Equipment | undefined>;
  // Worn pieces or items still loading: nothing is known to be missing or
  // wrong yet.
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), { loading: false });

const emit = defineEmits<{
  add: [holder: OutfitHolderEnum];
  quantity: [holder: OutfitHolderEnum, slug: string, quantity: number];
}>();

const { t, toNumber } = useI18n();

const microScuLabel = (value: number) =>
  value
    ? String(toNumber(value, "microScu"))
    : t("number.microScu", { count: 0 });

const inventoryOf = (holder: OutfitHolderEnum) =>
  wornInventory(props.worn, holder);

// Everything with room in it, and anything still holding items after the piece
// that held them came off.
const holders = computed(() =>
  HOLDERS.flatMap((holder) => {
    const inventory = inventoryOf(holder);
    const entries = props.stored[holder] ?? [];
    if (!inventory && !entries.length) return [];

    const used = usedSpace(entries, props.storedItems);

    return [
      {
        holder,
        inventory,
        entries,
        used,
        percent: inventory
          ? Math.min(100, Math.round((used / inventory.capacity) * 100))
          : 0,
        problem: props.loading
          ? undefined
          : holderProblem(inventory, entries, props.storedItems),
      },
    ];
  }),
);

const canAddOne = (
  holder: OutfitHolderEnum,
  entry: StoredEntry,
  used: number,
) => {
  const inventory = inventoryOf(holder);
  const item = props.storedItems[entry.slug];

  return (
    !!inventory &&
    !!item &&
    entry.quantity < MAX_STORED_QUANTITY &&
    !storeProblem(inventory, item, used)
  );
};
</script>

<template>
  <section class="worn-storage" data-test="dressing-room-storage">
    <p
      v-if="!holders.length"
      class="worn-storage__hint"
      data-test="dressing-room-storage-hint"
    >
      {{ loading ? "…" : t("dressingRoom.storage.hint") }}
    </p>
    <div
      v-for="{ holder, inventory, entries, used, percent, problem } in holders"
      :key="holder"
      class="worn-storage__holder"
      :data-test="`dressing-room-storage-${holder}`"
    >
      <div class="worn-storage__header">
        <span class="worn-storage__piece">
          {{ t(`dressingRoom.slots.${holder}`) }}
        </span>
        <span
          v-if="inventory"
          class="worn-storage__space"
          :data-test="`dressing-room-storage-space-${holder}`"
        >
          {{
            t("dressingRoom.storage.space", {
              used: microScuLabel(used),
              capacity: microScuLabel(inventory.capacity),
            })
          }}
        </span>
      </div>
      <div
        v-if="inventory"
        class="worn-storage__meter"
        role="progressbar"
        :aria-valuenow="percent"
        aria-valuemin="0"
        aria-valuemax="100"
        :aria-label="t(`dressingRoom.slots.${holder}`)"
      >
        <span
          class="worn-storage__meter-fill"
          :class="{
            'worn-storage__meter-fill--over': problem === 'overCapacity',
          }"
          :style="{ width: `${percent}%` }"
        />
      </div>
      <p
        v-if="problem"
        class="worn-storage__warning"
        :data-test="`dressing-room-storage-problem-${holder}`"
      >
        {{ t(`dressingRoom.storage.problems.${problem}`) }}
      </p>
      <ul v-if="entries.length" class="worn-storage__items">
        <li
          v-for="entry in entries"
          :key="entry.slug"
          class="worn-storage__item"
          :data-test="`dressing-room-stored-${holder}-${entry.slug}`"
        >
          <span
            class="worn-storage__name"
            :class="{
              'worn-storage__name--missing':
                !storedItems[entry.slug] && !loading,
            }"
          >
            {{
              storedItems[entry.slug]?.name ??
              (loading ? "…" : t("dressingRoom.notFound"))
            }}
          </span>
          <Btn
            :size="BtnSizesEnum.SM"
            :variant="BtnVariantsEnum.BARE"
            :aria-label="t('dressingRoom.storage.fewer')"
            :data-test="`dressing-room-stored-fewer-${holder}-${entry.slug}`"
            @click="emit('quantity', holder, entry.slug, entry.quantity - 1)"
          >
            <i class="fa-light fa-minus" />
          </Btn>
          <span class="worn-storage__quantity">{{ entry.quantity }}</span>
          <Btn
            :size="BtnSizesEnum.SM"
            :variant="BtnVariantsEnum.BARE"
            :disabled="!canAddOne(holder, entry, used)"
            :aria-label="t('dressingRoom.storage.more')"
            :data-test="`dressing-room-stored-more-${holder}-${entry.slug}`"
            @click="emit('quantity', holder, entry.slug, entry.quantity + 1)"
          >
            <i class="fa-light fa-plus" />
          </Btn>
          <Btn
            :size="BtnSizesEnum.SM"
            :variant="BtnVariantsEnum.BARE"
            :aria-label="t('dressingRoom.remove')"
            :data-test="`dressing-room-stored-remove-${holder}-${entry.slug}`"
            @click="emit('quantity', holder, entry.slug, 0)"
          >
            <i class="fa-light fa-xmark" />
          </Btn>
        </li>
      </ul>
      <Btn
        v-if="inventory"
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.GHOST"
        :data-test="`dressing-room-storage-add-${holder}`"
        @click="emit('add', holder)"
      >
        <i class="fa-light fa-plus" />
        {{ t("dressingRoom.storage.add") }}
      </Btn>
    </div>
  </section>
</template>

<style lang="scss" scoped>
.worn-storage {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.worn-storage__hint {
  margin: 0;
  color: $gray-light;
}

.worn-storage__holder {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 0.375rem;
}

.worn-storage__header {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  gap: 0.25rem 0.75rem;
  width: 100%;
}

.worn-storage__space {
  color: $gray-lighter;
  font-size: 0.85em;
}

.worn-storage__meter {
  width: 100%;
  height: 4px;
  overflow: hidden;
  border-radius: 2px;
  background: $gray-darker;
}

.worn-storage__meter-fill {
  display: block;
  height: 100%;
  background: $primary;
}

.worn-storage__meter-fill--over {
  background: $warning;
}

.worn-storage__warning {
  margin: 0;
  color: $warning;
  font-size: 0.85em;
}

.worn-storage__items {
  display: flex;
  flex-direction: column;
  width: 100%;
  margin: 0;
  padding: 0;
  list-style: none;
}

.worn-storage__item {
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

.worn-storage__name {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.worn-storage__name--missing {
  color: $warning;
}

.worn-storage__quantity {
  min-width: 2ch;
  text-align: center;
}
</style>
