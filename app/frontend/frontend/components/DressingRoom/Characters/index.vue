<script lang="ts">
export default {
  name: "DressingRoomCharacters",
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
import Loader from "@/shared/components/Loader/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useSessionStore } from "@/frontend/stores/session";
import {
  type CharacterFace,
  type OutfitBodyEnum,
  type SharedCharacterFace,
  type ValidationError,
  getCharacterFacesQueryKey,
  getOutfitsQueryKey,
  useCharacterFaces,
  useCreateCharacterFace,
  useDestroyCharacterFace,
} from "@/services/fyApi";

type Props = {
  body: OutfitBodyEnum;
  // The character on the figure, by its token: the viewer's own or one a
  // share link brought.
  token?: string;
  shown?: SharedCharacterFace;
  // The shown character could not be found, or not drawn on this body.
  unavailable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  token: undefined,
  shown: undefined,
  unavailable: false,
});

const emit = defineEmits<{
  select: [token: string | undefined];
}>();

const { t } = useI18n();
const { displayAlert, displaySuccess } = useAppNotifications();
const { isAuthenticated } = storeToRefs(useSessionStore());
const queryClient = useQueryClient();

const { data: characters, isLoading } = useCharacterFaces({
  query: { enabled: isAuthenticated, retry: false },
});

const own = computed(() =>
  characters.value?.some((character) => character.token === props.token),
);

const createCharacter = useCreateCharacterFace();
const destroyCharacter = useDestroyCharacterFace();

const fileInput = ref<HTMLInputElement>();

const refresh = () =>
  queryClient.invalidateQueries({ queryKey: getCharacterFacesQueryKey() });

// The server says what is wrong with a file: not a character file, too large,
// or one for the other body.
const uploadError = (error: unknown) => {
  const response = (error as { response?: { data?: ValidationError } }).response
    ?.data;
  const message = response?.errors
    ?.flatMap((entry) => entry.messages)
    .map((entry) => entry.message)
    .join(" ");

  return message || t("dressingRoom.characters.messages.uploadFailed");
};

const upload = async (event: Event) => {
  const input = event.target as HTMLInputElement;
  const file = input.files?.[0];
  input.value = "";
  if (!file) return;

  try {
    const character = await createCharacter.mutateAsync({
      data: { file, body: props.body },
    });
    await refresh();
    emit("select", character.token);
    displaySuccess({ text: t("dressingRoom.characters.messages.uploaded") });
  } catch (error) {
    displayAlert({ text: uploadError(error) });
  }
};

const remove = async (character: CharacterFace) => {
  try {
    await destroyCharacter.mutateAsync({ id: character.id });
    if (character.token === props.token) emit("select", undefined);
    // Outfits that wore it are saved without it now.
    await Promise.all([
      refresh(),
      queryClient.invalidateQueries({ queryKey: getOutfitsQueryKey() }),
    ]);
  } catch {
    displayAlert({ text: t("dressingRoom.characters.messages.deleteFailed") });
  }
};
</script>

<template>
  <section class="characters" data-test="dressing-room-characters">
    <h2 class="characters__title">
      {{ t("dressingRoom.characters.title") }}
    </h2>
    <p v-if="unavailable" class="characters__warning">
      {{ t("dressingRoom.characters.unavailable") }}
    </p>
    <div
      v-if="shown && !own"
      class="characters__entry characters__entry--active"
      data-test="dressing-room-shared-character"
    >
      <span class="characters__name">{{ shown.name }}</span>
      <a
        :href="shown.file.url"
        :download="`${shown.name}.chf`"
        class="characters__download"
        :aria-label="t('dressingRoom.characters.download')"
        v-tooltip="t('dressingRoom.characters.download')"
      >
        <i class="fa-light fa-download" />
      </a>
      <Btn
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.BARE"
        :aria-label="t('dressingRoom.characters.takeOff')"
        @click="emit('select', undefined)"
      >
        <i class="fa-light fa-xmark" />
      </Btn>
    </div>
    <p v-if="!isAuthenticated" class="characters__hint">
      {{ t("dressingRoom.characters.signIn") }}
    </p>
    <template v-else>
      <p class="characters__hint">{{ t("dressingRoom.characters.hint") }}</p>
      <div class="characters__actions">
        <Btn
          :size="BtnSizesEnum.SM"
          :loading="createCharacter.isPending.value"
          data-test="dressing-room-upload-character"
          @click="fileInput?.click()"
        >
          <i class="fa-light fa-upload" />
          {{ t("dressingRoom.characters.upload") }}
        </Btn>
        <Btn
          v-if="token"
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.GHOST"
          data-test="dressing-room-take-off-character"
          @click="emit('select', undefined)"
        >
          {{ t("dressingRoom.characters.takeOff") }}
        </Btn>
        <input
          ref="fileInput"
          type="file"
          accept=".chf"
          class="characters__file"
          data-test="dressing-room-character-file"
          @change="upload"
        />
      </div>
      <Loader v-if="isLoading" :loading="true" inline />
      <ul v-else-if="characters?.length" class="characters__list">
        <li
          v-for="character in characters"
          :key="character.id"
          class="characters__entry"
          :class="{ 'characters__entry--active': character.token === token }"
        >
          <button
            type="button"
            class="characters__select"
            :disabled="character.body !== body"
            :data-test="`dressing-room-character-${character.id}`"
            @click="emit('select', character.token)"
          >
            <span class="characters__name">{{ character.name }}</span>
            <span v-if="character.body !== body" class="characters__note">
              {{ t(`dressingRoom.bodies.${character.body}`) }}
            </span>
          </button>
          <a
            :href="character.file.url"
            :download="`${character.name}.chf`"
            class="characters__download"
            :aria-label="t('dressingRoom.characters.download')"
            v-tooltip="t('dressingRoom.characters.download')"
          >
            <i class="fa-light fa-download" />
          </a>
          <Btn
            :size="BtnSizesEnum.SM"
            :variant="BtnVariantsEnum.BARE"
            :tone="BtnTonesEnum.DANGER"
            :confirm="
              t('dressingRoom.characters.confirmDelete', {
                name: character.name,
              })
            "
            :aria-label="t('actions.delete')"
            :data-test="`dressing-room-delete-character-${character.id}`"
            @click="remove(character)"
          >
            <i class="fa-light fa-trash" />
          </Btn>
        </li>
      </ul>
    </template>
  </section>
</template>

<style lang="scss" scoped>
.characters {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.characters__title {
  margin: 0;
  font-size: 1.1rem;
}

.characters__hint {
  margin: 0;
  color: $gray-lighter;
}

.characters__warning {
  margin: 0;
  color: $warning;
}

.characters__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.characters__file {
  display: none;
}

.characters__list {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  margin: 0;
  padding: 0;
  list-style: none;
}

.characters__entry {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  min-height: 2rem;
  padding-left: 0.5rem;
  border: 1px solid transparent;
  border-radius: 4px;

  &:has(.characters__select) {
    padding-left: 0;
  }
}

.characters__entry--active {
  border-color: $primary;
}

.characters__select {
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

  &:hover:not(:disabled),
  &:focus-visible {
    background: $gray-black-hover;
  }

  &:disabled {
    cursor: not-allowed;
    opacity: 0.6;
  }
}

.characters__name {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.characters__note {
  flex: none;
  color: $gray-lighter;
}

.characters__download {
  flex: none;
  padding: 0 0.25rem;
  color: $gray-lighter;

  &:hover,
  &:focus-visible {
    color: inherit;
  }
}
</style>
