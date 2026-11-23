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
import RsiProfileLink from "@/shared/components/RsiProfileLink/index.vue";
import { handleVerifiedViaProfile } from "@/frontend/utils/rsiHandle";

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

const flagshipImage = computed(() => {
  const flagship = props.user.flagship;

  return (
    flagship?.angledViewColored?.largeUrl ||
    flagship?.angledView?.largeUrl ||
    flagship?.angledView?.url
  );
});

const flagshipName = computed(
  () => props.user.flagship?.name || props.user.flagship?.modelName,
);

const flagshipSub = computed(() =>
  props.user.flagship?.name
    ? props.user.flagship.modelName
    : props.user.flagship?.manufacturerName,
);

const props = withDefaults(defineProps<Props>(), {
  headlineKey: "headlines.hangar.public",
});
</script>

<template>
  <div class="hangar-public-heading">
    <div class="hangar-public-heading__identity">
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

      <div class="hangar-public-heading__links" data-test="hangar-public-links">
        <component
          :is="characterLink ? 'router-link' : 'span'"
          v-if="props.user.characterPortrait?.smallUrl"
          v-tooltip="
            characterLink ? t('dressingRoom.openCharacter') : undefined
          "
          :to="characterLink"
          :aria-label="t('dressingRoom.openCharacter')"
          class="hangar-public-heading__character"
          data-test="hangar-public-character"
        >
          <img :src="props.user.characterPortrait.smallUrl" alt="" />
        </component>
        <a
          v-if="props.user.homepage"
          v-tooltip="t('labels.homepage')"
          :aria-label="t('labels.homepage')"
          :href="`//${props.user.homepage}`"
          target="_blank"
          rel="noopener"
        >
          <i class="fa-light fa-globe globe-rotate" />
        </a>
        <RsiProfileLink
          v-if="props.user.rsiHandle"
          :handle="props.user.rsiHandle"
          :citizenid-profile-url="props.user.citizenidProfileUrl"
          :verified="handleVerifiedViaProfile(props.user)"
          icon-only
        />
        <a
          v-if="props.user.discord"
          v-tooltip="t('labels.discord')"
          :aria-label="t('labels.discord')"
          :href="`//${props.user.discord}`"
          target="_blank"
          rel="noopener"
        >
          <i class="fa-brands fa-discord" />
        </a>
        <a
          v-if="props.user.youtube"
          v-tooltip="t('labels.youtube')"
          :aria-label="t('labels.youtube')"
          :href="`//${props.user.youtube}`"
          target="_blank"
          rel="noopener"
        >
          <i class="fa-brands fa-youtube" />
        </a>
        <a
          v-if="props.user.twitch"
          v-tooltip="t('labels.twitch')"
          :aria-label="t('labels.twitch')"
          :href="`//${props.user.twitch}`"
          target="_blank"
          rel="noopener"
        >
          <i class="fa-brands fa-twitch" />
        </a>
      </div>
    </div>

    <router-link
      v-if="flagshipImage && props.user.flagship"
      :to="{ name: 'ship', params: { slug: props.user.flagship.modelSlug } }"
      class="hangar-public-heading__flagship"
      data-test="hangar-public-flagship"
    >
      <span class="hangar-public-heading__flagship-label">
        <span class="hangar-public-heading__eyebrow">
          {{ t("labels.flagship") }}
        </span>
        <span
          class="hangar-public-heading__flagship-name"
          data-test="hangar-public-flagship-name"
        >
          {{ flagshipName }}
        </span>
        <span v-if="flagshipSub" class="hangar-public-heading__flagship-sub">
          {{ flagshipSub }}
        </span>
      </span>
      <img
        :src="flagshipImage"
        alt=""
        class="hangar-public-heading__ship"
        aria-hidden="true"
      />
    </router-link>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
