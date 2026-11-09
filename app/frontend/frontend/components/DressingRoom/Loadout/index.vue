<script lang="ts">
export default {
  name: "DressingRoomLoadout",
};
</script>

<script lang="ts" setup>
import SlotRow from "@/frontend/components/DressingRoom/SlotRow/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type OutfitSlotEnum } from "@/services/fyApi";

type Row = Omit<InstanceType<typeof SlotRow>["$props"], "slot"> & {
  slot: OutfitSlotEnum;
  label: string;
};

type Tab = {
  key: string;
  slots: OutfitSlotEnum[];
  // Said in place of the slots when there are none.
  hint?: string;
};

type Props = {
  tabs: Tab[];
  // The gear a pocket or holster holds, by kind.
  supplies: { key: string; slots: OutfitSlotEnum[] }[];
  suppliesHint?: string;
  row: (slot: OutfitSlotEnum) => Row;
};

const props = withDefaults(defineProps<Props>(), {
  suppliesHint: undefined,
});

const emit = defineEmits<{
  pick: [slot: OutfitSlotEnum];
  hold: [slot: OutfitSlotEnum];
  clear: [slot: OutfitSlotEnum];
}>();

const { t } = useI18n();

const SUPPLIES = "supplies";

const tabKeys = computed(() => [...props.tabs.map((tab) => tab.key), SUPPLIES]);

const active = ref(props.tabs[0]?.key ?? SUPPLIES);

const filled = (slots: OutfitSlotEnum[]) =>
  slots.filter((slot) => props.row(slot).selected).length;
</script>

<template>
  <section class="loadout" data-test="dressing-room-loadout">
    <div
      class="loadout__tabs"
      role="tablist"
      :aria-label="t('dressingRoom.loadout')"
    >
      <button
        v-for="key in tabKeys"
        :key="key"
        type="button"
        class="loadout__tab"
        :class="{ 'loadout__tab--active': key === active }"
        role="tab"
        :aria-selected="key === active"
        :data-test="`dressing-room-tab-${key}`"
        @click="active = key"
      >
        {{ t(`dressingRoom.groups.${key}`) }}
      </button>
    </div>

    <div
      v-for="tab in tabs"
      v-show="tab.key === active"
      :key="tab.key"
      role="tabpanel"
      class="loadout__panel"
    >
      <p
        v-if="!tab.slots.length && tab.hint"
        class="loadout__hint"
        :data-test="`dressing-room-${tab.key}-hint`"
      >
        {{ tab.hint }}
      </p>
      <ul
        v-else
        class="loadout__slots"
        :data-test="`dressing-room-slots-${tab.key}`"
      >
        <SlotRow
          v-for="slot in tab.slots"
          :key="slot"
          v-bind="row(slot)"
          @pick="emit('pick', slot)"
          @hold="emit('hold', slot)"
          @clear="emit('clear', slot)"
        />
      </ul>
    </div>

    <div
      v-show="active === SUPPLIES"
      role="tabpanel"
      class="loadout__panel"
      data-test="dressing-room-gear-columns"
    >
      <p
        v-if="!supplies.length && suppliesHint"
        class="loadout__hint"
        data-test="dressing-room-gear-hint"
      >
        {{ suppliesHint }}
      </p>
      <section v-for="kind in supplies" :key="kind.key" class="loadout__kind">
        <h3 class="loadout__kind-title">
          {{ t(`dressingRoom.gearColumns.${kind.key}`) }}
          <span class="loadout__kind-count">
            {{
              t("dressingRoom.filledOf", {
                count: filled(kind.slots),
                total: kind.slots.length,
              })
            }}
          </span>
        </h3>
        <ul
          class="loadout__cells"
          :data-test="`dressing-room-slots-${kind.key}`"
        >
          <SlotRow
            v-for="slot in kind.slots"
            :key="slot"
            v-bind="row(slot)"
            compact
            tile
            @pick="emit('pick', slot)"
            @clear="emit('clear', slot)"
          />
        </ul>
      </section>
    </div>
  </section>
</template>

<style lang="scss" scoped>
.loadout {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.loadout__tabs {
  display: flex;
  gap: 0.25rem;
  padding: 0.1875rem;
  border-radius: var(--radius-control);
  background: var(--color-field);
}

.loadout__tab {
  flex: 1 1 0;
  min-width: 0;
  min-height: $tap-target-min;
  padding: 0 0.5rem;
  border: 0;
  border-radius: var(--radius-control-bare);
  background: transparent;
  color: $gray-lighter;
  font-size: 0.8125rem;
  font-weight: 600;
  cursor: pointer;

  &:hover,
  &:focus-visible {
    color: $text-color;
  }
}

.loadout__tab--active {
  background: var(--color-seam);
  color: var(--color-lifted);
}

.loadout__panel {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.loadout__slots {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  margin: 0;
  padding: 0;
  list-style: none;
}

.loadout__hint {
  margin: 0;
  color: $gray-light;
}

.loadout__kind {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.loadout__kind-title {
  display: flex;
  justify-content: space-between;
  gap: 0.5rem;
  margin: 0;
  color: $gray-lighter;
  font-size: 0.75rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.loadout__kind-count {
  font-weight: 400;
  letter-spacing: normal;
  text-transform: none;
}

.loadout__cells {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0.375rem;
  margin: 0;
  padding: 0;
  list-style: none;
}
</style>
