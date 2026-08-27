<script lang="ts">
export default {
  name: "ModelHullPartsModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import CompositionBar from "@/frontend/components/Models/CompositionBar/index.vue";
import type { ModelHullPart, ModelHullDoor } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useHullParts,
  humanizeHullPart,
  HULL_CATEGORY_COLORS,
} from "@/frontend/composables/useHullParts";

type Props = {
  hullHealth?: number;
  hullParts?: ModelHullPart[];
  hullDoors?: ModelHullDoor[];
};

const props = withDefaults(defineProps<Props>(), {
  hullHealth: undefined,
  hullParts: () => [],
  hullDoors: () => [],
});

const { t, toNumber } = useI18n();

const { groups, composition, rankedParts, maxPartHealth } = useHullParts(
  () => props.hullParts,
);

const round = (value: number) => Math.round(value);
// `toNumber` renders any falsy value as "N/A", which is wrong for a genuine
// zero — nothing absorbed is a real result, not missing data.
const num = (value: number) => (value ? toNumber(value, "integer") : "0");

const hoveredCategory = ref<string | null>(null);

const barWidth = (health: number) =>
  maxPartHealth.value > 0 ? `${(health / maxPartHealth.value) * 100}%` : "0%";

// Doors are a separate area, ranked among themselves — their HP runs far above
// hull part HP on capitals, so sharing the parts scale would flatten it.
const rankedDoors = computed(() =>
  [...props.hullDoors].sort((a, b) => b.health - a.health),
);

const doorHp = computed(() =>
  rankedDoors.value.reduce((sum, door) => sum + door.health, 0),
);

const maxDoorHealth = computed(() => rankedDoors.value[0]?.health ?? 0);

const doorBarWidth = (health: number) =>
  maxDoorHealth.value > 0 ? `${(health / maxDoorHealth.value) * 100}%` : "0%";
</script>

