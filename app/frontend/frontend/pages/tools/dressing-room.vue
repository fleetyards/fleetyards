<script lang="ts">
export default {
  name: "ToolsDressingRoomPage",
};
</script>

<script lang="ts" setup>
import { useQueries } from "@tanstack/vue-query";
import { storeToRefs } from "pinia";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import HoloViewer from "@/shared/components/HoloViewer/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import Characters from "@/frontend/components/DressingRoom/Characters/index.vue";
import Outfits from "@/frontend/components/DressingRoom/Outfits/index.vue";
import Loadout from "@/frontend/components/DressingRoom/Loadout/index.vue";
import StageLayout from "@/frontend/components/StageLayout/index.vue";
import StagePanel from "@/frontend/components/StagePanel/index.vue";
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
  HoldPoseWeaponEnum,
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
  GEAR_SLOTS,
  holdClip,
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
  slotIcon,
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

const supplyKinds = GEAR_COLUMNS.flat();

const isSupply = (slot: OutfitSlotEnum) =>
  supplyKinds.includes(gearKind(slot)?.key ?? "");

// What pockets and pouches hold, by kind, leaving out what the worn pieces
// have no slot for.
const supplies = computed(() =>
  supplyKinds
    .map((key) => ({
      key,
      slots: gearSlots.value.filter((slot) => gearKind(slot)?.key === key),
    }))
    .filter((kind) => kind.slots.length),
);

// Said in the supplies tab while nothing worn carries any; with gadget or
// tool slots in the gear tab, the tab is simply left out.
const suppliesHint = computed(() => {
  if (wornLoading.value) return "…";
  if (gearSlots.value.length) return undefined;

  return wearsGearProvider.value
    ? t("dressingRoom.gearNone")
    : t("dressingRoom.gearHint");
});

// The gear tab only while something worn takes a gadget or a tool.
const loadoutTabs = computed(() => {
  const gear = gearSlots.value.filter((slot) => !isSupply(slot));

  return [
    { key: "armour", slots: OUTFIT_SLOTS },
    { key: "weapons", slots: WEAPON_SLOTS },
    ...(gear.length ? [{ key: "gear", slots: gear }] : []),
  ];
});

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

