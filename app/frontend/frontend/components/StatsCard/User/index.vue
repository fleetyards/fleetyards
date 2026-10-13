<script lang="ts">
export default {
  name: "UserStatsCard",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import StatsCard from "@/frontend/components/StatsCard/index.vue";
import ContactLinks from "@/frontend/components/StatsCard/ContactLinks/index.vue";
import Avatar from "@/shared/components/Avatar/index.vue";
import SupporterBadge from "@/shared/components/SupporterBadge/index.vue";
import { SUPPORTER_TOP_TIER } from "@/shared/components/SupporterBadge/types";
import { useI18n } from "@/shared/composables/useI18n";
import { type StatsCardStatus } from "@/frontend/components/StatsCard/types";
import { type UserPublic } from "@/services/fyApi";

type Props = {
  user?: UserPublic;
  name?: string;
  to?: RouteLocationRaw | false;
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  user: undefined,
  name: undefined,
  to: undefined,
  loading: false,
});

const emit = defineEmits<{ navigate: [] }>();

const { t } = useI18n();

const subtitle = computed(() =>
  props.user?.rsiHandle
    ? t("labels.statsCard.rsiHandle", { handle: props.user.rsiHandle })
    : undefined,
);

const status = computed<StatsCardStatus | undefined>(() =>
  props.user?.rsiHandleVerified
    ? { label: t("labels.fleet.members.card.verified"), tone: "success" }
    : undefined,
);

// The link a user gave on their profile, written without a scheme as the
// roster's own link list reads it.
const discordUrl = computed(() =>
  props.user?.discord ? `//${props.user.discord}` : undefined,
);
</script>

<template>
  <StatsCard
    compact
    :title="user?.username || name || ''"
    kind="User"
    :subtitle="subtitle"
    :status="status"
    :to="to === false ? undefined : to"
    :loading="loading"
    :unavailable="!loading && !user"
    large-icon
    @navigate="emit('navigate')"
  >
    <!-- The dot only when the API answered, which it does for friends and
         fleet mates: for anyone else an absent dot is not a claim. -->
    <template v-if="user" #icon>
      <span class="user-card__avatar">
        <Avatar
          :avatar="user.avatar?.mediumUrl ?? user.avatar?.smallUrl"
          size="medium"
          :online="user.online"
        />
        <!-- Where a member's avatar carries their squadron: a user has none,
             and the corner mirrors the presence dot's. -->
        <span
          v-if="user.supporter"
          v-tooltip="
            user.maintainer
              ? t('labels.maintainer.tooltip')
              : t('labels.supporter.tooltip')
          "
          :aria-label="
            user.maintainer
              ? t('labels.maintainer.badge')
              : t('labels.supporter.badge')
          "
          role="img"
          class="user-card__supporter"
        >
          <SupporterBadge
            v-if="user.maintainer"
            :tier="SUPPORTER_TOP_TIER"
            :size="20"
          />
          <SupporterBadge
            v-else-if="user.supporterTier"
            :tier="user.supporterTier"
            :size="20"
          />
          <i v-else class="fa-duotone fa-heart" aria-hidden="true" />
        </span>
      </span>
    </template>

    <ContactLinks :rsi-handle="user?.rsiHandle" :discord-url="discordUrl" />
  </StatsCard>
</template>

<style lang="scss" scoped>
.user-card__avatar {
  position: relative;
  display: inline-flex;
}

// Placed as MemberAvatar places a squadron: centred 5px in from the corner, as
// the presence dot is in its own.
.user-card__supporter {
  position: absolute;
  left: 5px;
  bottom: 5px;
  display: inline-flex;
  transform: translate(-50%, 50%);
  color: var(--color-success, #5cb85c);
  font-size: 18px;
  line-height: 1;
}
</style>
