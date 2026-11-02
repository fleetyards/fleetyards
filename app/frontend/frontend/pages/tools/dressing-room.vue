<script lang="ts">
export default {
  name: "ToolsDressingRoomPage",
};
</script>

<script lang="ts" setup>
import { useQueries } from "@tanstack/vue-query";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import HoloViewer from "@/shared/components/HoloViewer/index.vue";
import SlotPicker from "@/frontend/components/DressingRoom/SlotPicker/index.vue";
import Outfits from "@/frontend/components/DressingRoom/Outfits/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import copyText from "@/shared/utils/CopyText";
import {
  type Equipment,
  type Outfit,
  type OutfitItemInput,
  type OutfitSlotEnum,
  getEquipmentItemQueryOptions,
  useCharacterBodies,
} from "@/services/fyApi";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import {
  OUTFIT_SLOTS,
  type OutfitSelection,
  type PieceHolo,
  clipLabel,
  outfitModel,
  outfitQuery,
  parseOutfitQuery,
  pieceHolo,
  riggedOutfitModel,
  riggedPieceHolo,
} from "@/frontend/utils/dressingRoom";

// The only body exported so far; the others join as the export adds them.
const BODY_KEY = "male";

// The figure faces +Z in the export; a quarter turn shows it from the front
// at an angle.
const HOLO_AZIMUTH = 30;

const { t } = useI18n();
const { displayAlert, displaySuccess } = useAppNotifications();

const route = useRoute();
const router = useRouter();

const selection = computed<OutfitSelection>(() =>
  parseOutfitQuery(route.query),
);

const queryValue = (key: string) => {
  const value = [route.query[key]].flat()[0];

  return typeof value === "string" && value ? value : undefined;
};

const activeOutfitId = computed(() => queryValue("outfit"));

const poseName = computed(() => queryValue("pose"));

const navigate = (
  next: OutfitSelection,
  outfitId = activeOutfitId.value,
  pose = poseName.value,
) =>
  router.replace({
    name: "dressing-room",
    query: { ...outfitQuery(next), outfit: outfitId, pose },
  });

const picking = ref<OutfitSlotEnum>();

const choose = (slot: OutfitSlotEnum, item: Equipment) => {
  picking.value = undefined;
  void navigate({ ...selection.value, [slot]: item.slug });
};

const clear = (slot: OutfitSlotEnum) => {
  void navigate({ ...selection.value, [slot]: undefined });
};

const reset = () => {
  picking.value = undefined;
  void navigate({}, undefined, undefined);
};

const loadOutfit = (outfit: Outfit) => {
  picking.value = undefined;
  void navigate(
    Object.fromEntries(
      outfit.items.map((item) => [item.slot, item.equipment.slug]),
    ),
    outfit.id,
  );
};

const setActiveOutfit = (id: string | undefined) => {
  void navigate(selection.value, id);
};

const selectedSlots = computed(() =>
  OUTFIT_SLOTS.filter((slot) => selection.value[slot]),
);

const itemQueries = useQueries({
  queries: computed(() =>
    selectedSlots.value.map((slot) =>
      getEquipmentItemQueryOptions(selection.value[slot] as string, {
        query: { retry: false, refetchOnWindowFocus: false },
      }),
    ),
  ),
});

const items = computed(
  () =>
    Object.fromEntries(
      selectedSlots.value.map((slot, index) => [
        slot,
        itemQueries.value[index]?.data,
      ]),
    ) as Partial<Record<OutfitSlotEnum, Equipment>>,
);

const loadingSlot = (slot: OutfitSlotEnum) =>
  !!selection.value[slot] &&
  !items.value[slot] &&
  !!itemQueries.value[selectedSlots.value.indexOf(slot)]?.isLoading;

const missingSlot = (slot: OutfitSlotEnum) =>
  !!selection.value[slot] &&
  !!itemQueries.value[selectedSlots.value.indexOf(slot)]?.isError;

// Painted holos that did not load, so the figure is drawn in clay instead.
const failedPaths = ref<string[]>([]);

const { data: bodies } = useCharacterBodies({
  query: { retry: false, refetchOnWindowFocus: false },
});

// A body that does not load leaves the pieces to stand on their own.
const bodyFailed = ref(false);

