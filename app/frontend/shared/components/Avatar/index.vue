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

        {{ i18n?.t("actions.remove") }}
      </template>
      <template v-else>
        <i class="fa fa-upload" />

        <template v-if="editable">
          {{ i18n?.t("actions.change") }}
        </template>
        <template v-else>
          {{ i18n?.t("actions.upload") }}
        </template>
      </template>
    </div>
  </div>
</template>

<script lang="ts" setup>
import type { I18nPluginOptions } from "@/shared/plugins/I18n";

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

const i18n = inject<I18nPluginOptions>("i18n");

const emit = defineEmits(["upload", "destroy"]);

const emitClick = () => {
  if (props.avatar) {
    emit("destroy");
  } else {
    emit("upload");
  }
};
</script>

<script lang="ts">
export default {
  name: "AvatarComponent",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
