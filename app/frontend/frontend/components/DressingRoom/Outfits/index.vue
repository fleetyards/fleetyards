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
  getOutfitsQueryKey,
  useCreateOutfit,
  useDestroyOutfit,
  useOutfits,
  useUpdateOutfit,
} from "@/services/fyApi";
import {
  type OutfitSelection,
  sameOutfit,
} from "@/frontend/utils/dressingRoom";

type Props = {
  selection: OutfitSelection;
  // What the selection's slugs are, by id: what an outfit is saved with.
  items: OutfitItemInput[];
  activeId?: string;
};

const props = withDefaults(defineProps<Props>(), {
  activeId: undefined,
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

const selectionOf = (outfit: Outfit): OutfitSelection =>
  Object.fromEntries(
    outfit.items.map((item) => [item.slot, item.equipment.slug]),
  );

const name = ref("");

watch(
  active,
  (outfit) => {
    name.value = outfit?.name ?? "";
  },
  { immediate: true },
);

const changed = computed(
  () =>
    !!active.value &&
    (active.value.name !== name.value.trim() ||
      !sameOutfit(selectionOf(active.value), props.selection)),
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
      data: { name: name.value.trim(), items: props.items },
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
      data: { name: name.value.trim(), items: props.items },
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
  () => !!name.value.trim() && !nameTaken.value && !saving.value,
);
</script>

<template>
  <section class="outfits" data-test="dressing-room-outfits">
    <h2 class="outfits__title">{{ t("dressingRoom.savedOutfits") }}</h2>
    <p v-if="!isAuthenticated" class="outfits__hint">
      {{ t("dressingRoom.signInToSave") }}
    </p>
    <template v-else>
      <form
        class="outfits__form"
        @submit.prevent="active ? saveChanges() : saveNew()"
      >
        <FormInput
          v-model="name"
          name="dressing-room-outfit-name"
          :label="t('dressingRoom.outfitName')"
        />
        <p v-if="nameTaken" class="outfits__warning">
          {{ t("dressingRoom.nameTaken") }}
        </p>
        <div class="outfits__actions">
          <Btn
            v-if="active"
            :disabled="!canSave || !changed"
            data-test="dressing-room-save-changes"
            @click="saveChanges"
          >
            {{ t("dressingRoom.saveChanges") }}
          </Btn>
          <Btn
            :variant="active ? BtnVariantsEnum.GHOST : BtnVariantsEnum.SOLID"
            :disabled="!canSave || (!!active && name.trim() === active.name)"
            data-test="dressing-room-save-new"
            @click="saveNew"
          >
            {{ t("dressingRoom.saveNew") }}
          </Btn>
        </div>
      </form>
      <Loader v-if="isLoading" :loading="true" />
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
  font-size: 1.1rem;
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
