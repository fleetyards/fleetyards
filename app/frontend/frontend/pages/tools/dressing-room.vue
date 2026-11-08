<script lang="ts">
export default {
  name: "ToolsDressingRoomPage",
};
</script>

<script lang="ts" setup>
import { useQueries } from "@tanstack/vue-query";
import { onClickOutside } from "@vueuse/core";
import { storeToRefs } from "pinia";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import HoloViewer from "@/shared/components/HoloViewer/index.vue";
import Characters from "@/frontend/components/DressingRoom/Characters/index.vue";
import Outfits from "@/frontend/components/DressingRoom/Outfits/index.vue";
import SlotRow from "@/frontend/components/DressingRoom/SlotRow/index.vue";
import WornStorage from "@/frontend/components/DressingRoom/WornStorage/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import copyText from "@/shared/utils/CopyText";
import {
  type ArmorSet,
  type Equipment,
  type Outfit,
  type OutfitHolderEnum,
  type OutfitItemInput,
  type OutfitStoredItemInput,
  OutfitBodyEnum,
  OutfitSlotEnum,
  type OutfitWeaponSlotEnum,
  getEquipmentItemQueryOptions,
  useCharacterBodies,
  useCharacterFaces,
  useSharedCharacterFace,
} from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import type { ResolvedCharacter } from "@/shared/components/HoloViewer/character/types";
import { characterRig } from "@/frontend/utils/dressingRoomCharacter";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import {
  ALL_SLOTS,
  BACKPACK_MOUNT,
  GEAR_COLUMNS,
  GEAR_KINDS,
  GEAR_SLOTS,
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
  gearKind,
  gearNumber,
  isGearSlot,
  isWeaponSlot,
  outfitModel,
  outfitQuery,
  parseOutfitQuery,
  pieceHolo,
  riggedOutfitModel,
  riggedPieceHolo,
  visibleGearSlots,
  wearArmorSet,
} from "@/frontend/utils/dressingRoom";
import {
  type SlotFit,
  fitsSlot,
  gearMount,
  portProvider,
  providerNames,
  slotFit,
} from "@/frontend/utils/dressingRoomFit";
import {
  HOLDERS,
  type StoredSelection,
  addStored,
  holderProblem,
  parseStoredQuery,
  setStoredQuantity,
  storedQuery,
  storedSlugs,
  usedSpace,
  wornInventory,
} from "@/frontend/utils/dressingRoomStorage";

// The figure faces -Z, as the game's characters face its +Y: the camera starts
// in front of it.
const HOLO_AZIMUTH = 180;

// A little above the chest, looking down at the figure on its pedestal.
const HOLO_ELEVATION = 8;

const viewer = ref<InstanceType<typeof HoloViewer>>();

const stage = ref<HTMLElement>();
const stageTapped = ref(false);

// On click, not pointerdown: a tap's target is settled when the finger lifts, so
// revealing any earlier would hand that same tap to a button nobody could see.
// Dragging the figure round produces no click.
const handleStageClick = (event: MouseEvent) => {
  if ((event.target as Element).closest("button")) return;

  stageTapped.value = !stageTapped.value;
};

onClickOutside(stage, () => {
  stageTapped.value = false;
});

const { t } = useI18n();
const { displayAlert, displaySuccess } = useAppNotifications();

const route = useRoute();
const router = useRouter();

const selection = computed<OutfitSelection>(() =>
  parseOutfitQuery(route.query),
);

const stored = computed<StoredSelection>(() => parseStoredQuery(route.query));

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

// The character on the figure, by its token.
const faceToken = computed(() => queryValue("face"));

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
  face?: string;
};

