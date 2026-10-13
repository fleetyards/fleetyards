<script lang="ts">
export default {
  name: "HangarPublicHeading",
};
</script>

<script lang="ts" setup>
import { possessiveUsername } from "@/frontend/utils/possessiveUsername";
import Avatar from "@/shared/components/Avatar/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import SupporterBadge from "@/shared/components/SupporterBadge/index.vue";
import { SUPPORTER_TOP_TIER } from "@/shared/components/SupporterBadge/types";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useI18n } from "@/shared/composables/useI18n";
import { type UserPublic } from "@/services/fyApi";

type Props = {
  user: UserPublic;
  headlineKey?: string;
};

const { t } = useI18n();

const usernamePlural = computed(() => possessiveUsername(props.user.username));

const props = withDefaults(defineProps<Props>(), {
  headlineKey: "headlines.hangar.public",
});
</script>

<template>
  <Heading size="hero" alignment="left" hero>
    <div class="flex justify-center items-center">
      <Avatar :avatar="props.user.avatar?.smallUrl" />
      <div class="hangar-public-heading__name">
        <span>
          {{ t(props.headlineKey, { user: usernamePlural }) }}
        </span>
        <Pill
          v-if="props.user.maintainer"
          v-tooltip="t('labels.maintainer.tooltip')"
          class="hangar-public-heading__supporter"
          :variant="PillVariantsEnum.DEFAULT"
          uppercase
        >
          <SupporterBadge :tier="SUPPORTER_TOP_TIER" :size="24" />
          {{ t("labels.maintainer.badge") }}
        </Pill>
        <Pill
          v-else-if="props.user.supporter"
          v-tooltip="t('labels.supporter.tooltip')"
          class="hangar-public-heading__supporter"
          variant="success"
          uppercase
        >
          <SupporterBadge
            v-if="props.user.supporterTier"
            :tier="props.user.supporterTier"
            :size="24"
          />
          <i v-else class="fa-duotone fa-heart" />
          {{ t("labels.supporter.badge") }}
        </Pill>
      </div>
    </div>
  </Heading>
</template>

<style lang="scss" scoped>
@import "index";
</style>
