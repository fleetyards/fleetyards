<script lang="ts">
export default {
  name: "HangarPublicHeading",
};
</script>

<script lang="ts" setup>
import Avatar from "@/shared/components/Avatar/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type UserPublic } from "@/services/fyApi";

type Props = {
  user: UserPublic;
};

const { t } = useI18n();

const userTitle = computed(() => {
  return props.user.username[0].toUpperCase() + props.user.username.slice(1);
});

const usernamePlural = computed(() => {
  if (
    userTitle.value.endsWith("s") ||
    userTitle.value.endsWith("x") ||
    userTitle.value.endsWith("z")
  ) {
    return userTitle.value;
  }

  return `${userTitle.value}'s`;
});

const props = defineProps<Props>();
</script>

<template>
  <Heading size="hero" alignment="left" hero>
    <div class="flex justify-center items-center">
      <Avatar :avatar="props.user.avatar" />
      <span>
        {{ t("headlines.hangar.public", { user: usernamePlural }) }}
      </span>
    </div>
  </Heading>
</template>

<style lang="scss" scoped>
@import "index";
</style>
