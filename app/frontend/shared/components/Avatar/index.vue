<script lang="ts">
export default {
  name: "AvatarComponent",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";

type AvatarSizes = "default" | "small" | "large";

type Props = {
  avatar?: string;
  size?: AvatarSizes;
  editable?: boolean;
  creatable?: boolean;
  icon?: string;
  transparent?: boolean;
  round?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  avatar: undefined,
  size: "default",
  editable: false,
  creatable: false,
  icon: "fa-duotone fa-user",
  transparent: false,
  round: true,
});

const { t } = useI18n();

/*
 * A missing avatar and one whose URL no longer resolves are the same thing to
 * whoever is looking, so both fall back to the icon. Without this the browser
 * renders the img's alt text instead, and the round frame clips it - a deleted
 * upload or a CDN miss showed up as a cropped word.
 */
const loadFailed = ref(false);

watch(
  () => props.avatar,
  () => {
    loadFailed.value = false;
  },
);

const showImage = computed(() => !!props.avatar && !loadFailed.value);

const emit = defineEmits(["upload", "destroy"]);

const emitClick = () => {
  if (props.avatar) {
    emit("destroy");
  } else {
    emit("upload");
  }
};
</script>

<template>
  <div
    class="avatar"
    :class="{
      [`avatar-${size}`]: true,
      'avatar-editable': editable || creatable,
      'avatar-transparent': transparent,
      'avatar-round': round,
    }"
  >
    <img
      v-if="showImage"
      :src="avatar"
      alt="avatar"
      @error="loadFailed = true"
    />
    <div v-else class="no-avatar">
      <i :class="icon" />
    </div>
    <div v-if="editable || creatable" class="edit" @click.prevent="emitClick">
      <template v-if="avatar">
        <i class="fa fa-times" />

        {{ t("actions.remove") }}
      </template>
      <template v-else>
        <i class="fa fa-upload" />

        <template v-if="editable">
          {{ t("actions.change") }}
        </template>
        <template v-else>
          {{ t("actions.upload") }}
        </template>
      </template>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
