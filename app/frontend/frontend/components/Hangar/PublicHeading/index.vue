<script lang="ts">
export default {
  name: "HangarPublicHeading",
};
</script>

<script lang="ts" setup>
import Avatar from "@/shared/components/Avatar/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import SupporterBadge from "@/shared/components/SupporterBadge/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type UserPublic } from "@/services/fyApi";

type Props = {
  user: UserPublic;
  headlineKey?: string;
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

const props = withDefaults(defineProps<Props>(), {
  headlineKey: "headlines.hangar.public",
});
</script>

<template>
  <Heading size="hero" alignment="left" hero>
    <div class="flex justify-center items-center">
      <Avatar :avatar="props.user.avatar?.smallUrl" />
      <div class="hangar-public-heading__name">
        <div class="hangar-public-heading__title">
          <span>
            {{ t(props.headlineKey, { user: usernamePlural }) }}
          </span>
          <Pill
            v-if="props.user.supporter"
            v-tooltip="t('labels.supporter.tooltip')"
            class="hangar-public-heading__supporter"
            variant="success"
            uppercase
          >
            <i class="fa-duotone fa-heart" />
            {{ t("labels.supporter.badge") }}
          </Pill>
        </div>
        <SupporterBadge
          v-if="
            props.user.supporter &&
            (props.user.supporterTier || props.user.supporterRecurring)
          "
          :tier="props.user.supporterTier"
          :recurring="props.user.supporterRecurring"
          :size="20"
          class="hangar-public-heading__tier"
        />
      </div>
    </div>
  </Heading>
</template>

<style lang="scss" scoped>
@import "index";
</style>
