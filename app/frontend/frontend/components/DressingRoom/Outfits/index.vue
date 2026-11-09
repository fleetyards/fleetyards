<script lang="ts">
export default {
  name: "DressingRoomOutfits",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import { storeToRefs } from "pinia";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useSessionStore } from "@/frontend/stores/session";
import {
  type Outfit,
  type OutfitItemInput,
  type OutfitStoredItemInput,
  type OutfitBodyEnum,
  type OutfitWeaponSlotEnum,
  getOutfitsQueryKey,
  useCreateOutfit,
  useDestroyOutfit,
  useOutfits,
  useUpdateOutfit,
} from "@/services/fyApi";

type Props = {
  // What the outfit on screen wears, by id: what it is saved with.
  items: OutfitItemInput[];
  // What the worn pieces hold, by id.
  storedItems?: OutfitStoredItemInput[];
  activeId?: string;
  // A piece has not resolved yet, or no longer does: saving now would leave
  // it out.
  pending?: boolean;
  // Something on screen the API would refuse: gear with no port, storage that
  // does not fit.
  blocked?: boolean;
  heldWeapon?: OutfitWeaponSlotEnum;
  body?: OutfitBodyEnum;
  // The viewer's own character on the figure, saved with the outfit; left
  // as saved while it is not known yet.
  characterFaceId?: string | null;
};

const props = withDefaults(defineProps<Props>(), {
  storedItems: () => [],
  activeId: undefined,
  pending: false,
  blocked: false,
  heldWeapon: undefined,
  body: undefined,
  characterFaceId: undefined,
});

const emit = defineEmits<{
  load: [outfit: Outfit];
  active: [id: string | undefined];
}>();

const { t } = useI18n();
const { displayAlert, displaySuccess } = useAppNotifications();
const { isAuthenticated } = storeToRefs(useSessionStore());
const queryClient = useQueryClient();

const { data: outfits, isLoading } = useOutfits({
  query: { enabled: isAuthenticated, retry: false },
});

const active = computed(() =>
  outfits.value?.find((outfit) => outfit.id === props.activeId),
);

const itemsKey = (items: { slot: string; equipmentId: string }[]) =>
  items
    .map((item) => `${item.slot}:${item.equipmentId}`)
    .sort()
    .join(",");

const savedItemsKey = (outfit: Outfit) =>
  itemsKey(
    outfit.items.map((item) => ({
      slot: item.slot,
      equipmentId: item.equipment.id,
    })),
  );

const storedKey = (
  stored: { holder: string; equipmentId: string; quantity: number }[],
) =>
  stored
    .map((item) => `${item.holder}:${item.equipmentId}:${item.quantity}`)
    .sort()
    .join(",");

const savedStoredKey = (outfit: Outfit) =>
  storedKey(
    outfit.storedItems.map((item) => ({
      holder: item.holder,
      equipmentId: item.equipment.id,
      quantity: item.quantity,
    })),
  );

const name = ref("");

watch(
  active,
  (outfit) => {
    name.value = outfit?.name ?? "";
  },
  { immediate: true },
);

const contentsChanged = computed(
  () =>
    !active.value ||
    savedItemsKey(active.value) !== itemsKey(props.items) ||
    savedStoredKey(active.value) !== storedKey(props.storedItems),
);

// A patch can take a port or room away from a saved outfit. That only stands in
// the way of saving new contents: renaming it leaves them as they were.
const refused = computed(() => props.blocked && contentsChanged.value);

const changed = computed(
  () =>
    !!active.value &&
    (active.value.name !== name.value.trim() ||
      contentsChanged.value ||
      (active.value.heldWeapon ?? undefined) !== props.heldWeapon ||
      (props.characterFaceId !== undefined &&
        (active.value.characterFace?.id ?? null) !== props.characterFaceId) ||
      (props.body !== undefined && active.value.body !== props.body)),
);

const refresh = () =>
  queryClient.invalidateQueries({ queryKey: getOutfitsQueryKey() });

const createOutfit = useCreateOutfit();
const updateOutfit = useUpdateOutfit();
const destroyOutfit = useDestroyOutfit();

const saving = computed(
  () => createOutfit.isPending.value || updateOutfit.isPending.value,
);

const saveNew = async () => {
  try {
    const outfit = await createOutfit.mutateAsync({
      data: {
        name: name.value.trim(),
        items: props.items,
        storedItems: props.storedItems,
        heldWeapon: props.heldWeapon ?? null,
        body: props.body,
        ...(props.characterFaceId !== undefined
          ? { characterFaceId: props.characterFaceId }
          : {}),
      },
    });
    await refresh();
    emit("active", outfit.id);
    displaySuccess({ text: t("dressingRoom.messages.saved") });
  } catch {
    displayAlert({ text: t("dressingRoom.messages.saveFailed") });
  }
};

const saveChanges = async () => {
  if (!active.value) return;

  try {
    await updateOutfit.mutateAsync({
      id: active.value.id,
      data: {
        name: name.value.trim(),
        ...(contentsChanged.value
          ? { items: props.items, storedItems: props.storedItems }
          : {}),
        heldWeapon: props.heldWeapon ?? null,
        body: props.body,
        ...(props.characterFaceId !== undefined
          ? { characterFaceId: props.characterFaceId }
          : {}),
      },
    });
    await refresh();
    displaySuccess({ text: t("dressingRoom.messages.saved") });
  } catch {
    displayAlert({ text: t("dressingRoom.messages.saveFailed") });
  }
};