<template>
  <Modal :title="t('labels.hull.integrity')">
    <div class="hull-modal">
      <div class="hull-tiles">
        <div class="hull-tiles__item hull-tiles__item--primary">
          <span class="hull-tiles__value">
            {{ num(round(hullHealth ?? 0)) }}
          </span>
          <span class="hull-tiles__label">{{ t("labels.hull.totalHp") }}</span>
        </div>
        <div class="hull-tiles__item">
          <span class="hull-tiles__value">
            {{ num(rankedParts.length) }}
          </span>
          <span class="hull-tiles__label">{{ t("labels.hull.parts") }}</span>
        </div>
      </div>

      <CompositionBar
        v-if="composition.length"
        :segments="composition"
        :highlighted="hoveredCategory"
        @highlight="hoveredCategory = $event"
      />

      <div class="cat-tiles">
        <div
          v-for="group in groups"
          :key="group.category"
          class="cat-tiles__item"
          @mouseenter="hoveredCategory = group.category"
          @mouseleave="hoveredCategory = null"
        >
          <span
            class="cat-tiles__swatch"
            :style="{ background: HULL_CATEGORY_COLORS[group.category] }"
          />
          <span class="cat-tiles__label">{{ t(group.label) }}</span>
          <span class="cat-tiles__count">{{ group.parts.length }}</span>
          <span class="cat-tiles__hp">
            <template v-if="group.total > 0">
              {{ num(round(group.total)) }} hp
            </template>
            <template v-else>{{ t("labels.hull.noHp") }}</template>
          </span>
        </div>
      </div>

      <div class="parts-head">{{ t("labels.hull.partsTree") }}</div>

      <div class="parts-scroll">
        <table class="parts-table">
          <tbody>
            <tr
              v-for="part in rankedParts"
              :key="part.name"
              :class="{
                'parts-table__row--dim':
                  hoveredCategory !== null && part.category !== hoveredCategory,
              }"
            >
              <td class="parts-table__name">
                {{ humanizeHullPart(part.name) }}
              </td>
              <td class="parts-table__cat">
                <span
                  class="parts-table__chip"
                  :style="{ color: HULL_CATEGORY_COLORS[part.category] }"
                >
                  {{ t(`labels.hull.category.${part.category}`) }}
                </span>
              </td>
              <td class="parts-table__bar">
                <span v-if="part.health > 0" class="parts-table__track">
                  <span
                    class="parts-table__fill"
                    :style="{
                      width: barWidth(part.health),
                      background: HULL_CATEGORY_COLORS[part.category],
                    }"
                  />
                </span>
              </td>
              <td class="num">
                <template v-if="part.health > 0">
                  {{ num(round(part.health)) }}
                </template>
                <span v-else class="parts-table__nohp">
                  {{ t("labels.hull.noHp") }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <template v-if="rankedDoors.length">
        <div class="parts-head parts-head--doors">
          <span>{{ t("labels.hull.doors") }}</span>
          <span class="parts-head__meta">
            {{ rankedDoors.length }} · {{ num(round(doorHp)) }} HP
          </span>
        </div>

        <table class="parts-table">
          <tbody>
            <tr v-for="door in rankedDoors" :key="door.name">
              <td class="parts-table__name">
                {{ humanizeHullPart(door.name) }}
              </td>
              <td class="parts-table__cat">
                <span class="parts-table__chip parts-table__chip--door">
                  {{ t("labels.hull.door") }}
                </span>
              </td>
              <td class="parts-table__bar">
                <span class="parts-table__track">
                  <span
                    class="parts-table__fill"
                    :style="{ width: doorBarWidth(door.health) }"
                  />
                </span>
              </td>
              <td class="num">{{ num(round(door.health)) }}</td>
            </tr>
          </tbody>
        </table>

        <p class="parts-note">{{ t("labels.hull.doorsNote") }}</p>
      </template>

      <p class="parts-note">{{ t("labels.hull.partsNote") }}</p>
    </div>
  </Modal>
</template>

<style lang="scss" scoped>
.hull-tiles {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-bottom: 14px;

  &__item {
    flex: 1 1 120px;
    display: flex;
    flex-direction: column;
    gap: 4px;
    padding: 10px 14px;
    min-width: 0;
    overflow: hidden;
    container-type: inline-size;
    background: $gray-black;
    border: 1px solid rgba($gray-light, 0.28);
    border-radius: 6px;
  }

  &__item--primary {
    border-color: rgba($gold, 0.5);

    .hull-tiles__value {
      color: $gold;
    }
  }

  &__value {
    font-family: "Orbitron", tahoma, sans-serif;
    font-weight: 700;
    // Capital hulls run past a million; scale to the tile so the value cannot
    // outgrow it.
    font-size: clamp(15px, 16cqw, 22px);
    line-height: 1;
    color: lighten($text-color, 15%);
    font-variant-numeric: tabular-nums;
    white-space: nowrap;
  }

  &__label {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 9px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: $gray;
  }
}

.cat-tiles {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin: 14px 0 20px;

  &__item {
    flex: 1 1 110px;
    display: grid;
    grid-template-columns: auto 1fr;
    align-items: baseline;
    gap: 2px 7px;
    padding: 8px 10px;
    background: $gray-black;
    border: 1px solid rgba($gray-light, 0.28);
    border-radius: 6px;
    cursor: default;
  }

  &__swatch {
    width: 8px;
    height: 8px;
    border-radius: 2px;
    align-self: center;
  }

  &__label {
    font-size: 11px;
    color: $gray-light;
  }

  &__count {
    grid-column: 2;
    font-family: "Orbitron", tahoma, sans-serif;
    font-weight: 700;
    font-size: 16px;
    color: lighten($text-color, 15%);
    font-variant-numeric: tabular-nums;
  }

  &__hp {
    grid-column: 2;
    font-size: 10px;
    color: $gray;
    font-variant-numeric: tabular-nums;
  }
}

.parts-head--doors {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 10px;
  margin-top: 20px;

  .parts-head__meta {
    font-family: "Open Sans", sans-serif;
    font-size: 11px;
    letter-spacing: 0;
    text-transform: none;
    color: $gray-light;
    font-variant-numeric: tabular-nums;
  }
}

.parts-head {
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 9px;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: $gray;
  padding-bottom: 6px;
  border-bottom: 1px solid rgba($gray-light, 0.28);
}

// The modal body is itself a scroll container, so an inner scroller with its
// own max-height gives two nested scrollbars. Capping this wrapper at the same
// height instead means the body never needs to scroll and only the part list
// does.
.hull-modal {
  display: flex;
  flex-direction: column;
  max-height: calc(100vh - 15rem);
}

.parts-scroll {
  flex: 1 1 auto;
  min-height: 0;
  overflow-x: hidden;
  overflow-y: auto;
}

.parts-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;

  td {
    padding: 7px 10px 7px 0;
    border-bottom: 1px solid rgba($gray-light, 0.18);
    color: $text-color;
  }

  tr:last-child td {
    border-bottom: 0;
  }

  &__row--dim {
    opacity: 0.35;
  }

  &__name {
    color: lighten($text-color, 15%);
    white-space: nowrap;
  }

  &__cat {
    width: 1%;
  }

  &__chip--door {
    color: $primary;
  }

  &__chip {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 8.5px;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    white-space: nowrap;
  }

  &__bar {
    width: 40%;
  }

  &__track {
    display: block;
    height: 6px;
    border-radius: 999px;
    background: rgba($gray-light, 0.16);
    overflow: hidden;
  }

  &__fill {
    display: block;
    background: $primary;
    height: 100%;
    border-radius: 999px;
  }

  .num {
    text-align: right;
    padding-right: 0;
    font-variant-numeric: tabular-nums;
    white-space: nowrap;
  }

  &__nohp {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 8.5px;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    color: $gray;
  }

  @media (max-width: 576px) {
    &__bar {
      display: none;
    }
  }
}

.parts-note {
  margin: 14px 0 0;
  font-size: 11px;
  color: $gray;
}
</style>
