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
import Pill from "@/shared/components/base/Pill/index.vue";
import SupporterBadge from "@/shared/components/SupporterBadge/index.vue";
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
      <Avatar
        :avatar="user.avatar?.mediumUrl ?? user.avatar?.smallUrl"
        size="medium"
        :online="user.online"
      />
    </template>

    <Pill
      v-if="user?.supporter"
      v-tooltip="t('labels.supporter.tooltip')"
      class="user-card__supporter"
      variant="success"
      uppercase
    >
      <SupporterBadge
        v-if="user.supporterTier || user.supporterRecurring"
        :tier="user.supporterTier"
        :recurring="user.supporterRecurring"
        :size="18"
      />
      <i v-else class="fa-duotone fa-heart" />
      {{ t("labels.supporter.badge") }}
    </Pill>
    <ContactLinks :rsi-handle="user?.rsiHandle" :discord-url="discordUrl" />
  </StatsCard>
</template>

<style lang="scss" scoped>
.user-card__supporter {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin-top: 10px;
}
</style>
