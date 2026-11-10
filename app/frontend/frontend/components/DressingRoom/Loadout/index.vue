<script lang="ts">
export default {
  name: "DressingRoomLoadout",
};
</script>

<script lang="ts" setup>
import SlotRow from "@/frontend/components/DressingRoom/SlotRow/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { type OutfitSlotEnum } from "@/services/fyApi";

type Row = Omit<InstanceType<typeof SlotRow>["$props"], "slot"> & {
  slot: OutfitSlotEnum;
  label: string;
};

type Tab = {
  key: string;
  slots: OutfitSlotEnum[];
};

type Props = {
  tabs: Tab[];
  // The gear a pocket or holster holds, by kind.
  supplies: { key: string; slots: OutfitSlotEnum[] }[];
  // Said in a supplies tab with nothing to hold; without one, and without
  // supplies, the tab is left out.
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
  fill: [slots: OutfitSlotEnum[]];
}>();

const { t } = useI18n();

const slots = useSlots();

// Five tabs do not fit the column by name: each is an icon, and only the open
// one is named.
const TAB_ICONS: Record<string, string> = {
  armour: "fa-helmet-battle",
  weapons: "fa-person-rifle",
  gear: "fa-toolbox",
  supplies: "fa-syringe",
  storage: "fa-backpack",
};

const tabLabel = (key: string) => t(`dressingRoom.groups.${key}`);

const SUPPLIES = "supplies";
const STORAGE = "storage";

const tabKeys = computed(() => [
  ...props.tabs.map((tab) => tab.key),
  ...(props.supplies.length || props.suppliesHint ? [SUPPLIES] : []),
  ...(slots.storage ? [STORAGE] : []),
]);

const picked = ref<string>();

// The tab picked while it is offered, else the first: the gear tab goes
// when what is worn stops taking gear.
const active = computed(() =>
  picked.value && tabKeys.value.includes(picked.value)
    ? picked.value
    : tabKeys.value[0],
);

const id = useId();
const tabId = (key: string) => `${id}-tab-${key}`;
const panelId = (key: string) => `${id}-panel-${key}`;

// The arrow keys, Home and End move along the tabs, as a tab list's do.
const moveTab = (event: KeyboardEvent) => {
  const keys = tabKeys.value;
  const index = keys.indexOf(active.value ?? "");
  const next = {
    ArrowRight: (index + 1) % keys.length,
    ArrowLeft: (index - 1 + keys.length) % keys.length,
    Home: 0,
    End: keys.length - 1,
  }[event.key];
  if (next === undefined) return;

  event.preventDefault();
  picked.value = keys[next];
  document.getElementById(tabId(keys[next]))?.focus();
};

const fillLabel = (key: string) =>
  t("dressingRoom.fillAll", { kind: t(`dressingRoom.gearColumns.${key}`) });

const filled = (slots: OutfitSlotEnum[]) =>
  slots.filter((slot) => props.row(slot).selected).length;
</script>

<template>
  <section class="loadout" data-test="dressing-room-loadout">
    <div
      class="loadout__tabs"
      role="tablist"
      :aria-label="t('dressingRoom.loadout')"
      @keydown="moveTab"
    >
      <button
        v-for="key in tabKeys"
        :id="tabId(key)"
        :key="key"
        type="button"
        class="loadout__tab"
        :class="{ 'loadout__tab--active': key === active }"
        role="tab"
        :aria-selected="key === active"
        :aria-controls="panelId(key)"
        :tabindex="key === active ? 0 : -1"
        :aria-label="tabLabel(key)"
        v-tooltip="key === active ? undefined : tabLabel(key)"
        :data-test="`dressing-room-tab-${key}`"
        @click="picked = key"
      >
        <i :class="`fa-light ${TAB_ICONS[key] ?? 'fa-circle'}`" />
        <span v-if="key === active" class="loadout__tab-label">
          {{ tabLabel(key) }}
        </span>
      </button>
    </div>

    <div
      v-for="tab in tabs"
      v-show="tab.key === active"
      :id="panelId(tab.key)"
      :key="tab.key"
      role="tabpanel"
      :aria-labelledby="tabId(tab.key)"
      class="loadout__panel"
    >
      <ul class="loadout__slots" :data-test="`dressing-room-slots-${tab.key}`">
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
      v-if="tabKeys.includes(SUPPLIES)"
      v-show="active === SUPPLIES"
      :id="panelId(SUPPLIES)"
      role="tabpanel"
      :aria-labelledby="tabId(SUPPLIES)"
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
          <Btn
            v-if="kind.slots.length > 1"
            class="loadout__fill"
            :size="BtnSizesEnum.SM"
            :variant="BtnVariantsEnum.BARE"
            :aria-label="fillLabel(kind.key)"
            v-tooltip="fillLabel(kind.key)"
            :data-test="`dressing-room-fill-${kind.key}`"
            @click="emit('fill', kind.slots)"
          >
            <i class="fa-light fa-layer-group" />
          </Btn>
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

    <div
      v-if="tabKeys.includes(STORAGE)"
      v-show="active === STORAGE"
      :id="panelId(STORAGE)"
      role="tabpanel"
      :aria-labelledby="tabId(STORAGE)"
      class="loadout__panel"
    >
      <slot name="storage" />
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
  display: flex;
  flex: 1 1 0;
  align-items: center;
  justify-content: center;
  gap: 0.375rem;
  min-width: $tap-target-min;
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

.loadout__tab-label {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.loadout__tab--active {
  flex-grow: 2.5;
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
  align-items: center;
  gap: 0.5rem;
  margin: 0;
  color: $gray-lighter;
  font-size: 0.75rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.loadout__kind-count {
  margin-left: auto;
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
