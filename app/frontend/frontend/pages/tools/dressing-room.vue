<script lang="ts">
export default {
  name: "ToolsDressingRoomPage",
};
</script>

<script lang="ts" setup>
import { useQueries } from "@tanstack/vue-query";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
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
  OutfitBodyEnum,
  OutfitSlotEnum,
  type OutfitWeaponSlotEnum,
  getEquipmentItemQueryOptions,
  useCharacterBodies,
} from "@/services/fyApi";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import {
  ALL_SLOTS,
  BACKPACK_MOUNT,
  RIFLE_HOLD_CLIP,
  RIG_ORDER,
  handMount,
  OUTFIT_SLOTS,
  type OutfitSelection,
  type PieceHolo,
  STOWED_MOUNTS,
  WEAPON_SLOTS,
  attachment,
  clipLabel,
  isWeaponSlot,
  outfitModel,
  outfitQuery,
  parseOutfitQuery,
  pieceHolo,
  riggedOutfitModel,
  riggedPieceHolo,
} from "@/frontend/utils/dressingRoom";
import {
  type SlotFit,
  fitsSlot,
  providerNames,
  slotFit,
} from "@/frontend/utils/dressingRoomFit";

// The figure faces -Z, as the game's characters face its +Y: the camera starts
// in front of it.
const HOLO_AZIMUTH = 180;

// A little above the chest, looking down at the figure on its pedestal.
const HOLO_ELEVATION = 8;

const viewer = ref<InstanceType<typeof HoloViewer>>();

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

const BODY_KEYS = Object.values(OutfitBodyEnum);

const bodyKey = computed(() => {
  const key = queryValue("body");

  return BODY_KEYS.includes(key as OutfitBodyEnum)
    ? (key as OutfitBodyEnum)
    : OutfitBodyEnum.MALE;
});

const poseName = computed(() => queryValue("pose"));

// The weapon in hand, only while the outfit carries it.
const heldWeapon = computed(() => {
  const held = queryValue("held");

  return isWeaponSlot(held) && selection.value[held] ? held : undefined;
});

type NavigationState = {
  outfit?: string;
  pose?: string;
  held?: OutfitWeaponSlotEnum;
  body?: OutfitBodyEnum;
};

const navigate = (next: OutfitSelection, state: NavigationState = {}) => {
  const query: NavigationState = {
    outfit: activeOutfitId.value,
    pose: poseName.value,
    held: heldWeapon.value,
    body: bodyKey.value,
    ...state,
  };

  // The usual body is left out of the address.
  if (query.body === OutfitBodyEnum.MALE) query.body = undefined;

  if (query.held && !next[query.held]) query.held = undefined;

  return router.replace({
    name: "dressing-room",
    query: { ...outfitQuery(next), ...query },
  });
};

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
  void navigate({}, { outfit: undefined, pose: undefined, held: undefined });
};

const toggleHeld = (slot: OutfitSlotEnum) => {
  if (!isWeaponSlot(slot)) return;

  void navigate(selection.value, {
    held: heldWeapon.value === slot ? undefined : slot,
  });
};

const loadOutfit = (outfit: Outfit) => {
  picking.value = undefined;
  void navigate(
    Object.fromEntries(
      outfit.items.map((item) => [item.slot, item.equipment.slug]),
    ),
    {
      outfit: outfit.id,
      held: outfit.heldWeapon ?? undefined,
      body: outfit.body,
    },
  );
};

const setActiveOutfit = (id: string | undefined) => {
  void navigate(selection.value, { outfit: id });
};

const SLOT_GROUPS = [
  { key: "armour", slots: OUTFIT_SLOTS },
  { key: "weapons", slots: WEAPON_SLOTS },
];