const navigate = (
  next: OutfitSelection,
  state: NavigationState = {},
  nextStored: StoredSelection = stored.value,
) => {
  const query: NavigationState = {
    outfit: activeOutfitId.value,
    pose: poseName.value,
    held: heldWeapon.value,
    body: bodyKey.value,
    face: faceToken.value,
    ...state,
  };

  // The usual body is left out of the address.
  if (query.body === OutfitBodyEnum.MALE) query.body = undefined;

  if (query.held && !next[query.held]) query.held = undefined;

  return router.replace({
    name: "dressing-room",
    query: { ...outfitQuery(next), ...storedQuery(nextStored), ...query },
  });
};

const comlink = useComlink();

const openArmorSets = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/DressingRoom/ArmorSetsModal/index.vue"),
    props: {
      selection: selection.value,
      onSelect: (set: ArmorSet) => {
        void navigate(wearArmorSet(selection.value, set));
      },
    },
    wide: true,
  });
};

const choose = (slot: OutfitSlotEnum, item: Equipment) => {
  void navigate({ ...selection.value, [slot]: item.slug });
};

const clear = (slot: OutfitSlotEnum) => {
  void navigate({ ...selection.value, [slot]: undefined });
};

const openSlot = (slot: OutfitSlotEnum) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/DressingRoom/SlotPickerModal/index.vue"),
    props: {
      slot,
      selectedSlug: () => selection.value[slot],
      fit: () => slotFits.value[slot],
      title: slotLabel(slot),
      onSelect: (item: Equipment) => choose(slot, item),
    },
    wide: true,
  });
};

const reset = () => {
  void navigate(
    {},
    { outfit: undefined, pose: undefined, held: undefined },
    {},
  );
};

const toggleHeld = (slot: OutfitSlotEnum) => {
  if (!isWeaponSlot(slot)) return;

  void navigate(selection.value, {
    held: heldWeapon.value === slot ? undefined : slot,
  });
};

const loadOutfit = (outfit: Outfit) => {
  void navigate(
    Object.fromEntries(
      outfit.items.map((item) => [item.slot, item.equipment.slug]),
    ),
    {
      outfit: outfit.id,
      held: outfit.heldWeapon ?? undefined,
      body: outfit.body,
      face: outfit.characterFace?.token,
    },
    outfit.storedItems.reduce<StoredSelection>(
      (list, item) => ({
        ...list,
        [item.holder]: [
          ...(list[item.holder] ?? []),
          { slug: item.equipment.slug, quantity: item.quantity },
        ],
      }),
      {},
    ),
  );
};

const setActiveOutfit = (id: string | undefined) => {
  void navigate(selection.value, { outfit: id });
};

const selectFace = (token: string | undefined) => {
  void navigate(selection.value, { face: token });
};

// A numbered gear slot reads by its kind; the one of a kind needs no number.
const slotLabel = (slot: OutfitSlotEnum) => {
  const kind = gearKind(slot);
  if (!kind) return t(`dressingRoom.slots.${slot}`);

  return t(`dressingRoom.gear.${kind.key}`, { number: gearNumber(slot) });
};

// Whether the empty gear group is down to what is worn, or to nothing being.
const wearsGearProvider = computed(() =>
  GEAR_SLOTS.some((slot) => {
    const fit = slotFits.value[slot];

    return fit.kind !== "none" || fit.providers.length > 0;
  }),
);

const gearSlots = computed(() =>
  visibleGearSlots(
    selection.value,
    (slot) => slotFits.value[slot].kind === "ports",
  ),
);

const columnKinds = GEAR_COLUMNS.flat();

// The gear with a column under the stage, by column and kind, leaving out what
// the worn pieces have no slot for.
const gearColumns = computed(() =>
  GEAR_COLUMNS.map((column, index) => ({
    key: index,
    kinds: GEAR_KINDS.filter((kind) => column.includes(kind.key))
      .map((kind) => ({
        key: kind.key,
        slots: gearSlots.value.filter((slot) => kind.slots.includes(slot)),
      }))
      .filter((kind) => kind.slots.length),
  })).filter((column) => column.kinds.length),
);

const listedGearSlots = computed(() =>
  gearSlots.value.filter(
    (slot) => !columnKinds.includes(gearKind(slot)?.key ?? ""),
  ),
);

