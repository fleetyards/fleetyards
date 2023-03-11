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

    <div v-if="editable || creatable" class="edit">
      <BtnDropdown
        size="small"
        variant="link"
        class="panel-edit-menu"
        data-test="avatar-edit-menu"
        :inline="true"
        icon="fad fa-gear"
      >
        <template slot="label">
          <i class="fad fa-gear" />
        </template>
        <Btn
          :aria-label="$t('actions.change')"
          size="xsmall"
          variant="dropdown"
          data-test="avatar-change"
          @click.native="changeAvatar"
        >
          <i class="fa fa-upload" />
          <span v-if="avatar">{{ $t("actions.change") }}</span>
          <span v-else>{{ $t("actions.upload") }}</span>
        </Btn>
        <Btn
          v-if="avatar"
          :aria-label="$t('actions.remove')"
          size="xsmall"
          variant="dropdown"
          data-test="avatar-edit"
          @click.native="removeAvatar"
        >
          <i class="fal fa-trash" />
          <span>{{ $t("actions.remove") }}</span>
        </Btn>
      </BtnDropdown>
    </div>
  </div>
</template>

<script lang="ts" setup>
import BtnDropdown from "@/frontend/core/components/BtnDropdown/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";

interface Props {
  avatar?: string;
  size?: "default" | "small" | "large";
  editable?: boolean;
  creatable?: boolean;
  icon?: string;
  transparent?: boolean;
  round?: boolean;
}

withDefaults(defineProps<Props>(), {
  avatar: undefined,
  size: "default",
  editable: false,
  creatable: false,
  icon: "fad fa-user",
  transparent: false,
  round: true,
});

const emit = defineEmits(["destroy", "upload"]);

const removeAvatar = () => {
  emit("destroy");
};

const changeAvatar = () => {
  emit("upload");
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