const selectedSlots = computed(() =>
  ALL_SLOTS.filter((slot) => selection.value[slot]),
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

// What each slot may take, from the ports of what is worn: an arms slot on a
// flight suit takes nothing, a light core takes a light backpack only.
const slotFits = computed(
  () =>
    Object.fromEntries(
      ALL_SLOTS.map((slot) => [slot, slotFit(slot, items.value)]),
    ) as Record<OutfitSlotEnum, SlotFit>,
);

// Why a slot cannot take its piece, or anything at all; nothing when it fits.
const fitNote = (slot: OutfitSlotEnum) => {
  const fit = slotFits.value[slot];

  if (fit.kind === "none") {
    return t("dressingRoom.fit.noPort", { item: providerNames(fit) });
  }

  const item = items.value[slot];
  if (item && !fitsSlot(fit, item)) {
    return t("dressingRoom.fit.doesNotFit", { item: providerNames(fit) });
  }

  return undefined;
};

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

// A body that does not load leaves the pieces to stand on their own -- that
// body: another one, however it is picked, is tried afresh.
const bodyFailed = ref(false);

watch(bodyKey, () => {
  bodyFailed.value = false;
});

const body = computed(() =>
  bodyFailed.value
    ? undefined
    : bodies.value?.find(
        (entry) => entry.key === bodyKey.value && entry.holo?.url,
      ),
);

// On a body, armour is drawn only from its rig for that body: a static holo is
// modelled in another pose and would not sit on it. Rigid things -- weapons, a
// backpack without a rig -- are pinned to a bone from their ordinary holo.
const riggedHolos = computed(
  () =>
    Object.fromEntries(
      OUTFIT_SLOTS.map((slot) => [
        slot,
        riggedPieceHolo(items.value[slot]?.media, bodyKey.value),
      ]),
    ) as Partial<Record<OutfitSlotEnum, PieceHolo>>,
);

const staticHolos = computed(
  () =>
    Object.fromEntries(
      ALL_SLOTS.map((slot) => [
        slot,
        pieceHolo(items.value[slot]?.media, failedPaths.value),
      ]),
    ) as Partial<Record<OutfitSlotEnum, PieceHolo>>,
);

const pinnedBackpack = computed(() =>
  body.value && !riggedHolos.value[OutfitSlotEnum.BACKPACK]
    ? staticHolos.value[OutfitSlotEnum.BACKPACK]
    : undefined,
);

// What each slot is drawn from, or nothing: the slot list says which are not.
const holos = computed(
  () =>
    Object.fromEntries(
      ALL_SLOTS.map((slot) => {
        if (!body.value) {
          return [
            slot,
            isWeaponSlot(slot) ? undefined : staticHolos.value[slot],
          ];
        }
        if (isWeaponSlot(slot)) return [slot, staticHolos.value[slot]];
        if (slot === OutfitSlotEnum.BACKPACK) {
          return [slot, riggedHolos.value[slot] ?? pinnedBackpack.value];
        }

        return [slot, riggedHolos.value[slot]];
      }),
    ) as Partial<Record<OutfitSlotEnum, PieceHolo>>,
);

// Undersuit first, so a figure without a body is rooted on the layer the
// armour sits on, and the core before the backpack that hangs from it.
const pieces = computed(() =>
  RIG_ORDER.flatMap((slot) => {
    const holo = body.value ? riggedHolos.value[slot] : holos.value[slot];

    return holo ? [holo] : [];
  }),
);

// A held weapon sits on its grip, which is its holo's origin. A stowed one
// hangs by a helper on itself, and is drawn only once the export lists where
// that is: hung by its grip it sticks out of the holster.
const weaponPlacement = (slot: OutfitSlotEnum) => {
  const holo = staticHolos.value[slot];
  if (!holo) return undefined;

  if (heldWeapon.value === slot) {
    return attachment(holo, handMount(body.value));
  }

  // With a backpack on, the game hangs a rifle from the backpack's own mount,
  // which its rig does not carry yet: hung from the core's, it would sit
  // inside the pack.
  if (onBackpack(slot)) return undefined;

  const mount = STOWED_MOUNTS[slot];
  const placed =
    mount && attachment(holo, mount, items.value[slot]?.attachPoints);

  return placed?.helper ? placed : undefined;
};

const onBackpack = (slot: OutfitSlotEnum) => {
  const port =
    slot === OutfitSlotEnum.PRIMARY
      ? "wep_stocked_3"
      : slot === OutfitSlotEnum.SECONDARY
        ? "wep_stocked_2"
        : undefined;
  const ports = items.value[OutfitSlotEnum.BACKPACK]?.fit?.ports ?? [];

  return !!port && ports.some((candidate) => candidate.name === port);
};

const positionPending = (slot: OutfitSlotEnum) =>
  isWeaponSlot(slot) &&
  !!body.value &&
  !!staticHolos.value[slot] &&
  heldWeapon.value !== slot &&
  !weaponPlacement(slot);

const attachments = computed(() => [
  ...(pinnedBackpack.value
    ? [
        attachment(
          pinnedBackpack.value,
          BACKPACK_MOUNT,
          items.value[OutfitSlotEnum.BACKPACK]?.attachPoints,
        ),
      ]
    : []),
  ...WEAPON_SLOTS.flatMap((slot) => {
    const placed = weaponPlacement(slot);

    return placed ? [placed] : [];
  }),
]);

const model = computed(() =>
  body.value
    ? riggedOutfitModel(
        body.value,
        pieces.value,
        pose.value,
        attachments.value,
        OUTFIT_SLOTS.filter((slot) => riggedHolos.value[slot]),
      )
    : outfitModel(pieces.value),
);

// A rifle in hand is held, unless the address picks another pose.
const pose = computed(() => {
  if (poseName.value) return poseName.value;

  const holdsRifle =
    heldWeapon.value === OutfitSlotEnum.PRIMARY ||
    heldWeapon.value === OutfitSlotEnum.SECONDARY;
  const holdable = body.value?.clips.some(
    (clip) => clip.name === RIFLE_HOLD_CLIP,
  );

  return holdsRifle && holdable ? RIFLE_HOLD_CLIP : undefined;
});

const holoUnavailable = () => {
  const root = model.value;
  if (!root) return;

  if (root.rig) {
    bodyFailed.value = true;
  } else if (root.textured) {
    failedPaths.value = [...failedPaths.value, root.path];
  }
};

// The bodies the export has, in the order the enum lists them.
const bodyOptions = computed(() =>
  BODY_KEYS.filter((key) =>
    bodies.value?.some((entry) => entry.key === key && entry.holo?.url),
  ),
);

const selectBody = (key: OutfitBodyEnum) => {
  void navigate(selection.value, { body: key });
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
    void navigate(selection.value, { pose });
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

// Everything that makes the outfit what it looks like, and nothing of the
// sharer's own: their saved outfit stays out of it.
const shareUrl = computed(
  () =>
    new URL(
      router.resolve({
        name: "dressing-room",
        query: {
          ...outfitQuery(selection.value),
          held: heldWeapon.value,
          pose: poseName.value,
          body:
            bodyKey.value === OutfitBodyEnum.MALE ? undefined : bodyKey.value,
        },
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
          ref="viewer"
          :key="model.path"
          :models="[model]"
          :azimuth="HOLO_AZIMUTH"
          :elevation="HOLO_ELEVATION"
          :auto-rotate="false"
          :contain-padding="1.08"
          contain
          zoomable
          turntable
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
            v-if="model"
            :size="BtnSizesEnum.SM"
            :aria-label="t('actions.vehicleOverview.fullscreenHolo')"
            v-tooltip="t('actions.vehicleOverview.fullscreenHolo')"
            data-test="dressing-room-fullscreen"
            @click="viewer?.enableFullscreen()"
          >
            <i class="fa-light fa-expand" />
          </Btn>
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

      <aside class="dressing-room__side dressing-room__side--pieces">
        <SlotPicker
          v-if="picking"
          :slot="picking"
          :selected-slug="selection[picking]"
          :fit="slotFits[picking]"
          @select="choose(picking, $event)"
          @close="picking = undefined"
        />
        <div v-else class="dressing-room__groups">
          <section
            v-for="group in SLOT_GROUPS"
            :key="group.key"
            class="dressing-room__group"
          >
            <h2 class="dressing-room__group-title">
              {{ t(`dressingRoom.groups.${group.key}`) }}
            </h2>
            <ul
              class="dressing-room__slots"
              :data-test="`dressing-room-slots-${group.key}`"
            >
              <li
                v-for="slot in group.slots"
                :key="slot"
                class="dressing-room__slot"
                :data-test="`dressing-room-slot-${slot}`"
              >
                <button
                  type="button"
                  class="dressing-room__slot-pick"
                  :data-test="`dressing-room-pick-${slot}`"
                  :disabled="slotFits[slot].kind === 'none' && !selection[slot]"
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
                    v-if="fitNote(slot)"
                    class="dressing-room__slot-note dressing-room__slot-note--warning"
                    :data-test="`dressing-room-fit-${slot}`"
                  >
                    {{ fitNote(slot) }}
                  </span>
                  <span
                    v-else-if="items[slot] && positionPending(slot)"
                    class="dressing-room__slot-note"
                    :data-test="`dressing-room-position-pending-${slot}`"
                  >
                    {{ t("dressingRoom.positionPending") }}
                  </span>
                  <span
                    v-else-if="items[slot] && !holos[slot]"
                    class="dressing-room__slot-note"
                    :data-test="`dressing-room-no-holo-${slot}`"
                  >
                    {{ t("dressingRoom.noHolo") }}
                  </span>
                </button>
                <Btn
                  v-if="isWeaponSlot(slot) && items[slot] && holos[slot]"
                  :size="BtnSizesEnum.SM"
                  :variant="BtnVariantsEnum.BARE"
                  :active="heldWeapon === slot"
                  :aria-pressed="heldWeapon === slot"
                  :aria-label="t('dressingRoom.hold')"
                  v-tooltip="t('dressingRoom.hold')"
                  :data-test="`dressing-room-hold-${slot}`"
                  @click="toggleHeld(slot)"
                >
                  <i class="fa-light fa-hand" />
                </Btn>
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
          </section>
        </div>
      </aside>

      <aside class="dressing-room__side dressing-room__side--outfit">
        <BtnGroup
          v-if="bodyOptions.length > 1"
          segmented
          class="dressing-room__bodies"
          data-test="dressing-room-bodies"
        >
          <Btn
            v-for="option in bodyOptions"
            :key="option"
            :active="option === bodyKey"
            :data-test="`dressing-room-body-${option}`"
            @click="selectBody(option)"
          >
            {{ t(`dressingRoom.bodies.${option}`) }}
          </Btn>
        </BtnGroup>
        <BaseSelect
          v-if="poseOptions.length > 1"
          v-model="selectedPose"
          name="dressing-room-pose"
          :label="t('dressingRoom.pose')"
          :options="poseOptions"
          :searchable="false"
          data-test="dressing-room-pose"
        />
        <Outfits
          :items="outfitItems"
          :held-weapon="heldWeapon"
          :body="bodyKey"
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
  grid-template-areas:
    "stage"
    "pieces"
    "outfit";
  grid-template-columns: minmax(0, 1fr);
  gap: 1.5rem;

  @media (min-width: $desktop-breakpoint) {
    grid-template-areas: "pieces stage outfit";
    grid-template-columns: minmax(16rem, 1fr) auto minmax(16rem, 1fr);
    align-items: start;
  }
}

// Portrait, as a standing figure is: a landscape stage left most of itself
// empty either side of it.
.dressing-room__stage {
  position: relative;
  grid-area: stage;
  height: min(70vh, 48rem);
  min-height: 24rem;
  border-radius: 4px;
  // No box of its own: the page shows through, lit by a spot behind the
  // figure and a glow on the floor under its pedestal.
  background:
    radial-gradient(
      ellipse 42% 12% at 50% 90%,
      rgba($primary, 0.28),
      transparent 70%
    ),
    radial-gradient(
      ellipse 55% 60% at 50% 42%,
      rgba($primary, 0.16),
      rgba($background, 0.35) 70%,
      transparent 100%
    );

  @media (min-width: $desktop-breakpoint) {
    height: min(78vh, 56rem);
    aspect-ratio: 3 / 4;
  }
}

.dressing-room__side--pieces {
  grid-area: pieces;
}

.dressing-room__side--outfit {
  grid-area: outfit;
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

.dressing-room__groups {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.dressing-room__group-title {
  margin: 0 0 0.5rem;
  font-size: 1rem;
  color: $gray-lighter;
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

.dressing-room__slot-note--warning {
  color: $warning;
}
</style>