const body = computed(() =>
  bodyFailed.value
    ? undefined
    : bodies.value?.find((entry) => entry.key === BODY_KEY && entry.holo?.url),
);

// On a body only the pieces rigged to it are drawn: a static holo is modelled
// in another pose and would not sit on it.
const holos = computed(
  () =>
    Object.fromEntries(
      OUTFIT_SLOTS.map((slot) => {
        const media = items.value[slot]?.media;

        return [
          slot,
          body.value
            ? riggedPieceHolo(media)
            : pieceHolo(media, failedPaths.value),
        ];
      }),
    ) as Partial<Record<OutfitSlotEnum, PieceHolo>>,
);

// Undersuit first, so a figure without a body is rooted on the layer the
// armour sits on.
const pieces = computed(() =>
  [...OUTFIT_SLOTS]
    .reverse()
    .flatMap((slot) => (holos.value[slot] ? [holos.value[slot]] : [])),
);

const model = computed(() =>
  body.value
    ? riggedOutfitModel(body.value, pieces.value, poseName.value)
    : outfitModel(pieces.value),
);

const holoUnavailable = () => {
  const root = model.value;
  if (!root) return;

  if (root.rig) {
    bodyFailed.value = true;
  } else if (root.textured) {
    failedPaths.value = [...failedPaths.value, root.path];
  }
};

const poseOptions = computed(() =>
  (body.value?.clips ?? []).map((clip) => ({
    label: clipLabel(clip.name),
    value: clip.name,
  })),
);

const selectedPose = computed({
  get: () => model.value?.rig?.clip,
  set: (pose?: string) => {
    void navigate(selection.value, activeOutfitId.value, pose);
  },
});

// A piece still loading, or one the address names but the catalogue no longer
// has: saving now would drop it from the outfit.
const piecesPending = computed(() =>
  selectedSlots.value.some((slot) => loadingSlot(slot) || missingSlot(slot)),
);

const outfitItems = computed<OutfitItemInput[]>(() =>
  selectedSlots.value.flatMap((slot) => {
    const item = items.value[slot];

    return item ? [{ slot, equipmentId: item.id }] : [];
  }),
);

const shareUrl = computed(
  () =>
    new URL(
      router.resolve({
        name: "dressing-room",
        query: outfitQuery(selection.value),
      }).href,
      window.location.origin,
    ).href,
);

const copyShareLink = () => {
  copyText(shareUrl.value).then(
    () => displaySuccess({ text: t("dressingRoom.messages.linkCopied") }),
    () => displayAlert({ text: t("dressingRoom.messages.copyFailed") }),
  );
};
</script>