// The gear group stays while it has slots or something to say about having none.
const SLOT_GROUPS = computed(() => [
  { key: "armour", slots: OUTFIT_SLOTS },
  { key: "weapons", slots: WEAPON_SLOTS },
  ...(listedGearSlots.value.length || !gearColumns.value.length
    ? [{ key: "gear", slots: listedGearSlots.value }]
    : []),
]);

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
  // A piece still loading may be the one that offers this gear its port.
  if (isGearSlot(slot) && wornLoading.value) return undefined;

  const fit = slotFits.value[slot];

  if (fit.kind === "none") {
    return fit.providers.length
      ? t("dressingRoom.fit.noPort", { item: providerNames(fit) })
      : t("dressingRoom.fit.noWornPiece");
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

const storedItemQueries = useQueries({
  queries: computed(() =>
    storedSlugs(stored.value).map((slug) =>
      getEquipmentItemQueryOptions(slug, {
        query: { retry: false, refetchOnWindowFocus: false },
      }),
    ),
  ),
});

const storedItems = computed<Record<string, Equipment | undefined>>(() =>
  Object.fromEntries(
    storedSlugs(stored.value).map((slug, index) => [
      slug,
      storedItemQueries.value[index]?.data,
    ]),
  ),
);

const storedLoading = computed(() =>
  storedItemQueries.value.some((query) => query.isLoading),
);

const storedMissing = computed(() =>
  storedItemQueries.value.some((query) => query.isError),
);

const openStorage = (holder: OutfitHolderEnum) => {
  const inventory = wornInventory(items.value, holder);
  if (!inventory) return;

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/DressingRoom/StoredItemPickerModal/index.vue"),
    props: {
      holder,
      inventory,
      used: () => usedSpace(stored.value[holder], storedItems.value),
      onSelect: (item: Equipment) => {
        void navigate(
          selection.value,
          {},
          addStored(stored.value, holder, item.slug),
        );
      },
    },
    wide: true,
  });
};

const changeStored = (
  holder: OutfitHolderEnum,
  slug: string,
  quantity: number,
) => {
  void navigate(
    selection.value,
    {},
    setStoredQuantity(stored.value, holder, slug, quantity),
  );
};

const wornLoading = computed(() => OUTFIT_SLOTS.some(loadingSlot));

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
        riggedPieceHolo(
          items.value[slot]?.media,
          bodyKey.value,
          failedPaths.value,
        ),
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

const isCarriedSlot = (slot: OutfitSlotEnum) =>
  isWeaponSlot(slot) || isGearSlot(slot);

