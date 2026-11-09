<script lang="ts">
export default {
  name: "DressingRoomCharacters",
};
</script>

<script lang="ts" setup>
import { storeToRefs } from "pinia";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useSessionStore } from "@/frontend/stores/session";
import {
  type OutfitBodyEnum,
  type SharedCharacterFace,
} from "@/services/fyApi";

type Props = {
  body: OutfitBodyEnum;
  // The character on the figure, by its token: the viewer's own or one a
  // share link brought. Without one the game's default character is worn.
  token?: string;
  shown?: SharedCharacterFace;
  // The shown character could not be found, or not drawn on this body.
  unavailable?: boolean;
  // The shown character is kept, but cannot be drawn until the customizer
  // data it needs is imported.
  notReady?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  token: undefined,
  shown: undefined,
  unavailable: false,
  notReady: false,
});

const emit = defineEmits<{
  select: [token: string | undefined];
}>();

const { t } = useI18n();
const { isAuthenticated } = storeToRefs(useSessionStore());
const comlink = useComlink();

const open = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/DressingRoom/CharactersModal/index.vue"),
    props: {
      body: props.body,
      token: () => props.token,
      onSelect: (token: string | undefined) => emit("select", token),
    },
  });
};
</script>

<template>
  <section class="character" data-test="dressing-room-characters">
    <h2 class="character__title">{{ t("dressingRoom.characters.title") }}</h2>
    <p v-if="unavailable" class="character__warning">
      {{ t("dressingRoom.characters.unavailable") }}
    </p>
    <p
      v-else-if="notReady"
      class="character__warning"
      data-test="dressing-room-character-not-ready"
    >
      {{ t("dressingRoom.characters.notReady") }}
    </p>
    <div class="character__current" data-test="dressing-room-current-character">
      <span class="character__name">
        {{ shown?.name ?? t("dressingRoom.characters.default") }}
      </span>
      <a
        v-if="shown"
        :href="shown.file.url"
        :download="`${shown.name}.chf`"
        class="character__download"
        :aria-label="t('dressingRoom.characters.download')"
        v-tooltip="t('dressingRoom.characters.download')"
      >
        <i class="fa-light fa-download" />
      </a>
    </div>
    <div class="character__actions">
      <Btn
        v-if="isAuthenticated"
        :size="BtnSizesEnum.SM"
        data-test="dressing-room-choose-character"
        @click="open"
      >
        <i class="fa-light fa-user-pen" />
        {{ t("dressingRoom.characters.change") }}
      </Btn>
      <Btn
        v-if="token"
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.GHOST"
        data-test="dressing-room-take-off-character"
        @click="emit('select', undefined)"
      >
        <i class="fa-light fa-undo" />
        {{ t("actions.reset") }}
      </Btn>
    </div>
    <p v-if="!isAuthenticated" class="character__hint">
      {{ t("dressingRoom.characters.signIn") }}
    </p>
  </section>
</template>

<style lang="scss" scoped>
.character {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.character__title {
  margin: 0;
  font-size: 1.1rem;
}

.character__hint {
  margin: 0;
  color: $gray-lighter;
}

.character__warning {
  margin: 0;
  color: $warning;
}

.character__current {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  min-height: 2rem;
  padding: 0 0.5rem;
  border: 1px solid $primary;
  border-radius: 4px;
}

.character__name {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.character__download {
  flex: none;
  color: $gray-lighter;

  &:hover,
  &:focus-visible {
    color: inherit;
  }
}

.character__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}
</style>