const remove = async (outfit: Outfit) => {
  try {
    await destroyOutfit.mutateAsync({ id: outfit.id });
    if (outfit.id === props.activeId) emit("active", undefined);
    await refresh();
  } catch {
    displayAlert({ text: t("dressingRoom.messages.deleteFailed") });
  }
};

const nameTaken = computed(() =>
  outfits.value?.some(
    (outfit) =>
      outfit.name === name.value.trim() && outfit.id !== props.activeId,
  ),
);

const canSave = computed(
  () =>
    !!name.value.trim() && !nameTaken.value && !saving.value && !props.pending,
);

const canSaveNew = computed(
  () =>
    canSave.value &&
    !props.blocked &&
    (!active.value || name.value.trim() !== active.value.name),
);

const canSaveChanges = computed(
  () => canSave.value && changed.value && !refused.value,
);

// Enter saves what the buttons would: the active outfit's changes, or a new
// outfit when none is active.
const submit = () => {
  if (active.value) {
    if (canSaveChanges.value) void saveChanges();
  } else if (canSaveNew.value) {
    void saveNew();
  }
};
</script>

<template>
  <section class="outfits" data-test="dressing-room-outfits">
    <h2 class="outfits__title">{{ t("dressingRoom.savedOutfits") }}</h2>
    <p v-if="!isAuthenticated" class="outfits__hint">
      {{ t("dressingRoom.signInToSave") }}
    </p>
    <template v-else>
      <form class="outfits__form" @submit.prevent="submit">
        <FormInput
          v-model="name"
          name="dressing-room-outfit-name"
          :label="t('dressingRoom.outfitName')"
        />
        <p v-if="nameTaken" class="outfits__warning">
          {{ t("dressingRoom.nameTaken") }}
        </p>
        <p
          v-if="refused"
          class="outfits__warning"
          data-test="dressing-room-save-blocked"
        >
          {{ t("dressingRoom.saveBlocked") }}
        </p>
        <div class="outfits__actions">
          <Btn
            v-if="active"
            :disabled="!canSaveChanges"
            data-test="dressing-room-save-changes"
            @click="saveChanges"
          >
            {{ t("dressingRoom.saveChanges") }}
          </Btn>
          <Btn
            :variant="active ? BtnVariantsEnum.GHOST : BtnVariantsEnum.SOLID"
            :disabled="!canSaveNew"
            data-test="dressing-room-save-new"
            @click="saveNew"
          >
            {{ t("dressingRoom.saveNew") }}
          </Btn>
        </div>
      </form>
      <Loader v-if="isLoading" :loading="true" inline />
      <p v-else-if="!outfits?.length" class="outfits__hint">
        {{ t("dressingRoom.noOutfits") }}
      </p>
      <ul v-else class="outfits__list">
        <li
          v-for="outfit in outfits"
          :key="outfit.id"
          class="outfits__entry"
          :class="{ 'outfits__entry--active': outfit.id === activeId }"
        >
          <button
            type="button"
            class="outfits__load"
            :data-test="`dressing-room-outfit-${outfit.id}`"
            @click="emit('load', outfit)"
          >
            <span class="outfits__name">{{ outfit.name }}</span>
            <span class="outfits__count">
              {{ t("dressingRoom.pieces", { count: outfit.items.length }) }}
            </span>
          </button>
          <Btn
            :size="BtnSizesEnum.SM"
            :variant="BtnVariantsEnum.BARE"
            :tone="BtnTonesEnum.DANGER"
            :confirm="t('dressingRoom.confirmDelete', { name: outfit.name })"
            :aria-label="t('actions.delete')"
            :data-test="`dressing-room-delete-${outfit.id}`"
            @click="remove(outfit)"
          >
            <i class="fa-light fa-trash" />
          </Btn>
        </li>
      </ul>
    </template>
  </section>
</template>

<style lang="scss" scoped>
.outfits {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.outfits__title {
  margin: 0;
  color: $gray-lighter;
  font-size: 0.75rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.outfits__hint {
  margin: 0;
  color: $gray-lighter;
}

.outfits__warning {
  margin: 0;
  color: $warning;
}

.outfits__form {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.outfits__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.outfits__list {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  margin: 0;
  padding: 0;
  list-style: none;
}

.outfits__entry {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  border: 1px solid transparent;
  border-radius: 4px;
}

.outfits__entry--active {
  border-color: $primary;
}

.outfits__load {
  display: flex;
  flex: 1;
  justify-content: space-between;
  gap: 0.5rem;
  min-width: 0;
  padding: 0.375rem 0.5rem;
  border: 0;
  background: none;
  color: inherit;
  text-align: left;
  cursor: pointer;

  &:hover,
  &:focus-visible {
    background: $gray-black-hover;
  }
}

.outfits__name {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.outfits__count {
  flex: none;
  color: $gray-lighter;
}
</style>
