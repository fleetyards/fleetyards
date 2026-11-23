<script lang="ts">
export default {
  name: "CharacterAvatarPicker",
};
</script>

<script lang="ts" setup>
import Avatar from "@/shared/components/Avatar/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type MediaFile,
  type User,
  UserAvatarSourceEnum,
  useUpdateProfile,
} from "@/services/fyApi";

type Props = {
  user: User;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displayAlert } = useAppNotifications();
const comlink = useComlink();

const updateProfile = useUpdateProfile();

type Option = {
  source: UserAvatarSourceEnum;
  file?: MediaFile;
};

const options = computed<Option[]>(() => [
  { source: UserAvatarSourceEnum.UPLOADED, file: props.user.avatar },
  {
    source: UserAvatarSourceEnum.CHARACTER_HELMET,
    file: props.user.characterAvatarHelmet,
  },
  {
    source: UserAvatarSourceEnum.CHARACTER_BARE,
    file: props.user.characterAvatarBare,
  },
]);

const hasRenders = computed(
  () =>
    !!props.user.defaultOutfitId &&
    (!!props.user.characterAvatarHelmet?.url ||
      !!props.user.characterAvatarBare?.url),
);

const choose = async (source: UserAvatarSourceEnum) => {
  if (source === props.user.avatarSource) return;

  try {
    await updateProfile.mutateAsync({ data: { avatarSource: source } });
    comlink.emit("user-update");
  } catch {
    displayAlert({ text: t("messages.updateProfile.failure") });
  }
};
</script>

<template>
  <fieldset class="avatar-picker" data-test="character-avatar-picker">
    <legend class="avatar-picker__legend">
      {{ t("labels.user.avatarSource") }}
    </legend>
    <p v-if="!hasRenders" class="avatar-picker__hint">
      {{
        user.defaultOutfitId
          ? t("labels.user.avatarSourcePending")
          : t("labels.user.avatarSourceHint")
      }}
      <router-link :to="{ name: 'dressing-room' }">
        {{ t("nav.tools.dressingRoom") }}
      </router-link>
    </p>
    <div v-else class="avatar-picker__options">
      <button
        v-for="option in options"
        :key="option.source"
        type="button"
        class="avatar-picker__option"
        :class="{
          'avatar-picker__option--selected':
            option.source === user.avatarSource,
        }"
        :aria-pressed="option.source === user.avatarSource"
        :disabled="
          updateProfile.isPending.value ||
          (option.source !== UserAvatarSourceEnum.UPLOADED && !option.file?.url)
        "
        :data-test="`avatar-source-${option.source}`"
        @click="choose(option.source)"
      >
        <Avatar :avatar="option.file?.smallUrl" size="medium" />
        <span>{{ t(`labels.user.avatarSources.${option.source}`) }}</span>
      </button>
    </div>
  </fieldset>
</template>

<style lang="scss" scoped>
.avatar-picker {
  margin: 0 0 1rem;
  padding: 0;
  border: 0;
}

.avatar-picker__legend {
  margin-bottom: 0.5rem;
  font-size: 0.875rem;
}

.avatar-picker__hint {
  margin: 0;
  color: $gray-lighter;
}

.avatar-picker__options {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.avatar-picker__option {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.375rem;
  min-width: 6rem;
  padding: 0.5rem;
  border: 1px solid $gray-dark;
  border-radius: 4px;
  background: none;
  color: inherit;
  font-size: 0.8125rem;
  cursor: pointer;

  &:hover:not(:disabled),
  &:focus-visible {
    border-color: $gray-light;
  }

  &:disabled {
    cursor: default;
    opacity: 0.5;
  }
}

.avatar-picker__option--selected,
.avatar-picker__option--selected:hover:not(:disabled) {
  border-color: $primary;
}
</style>
