<script lang="ts">
export default {
  name: "HangarPublicHeading",
};
</script>

<script lang="ts" setup>
import { possessiveName } from "@/frontend/utils/possessiveName";
import Avatar from "@/shared/components/Avatar/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import SupporterBadge from "@/shared/components/SupporterBadge/index.vue";
import { SUPPORTER_TOP_TIER } from "@/shared/components/SupporterBadge/types";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useI18n } from "@/shared/composables/useI18n";
import { FeatureFlagName, type UserPublic } from "@/services/fyApi";
import { characterQuery } from "@/frontend/utils/dressingRoomStorage";
import { useFeatures } from "@/frontend/composables/useFeatures";

type Props = {
  user: UserPublic;
  headlineKey?: string;
};

const { t } = useI18n();

const usernamePlural = computed(() => possessiveName(props.user));

const { isFeatureEnabled } = useFeatures();

// The figure opens in the dressing room only for a visitor who has it.
const characterLink = computed(() =>
  props.user.character && isFeatureEnabled(FeatureFlagName.DRESSING_ROOM)
    ? { name: "dressing-room", query: characterQuery(props.user.character) }
    : undefined,
);

const flagshipImage = computed(
  () =>
    props.user.flagship?.angledView?.mediumUrl ??
    props.user.flagship?.angledView?.url,
);

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
    <div
      v-if="props.user.characterPortrait?.smallUrl || flagshipImage"
      class="hangar-public-heading__showcase"
      data-test="hangar-public-showcase"
    >
      <component
        :is="characterLink ? 'router-link' : 'div'"
        v-if="props.user.characterPortrait?.smallUrl"
        :to="characterLink"
        class="hangar-public-heading__character"
        data-test="hangar-public-character"
      >
        <img
          :src="
            props.user.characterPortrait.mediumUrl ??
            props.user.characterPortrait.smallUrl
          "
          :alt="t('dressingRoom.openCharacter')"
        />
      </component>
      <router-link
        v-if="flagshipImage && props.user.flagship"
        :to="{ name: 'ship', params: { slug: props.user.flagship.modelSlug } }"
        class="hangar-public-heading__flagship"
        data-test="hangar-public-flagship"
      >
        <img :src="flagshipImage" :alt="props.user.flagship.modelName" />
        <span>{{
          props.user.flagship.name ?? props.user.flagship.modelName
        }}</span>
      </router-link>
    </div>
  </Heading>
</template>

<style lang="scss" scoped>
@import "index";
</style>
