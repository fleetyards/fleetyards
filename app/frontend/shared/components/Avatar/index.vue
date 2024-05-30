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
  icon: "fad fa-user",
  transparent: false,
  round: true,
});

const { t } = useI18n();

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
    <img v-if="avatar" :src="avatar" alt="avatar" />
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