// A supply reads by its number under its kind's heading.
const loadoutRow = (slot: OutfitSlotEnum) => {
  const supply = isSupply(slot);

  return {
    ...slotRow(slot),
    label: supply ? String(gearNumber(slot)) : slotLabel(slot),
    fullLabel: supply ? slotLabel(slot) : undefined,
    icon: supply ? undefined : slotIcon(slot),
  };
};

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
// body. Someone else's character, from a share link, cannot be saved and
// leaves the outfit's own as saved, as does not knowing the viewer's
// characters yet.
const ownFaceId = computed(() => {
  if (!faceToken.value) return null;
  if (!ownFaces.value) return undefined;

  const own = ownFaces.value.find((face) => face.token === faceToken.value);
  if (!own) return undefined;

  return own.body === bodyKey.value ? own.id : null;
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

// The character the address names, still on its way. Only a body with a
// face library can draw one.
const facePending = computed(
  () =>
    !!faceToken.value &&
    !!body.value?.faceLibrary &&
    !shownFace.value &&
    !sharedFaceMissing.value,
);

// While the next character is fetched, the query still holds the last one:
// the figure keeps it on rather than the default standing in for a moment.
const drawnFace = computed(() =>
  facePending.value ? sharedFace.value : shownFace.value,
);

// The character the address names, when it can be drawn on this body.
const chosenCharacter = computed(() => {
  const face = drawnFace.value;
  const resolved = face?.character as ResolvedCharacter | null;
  if (!body.value || !face || !resolved) return undefined;

  return characterRig(body.value, resolved, face.token, wornHeadWear.value);
});

// Without one, the game's own default character for the body: the head the
// customizer opens with.
const defaultCharacter = computed(() => {
  if (!body.value) return undefined;

  const fallback = body.value.defaultCharacter as ResolvedCharacter | null;
  if (!fallback) return undefined;

  return characterRig(
    body.value,
    fallback,
    `default:${body.value.key}`,
    wornHeadWear.value,
  );
});

const character = computed(
  () => chosenCharacter.value ?? defaultCharacter.value,
);

// Once drawn, the figure stays up while another character is fetched.
const figureDrawn = ref(false);

// A character the server has not resolved: the customizer data it needs is
// not imported yet.
const faceNotReady = computed(
  () => !!shownFace.value && !shownFace.value.character,
);

// A character the link names that cannot be drawn: gone, or for the other
// body.
const faceUnavailable = computed(
  () =>
    !!faceToken.value &&
    (sharedFaceMissing.value ||
      (!!shownFace.value &&
        (shownFace.value.body !== bodyKey.value ||
          (!!body.value &&
            !!shownFace.value.character &&
            !chosenCharacter.value)))),
);

const model = computed(() => {
  // Nothing drawn yet: the figure waits for its character.
  if (facePending.value && !figureDrawn.value) return undefined;

  return body.value
    ? riggedOutfitModel(
        body.value,
        pieces.value,
        pose.value,
        attachments.value,
        OUTFIT_SLOTS.filter((slot) => riggedHolos.value[slot]),
        failedPaths.value,
        character.value,
      )
    : outfitModel(pieces.value);
});

// A weapon in hand is held, unless the address picks another pose.
const pose = computed(() => {
  if (poseName.value) return poseName.value;

  if (!heldWeapon.value) return undefined;

  // A core still loading is worn all the same.
  const core = selection.value[OutfitSlotEnum.TORSO]
    ? (items.value[OutfitSlotEnum.TORSO] ?? {})
    : undefined;
  const weapon =
    heldWeapon.value === OutfitSlotEnum.SIDEARM
      ? HoldPoseWeaponEnum.PISTOL
      : HoldPoseWeaponEnum.RIFLE;

  return holdClip(body.value, weapon, core);
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

watch(
  model,
  (drawn) => {
    if (drawn?.rig) figureDrawn.value = true;
  },
  { immediate: true },
);

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
    <header class="dressing-room-page__header">
      <Heading hero>{{ t(`headlines.${route.meta.title}`) }}</Heading>
      <div class="dressing-room-page__actions">
        <Btn data-test="dressing-room-open-armor-sets" @click="openArmorSets">
          <i class="fa-light fa-layer-group" />
          {{ t("dressingRoom.armorSets.open") }}
        </Btn>
        <Btn
          :disabled="!selectedSlots.length && !faceToken"
          data-test="dressing-room-copy-link"
          @click="copyShareLink"
        >
          <i class="fa-light fa-link" />
          {{ t("dressingRoom.copyLink") }}
        </Btn>
      </div>
    </header>

    <StageLayout
      class="dressing-room"
      :controls-label="t('dressingRoom.viewControls')"
      data-test="dressing-room-stage"
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
        fullscreen-actions
        @unavailable="holoUnavailable"
        @unplaced="unplaced = $event"
        @fell-back="failedPaths = [...failedPaths, ...$event]"
      />
      <Loader
        v-else-if="facePending"
        :loading="true"
        data-test="dressing-room-character-loading"
      />
      <div v-else class="dressing-room__empty" data-test="dressing-room-empty">
        <i class="fa-duotone fa-person" />
        <p>{{ t("dressingRoom.empty") }}</p>
      </div>

      <template #controls>
        <BtnGroup
          v-if="bodyOptions.length > 1"
          segmented
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
          class="dressing-room__pose"
          :label="t('dressingRoom.pose')"
          :options="poseOptions"
          :searchable="false"
          no-label
          inline
          data-test="dressing-room-pose"
        />
        <Btn
          :aria-label="t('actions.reset')"
          v-tooltip="t('actions.reset')"
          :disabled="!selectedSlots.length && !activeOutfitId"
          data-test="dressing-room-reset"
          @click="reset"
        >
          <i class="fa-light fa-undo" />
        </Btn>
        <Btn
          v-if="model"
          :aria-label="t('actions.vehicleOverview.fullscreenHolo')"
          v-tooltip="t('actions.vehicleOverview.fullscreenHolo')"
          data-test="dressing-room-fullscreen"
          @click="viewer?.enableFullscreen()"
        >
          <i class="fa-light fa-expand" />
        </Btn>
      </template>

      <template #start>
        <StagePanel>
          <Loadout
            :tabs="loadoutTabs"
            :supplies="supplies"
            :supplies-hint="suppliesHint"
            :row="loadoutRow"
            @pick="openSlot"
            @hold="toggleHeld"
            @clear="clear"
          />
        </StagePanel>
      </template>

      <template #end>
        <StagePanel>
          <Characters
            :body="bodyKey"
            :token="faceToken"
            :shown="shownFace"
            :unavailable="faceUnavailable"
            :not-ready="faceNotReady"
            @select="selectFace"
          />
        </StagePanel>
        <StagePanel>
          <WornStorage
            :stored="stored"
            :worn="items"
            :stored-items="storedItems"
            :loading="storedLoading || wornLoading"
            @add="openStorage"
            @quantity="changeStored"
          />
        </StagePanel>
        <StagePanel>
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
        </StagePanel>
      </template>
    </StageLayout>
  </div>
</template>

<style lang="scss" scoped>
.dressing-room-page__header {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem 1.5rem;
  margin-bottom: 1rem;
}

.dressing-room-page__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.dressing-room__pose {
  min-width: 10rem;
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
</style>