<template>
  <div class="dressing-room-page">
    <Heading hero>{{ t(`headlines.${route.meta.title}`) }}</Heading>
    <p class="dressing-room-page__lead">{{ t("dressingRoom.lead") }}</p>

    <div class="dressing-room">
      <div class="dressing-room__stage" data-test="dressing-room-stage">
        <HoloViewer
          v-if="model"
          :key="model.path"
          :models="[model]"
          :azimuth="HOLO_AZIMUTH"
          :auto-rotate="false"
          contain
          zoomable
          @unavailable="holoUnavailable"
        />
        <div
          v-else
          class="dressing-room__empty"
          data-test="dressing-room-empty"
        >
          <i class="fa-duotone fa-person" />
          <p>{{ t("dressingRoom.empty") }}</p>
        </div>
        <div class="dressing-room__actions">
          <Btn
            :size="BtnSizesEnum.SM"
            :disabled="!selectedSlots.length"
            data-test="dressing-room-copy-link"
            @click="copyShareLink"
          >
            <i class="fa-light fa-link" />
            {{ t("dressingRoom.copyLink") }}
          </Btn>
          <Btn
            :size="BtnSizesEnum.SM"
            :variant="BtnVariantsEnum.GHOST"
            :disabled="!selectedSlots.length && !activeOutfitId"
            data-test="dressing-room-reset"
            @click="reset"
          >
            <i class="fa-light fa-undo" />
            {{ t("actions.reset") }}
          </Btn>
        </div>
      </div>

      <aside class="dressing-room__side">
        <BaseSelect
          v-if="poseOptions.length > 1"
          v-model="selectedPose"
          name="dressing-room-pose"
          :label="t('dressingRoom.pose')"
          :options="poseOptions"
          :searchable="false"
          data-test="dressing-room-pose"
        />
        <SlotPicker
          v-if="picking"
          :slot="picking"
          :selected-slug="selection[picking]"
          @select="choose(picking, $event)"
          @close="picking = undefined"
        />
        <ul v-else class="dressing-room__slots" data-test="dressing-room-slots">
          <li
            v-for="slot in OUTFIT_SLOTS"
            :key="slot"
            class="dressing-room__slot"
            :data-test="`dressing-room-slot-${slot}`"
          >
            <button
              type="button"
              class="dressing-room__slot-pick"
              :data-test="`dressing-room-pick-${slot}`"
              @click="picking = slot"
            >
              <span class="dressing-room__slot-label">
                {{ t(`dressingRoom.slots.${slot}`) }}
              </span>
              <span v-if="items[slot]" class="dressing-room__slot-item">
                {{ items[slot]?.name }}
              </span>
              <span
                v-else-if="loadingSlot(slot)"
                class="dressing-room__slot-item"
              >
                …
              </span>
              <span
                v-else-if="missingSlot(slot)"
                class="dressing-room__slot-item dressing-room__slot-item--missing"
              >
                {{ t("dressingRoom.notFound") }}
              </span>
              <span
                v-else
                class="dressing-room__slot-item dressing-room__slot-item--empty"
              >
                {{ t("dressingRoom.choose") }}
              </span>
              <span
                v-if="items[slot] && !holos[slot]"
                class="dressing-room__slot-note"
                :data-test="`dressing-room-no-holo-${slot}`"
              >
                {{ t("dressingRoom.noHolo") }}
              </span>
            </button>
            <Btn
              v-if="items[slot]"
              :size="BtnSizesEnum.SM"
              :variant="BtnVariantsEnum.BARE"
              :to="{
                name: 'equipment-item',
                params: { slug: items[slot]?.slug },
              }"
              :aria-label="t('dressingRoom.openItem')"
            >
              <i class="fa-light fa-arrow-up-right-from-square" />
            </Btn>
            <Btn
              v-if="selection[slot]"
              :size="BtnSizesEnum.SM"
              :variant="BtnVariantsEnum.BARE"
              :aria-label="t('dressingRoom.remove')"
              :data-test="`dressing-room-clear-${slot}`"
              @click="clear(slot)"
            >
              <i class="fa-light fa-xmark" />
            </Btn>
          </li>
        </ul>

        <Outfits
          :items="outfitItems"
          :pending="piecesPending"
          :active-id="activeOutfitId"
          @load="loadOutfit"
          @active="setActiveOutfit"
        />
      </aside>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.dressing-room-page__lead {
  max-width: 60rem;
  color: $gray-lighter;
}

.dressing-room {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 1.5rem;

  @media (min-width: $desktop-breakpoint) {
    grid-template-columns: minmax(0, 2fr) minmax(18rem, 1fr);
  }
}

.dressing-room__stage {
  position: relative;
  min-height: 24rem;
  height: 60vh;
  border-radius: 4px;
  background: $gray-black;
}

.dressing-room__empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  height: 100%;
  padding: 1rem;
  color: $gray-lighter;
  text-align: center;

  i {
    font-size: 4rem;
    opacity: 0.4;
  }
}

.dressing-room__actions {
  position: absolute;
  top: 8px;
  right: 8px;
  display: flex;
  gap: 8px;
}

.dressing-room__side {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.dressing-room__slots {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  margin: 0;
  padding: 0;
  list-style: none;
}

.dressing-room__slot {
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

.dressing-room__slot-pick {
  display: grid;
  flex: 1;
  grid-template-columns: 6rem minmax(0, 1fr);
  align-items: baseline;
  column-gap: 0.75rem;
  min-width: 0;
  min-height: $tap-target-min;
  padding: 0.375rem 0.5rem;
  border: 0;
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

.dressing-room__slot-label {
  color: $gray-lighter;
}

.dressing-room__slot-item {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.dressing-room__slot-item--empty {
  color: $gray-light;
  font-style: italic;
}

.dressing-room__slot-item--missing {
  color: $warning;
}

.dressing-room__slot-note {
  grid-column: 2;
  color: $gray-light;
  font-size: 0.85em;
}
</style>