// What each slot is drawn from, or nothing: the slot list says which are not.
const holos = computed(
  () =>
    Object.fromEntries(
      ALL_SLOTS.map((slot) => {
        if (!body.value) {
          return [
            slot,
            isCarriedSlot(slot) ? undefined : staticHolos.value[slot],
          ];
        }
        if (isCarriedSlot(slot)) return [slot, staticHolos.value[slot]];
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
    if (!holo) return [];

    if (!body.value || slot !== OutfitSlotEnum.BACKPACK) return [holo];

    const provider = portProvider(slot, items.value);
    const from = provider && riggedHolos.value[provider]?.path;

    return [{ ...holo, hangs: true, ...(from ? { from } : {}) }];
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

  const mount = STOWED_MOUNTS[slot];
  const placed =
    mount && attachment(holo, mount, items.value[slot]?.attachPoints);
  if (!placed?.helper) return undefined;

  // The mount of the piece whose port it is in, never a namesake underneath:
  // with a backpack on, a rifle hangs from the pack rather than inside it. A
  // provider without a rig -- a pack pinned whole -- brings no mount at all.
  const provider = portProvider(slot, items.value);
  if (!provider) return placed;

  const from = riggedHolos.value[provider]?.path;

  return from ? { ...placed, from } : undefined;
};

// Gear hangs where the port of the piece carrying it says, and only where the
// item has the helper that port names: without one it would be a guess.
const gearPlacement = (slot: OutfitSlotEnum) => {
  const holo = staticHolos.value[slot];
  const mount = gearMount(slot, items.value);
  const provider = portProvider(slot, items.value);
  const from = provider && riggedHolos.value[provider]?.path;
  if (!holo || !mount || !from) return undefined;

  const placed = attachment(holo, mount, items.value[slot]?.attachPoints);

  return placed.helper ? { ...placed, from } : undefined;
};

const carriedPlacement = (slot: OutfitSlotEnum) =>
  isGearSlot(slot) ? gearPlacement(slot) : weaponPlacement(slot);

// Left off the figure by the viewer: the piece it hangs from has no mount for
// it in its rig.
const unplaced = ref<string[]>([]);

const unplacedSlot = (slot: OutfitSlotEnum) => {
  const path = isCarriedSlot(slot)
    ? carriedPlacement(slot)?.path
    : riggedHolos.value[slot]?.path;

  return !!path && unplaced.value.includes(path);
};

const positionPending = (slot: OutfitSlotEnum) =>
  !!body.value &&
  (unplacedSlot(slot) ||
    (isCarriedSlot(slot) &&
      !!staticHolos.value[slot] &&
      heldWeapon.value !== slot &&
      !carriedPlacement(slot)));

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
  ...[...WEAPON_SLOTS, ...GEAR_SLOTS].flatMap((slot) => {
    const placed = carriedPlacement(slot);

    return placed ? [placed] : [];
  }),
]);

const slotRow = (slot: OutfitSlotEnum) => ({
  slot,
  item: items.value[slot],
  selected: !!selection.value[slot],
  loading: loadingSlot(slot),
  missing: missingSlot(slot),
  disabled: slotFits.value[slot].kind === "none" && !selection.value[slot],
  warning: fitNote(slot),
  positionPending: positionPending(slot),
  noHolo: !holos.value[slot],
  holdable: isWeaponSlot(slot) && !!items.value[slot] && !!holos.value[slot],
  held: heldWeapon.value === slot,
});

const { isAuthenticated } = storeToRefs(useSessionStore());

const { data: sharedFace, isError: sharedFaceMissing } = useSharedCharacterFace(
  () => faceToken.value ?? "",
  {
    query: {
      enabled: computed(() => !!faceToken.value),
      retry: false,
      refetchOnWindowFocus: false,
    },
  },
);

const { data: ownFaces } = useCharacterFaces({
  query: { enabled: isAuthenticated, retry: false },
});

// Saved with an outfit only when it is the viewer's own, for the outfit's
// body; unknown, and left as saved, until the viewer's characters are in.
const ownFaceId = computed(() => {
  if (!faceToken.value) return null;
  if (!ownFaces.value) return undefined;

  return (
    ownFaces.value.find(
      (face) => face.token === faceToken.value && face.body === bodyKey.value,
    )?.id ?? null
  );
});

const shownFace = computed(() =>
  faceToken.value && sharedFace.value?.token === faceToken.value
    ? sharedFace.value
    : undefined,
);

// What the worn pieces do to the hair: a helmet swaps it for a cap, a closed
// one hides the head.
const wornHeadWear = computed(() =>
  OUTFIT_SLOTS.flatMap((slot) => {
    const headWear = items.value[slot]?.headWear;

    return headWear ? [{ path: riggedHolos.value[slot]?.path, headWear }] : [];
  }),
);

const character = computed(() => {
  const resolved = shownFace.value?.character as ResolvedCharacter | null;
  if (!body.value || !resolved || !faceToken.value) return undefined;

  return characterRig(
    body.value,
    resolved,
    faceToken.value,
    wornHeadWear.value,
  );
});

// A character the link names that cannot be drawn: gone, or for the other
// body.
const faceUnavailable = computed(
  () =>
    !!faceToken.value &&
    (sharedFaceMissing.value ||
      (!!shownFace.value &&
        (shownFace.value.body !== bodyKey.value ||
          (!!body.value && !!shownFace.value.character && !character.value)))),
);

const model = computed(() =>
  body.value
    ? riggedOutfitModel(
        body.value,
        pieces.value,
        pose.value,
        attachments.value,
        OUTFIT_SLOTS.filter((slot) => riggedHolos.value[slot]),
        failedPaths.value,
        character.value,
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

const holoUnavailable = (failed?: string) => {
  const root = model.value;
  if (!root) return;

  // The loader reports one failed download more than once: by then the root
  // is the fallback, which has not failed.
  if (failed && failed !== root.path) return;

  // A painted body falls back to the clay one before the figure goes.
  if (root.textured) {
    failedPaths.value = [...failedPaths.value, root.path];
  } else if (root.rig) {
    bodyFailed.value = true;
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
const piecesPending = computed(
  () =>
    selectedSlots.value.some(
      (slot) => loadingSlot(slot) || missingSlot(slot),
    ) ||
    storedLoading.value ||
    storedMissing.value,
);

const storedInputs = computed<OutfitStoredItemInput[]>(() =>
  HOLDERS.flatMap((holder) =>
    (stored.value[holder] ?? []).flatMap((entry) => {
      const item = storedItems.value[entry.slug];

      return item
        ? [{ holder, equipmentId: item.id, quantity: entry.quantity }]
        : [];
    }),
  ),
);

// What the API would refuse, each already marked where it is on the page.
const saveBlocked = computed(
  () =>
    !wornLoading.value &&
    (GEAR_SLOTS.some((slot) => !!selection.value[slot] && !!fitNote(slot)) ||
      HOLDERS.some(
        (holder) =>
          !!holderProblem(
            wornInventory(items.value, holder),
            stored.value[holder],
            storedItems.value,
          ),
      )),
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
          ...storedQuery(stored.value),
          held: heldWeapon.value,
          pose: poseName.value,
          body:
            bodyKey.value === OutfitBodyEnum.MALE ? undefined : bodyKey.value,
          face: faceToken.value,
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
      <div
        ref="stage"
        class="dressing-room__stage"
        :class="{ 'dressing-room__stage--tapped': stageTapped }"
        data-test="dressing-room-stage"
        @click="handleStageClick"
      >
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
          backdrop
          @unavailable="holoUnavailable"
          @unplaced="unplaced = $event"
          @fell-back="failedPaths = [...failedPaths, ...$event]"
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
            :disabled="!selectedSlots.length && !faceToken"
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
        <div class="dressing-room__groups">
          <section
            v-for="group in SLOT_GROUPS"
            :key="group.key"
            class="dressing-room__group"
          >
            <div class="dressing-room__group-header">
              <h2 class="dressing-room__group-title">
                {{ t(`dressingRoom.groups.${group.key}`) }}
              </h2>
              <Btn
                v-if="group.key === 'armour'"
                :size="BtnSizesEnum.SM"
                :variant="BtnVariantsEnum.GHOST"
                data-test="dressing-room-open-armor-sets"
                @click="openArmorSets"
              >
                <i class="fa-light fa-layer-group" />
                {{ t("dressingRoom.armorSets.open") }}
              </Btn>
            </div>
            <p
              v-if="group.key === 'gear' && !group.slots.length"
              class="dressing-room__group-hint"
              data-test="dressing-room-gear-hint"
            >
              {{
                wornLoading
                  ? "…"
                  : wearsGearProvider
                    ? t("dressingRoom.gearNone")
                    : t("dressingRoom.gearHint")
              }}
            </p>
            <ul
              v-else
              class="dressing-room__slots"
              :data-test="`dressing-room-slots-${group.key}`"
            >
              <SlotRow
                v-for="slot in group.slots"
                :key="slot"
                v-bind="slotRow(slot)"
                :label="slotLabel(slot)"
                @pick="openSlot(slot)"
                @hold="toggleHeld(slot)"
                @clear="clear(slot)"
              />
            </ul>
          </section>
        </div>
      </aside>

      <section
        v-if="gearColumns.length"
        class="dressing-room__gear"
        data-test="dressing-room-gear-columns"
      >
        <div
          v-for="column in gearColumns"
          :key="column.key"
          class="dressing-room__gear-column"
        >
          <template v-for="kind in column.kinds" :key="kind.key">
            <h2 class="dressing-room__group-title">
              {{ t(`dressingRoom.gearColumns.${kind.key}`) }}
            </h2>
            <ul
              class="dressing-room__slots"
              :data-test="`dressing-room-slots-${kind.key}`"
            >
              <SlotRow
                v-for="slot in kind.slots"
                :key="slot"
                v-bind="slotRow(slot)"
                :label="String(gearNumber(slot))"
                :full-label="slotLabel(slot)"
                compact
                @pick="openSlot(slot)"
                @clear="clear(slot)"
              />
            </ul>
          </template>
        </div>
      </section>

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
        <Characters
          :body="bodyKey"
          :token="faceToken"
          :shown="shownFace"
          :unavailable="faceUnavailable"
          @select="selectFace"
        />
        <WornStorage
          :stored="stored"
          :worn="items"
          :stored-items="storedItems"
          :loading="storedLoading || wornLoading"
          @add="openStorage"
          @quantity="changeStored"
        />
        <Outfits
          :items="outfitItems"
          :stored-items="storedInputs"
          :blocked="saveBlocked"
          :held-weapon="heldWeapon"
          :body="bodyKey"
          :character-face-id="ownFaceId"
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
    grid-template-areas:
      "pieces stage outfit"
      "gear gear outfit";
    grid-template-columns: minmax(16rem, 1fr) auto minmax(16rem, 1fr);
    // The first row fits the slots and the stage; the right column's lists run
    // on past it beside the gear.
    grid-template-rows: auto 1fr;
    align-items: start;
  }
}

// Portrait, as a standing figure is: a landscape stage left most of itself
// empty either side of it.
.dressing-room__stage {
  position: relative;
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
    grid-area: stage;
    height: min(78vh, 56rem);
    aspect-ratio: 3 / 4;
  }
}

// As wide as the slots and stage above: the stage's aspect ratio sizes its
// column, and long item names here must not.
.dressing-room__gear {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(11rem, 1fr));
  gap: 1.25rem;
  align-items: start;
  width: 0;
  min-width: 100%;

  @media (min-width: $desktop-breakpoint) {
    grid-area: gear;
  }
}

.dressing-room__gear-column {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.dressing-room__side--pieces {
  @media (min-width: $desktop-breakpoint) {
    grid-area: pieces;
  }
}

.dressing-room__side--outfit {
  @media (min-width: $desktop-breakpoint) {
    grid-area: outfit;
  }
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
  // Out of the figure's way until the stage is pointed at or tapped. Hidden
  // buttons must not take taps: an unseen reset would wipe the outfit.
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.15s ease;
}

// Each kind of screen has its own reveal: a touch browser can hold on to :hover
// long after the tap, and a mouse click must not pin the buttons in place.
@media (hover: hover) {
  .dressing-room__stage:hover .dressing-room__actions {
    opacity: 1;
    pointer-events: auto;
  }
}

@media (hover: none) {
  .dressing-room__stage--tapped .dressing-room__actions {
    opacity: 1;
    pointer-events: auto;
  }
}

.dressing-room__actions:focus-within {
  opacity: 1;
  pointer-events: auto;
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

.dressing-room__group-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
}

.dressing-room__group-title {
  margin: 0;
  font-size: 1rem;
  color: $gray-lighter;
}

.dressing-room__group-hint {
  margin: 0;
  color: $gray-light;
}

.dressing-room__slots {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  margin: 0;
  padding: 0;
  list-style: none;
}
</style>
