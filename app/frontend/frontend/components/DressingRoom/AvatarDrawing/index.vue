<script lang="ts">
export default {
  name: "DressingRoomAvatarDrawing",
};
</script>

<script lang="ts" setup>
import AvatarRenderer from "@/frontend/components/DressingRoom/AvatarRenderer/index.vue";
import { useCharacterAvatarUpload } from "@/frontend/composables/useCharacterAvatarUpload";
import { useCharacterAvatarsStore } from "@/frontend/stores/characterAvatars";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();
const { displayAlert, displaySuccess } = useAppNotifications();

const store = useCharacterAvatarsStore();
const { upload } = useCharacterAvatarUpload();

// Signed out mid-drawing: the next session starts with nothing in flight.
onBeforeUnmount(() => store.finish());

const drawn = async (portraits: (Blob | null)[]) => {
  try {
    if (await upload(portraits)) {
      displaySuccess({ text: t("dressingRoom.messages.avatarsUpdated") });
    } else {
      displayAlert({ text: t("dressingRoom.messages.avatarsFailed") });
    }
  } catch {
    displayAlert({ text: t("dressingRoom.messages.avatarsFailed") });
  } finally {
    store.finish();
  }
};
</script>

<template>
  <AvatarRenderer
    v-if="store.models"
    :key="store.run"
    :models="store.models"
    @done="drawn"
  />
</template>
