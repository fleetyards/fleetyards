<script lang="ts">
export default {
  name: "AnnouncementEngagement",
};
</script>

<script lang="ts" setup>
import {
  type AnnouncementDelivery,
  AnnouncementChannelEnum,
  AnnouncementDeliveryStatusEnum,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  delivery: AnnouncementDelivery;
};

const props = defineProps<Props>();

const { t, l } = useI18n();

const counts = computed(() => {
  const engagement = props.delivery.engagement;
  if (!engagement) return [];

  return (
    [
      { key: "likes", icon: "fa-heart", value: engagement.likes },
      { key: "reposts", icon: "fa-retweet", value: engagement.reposts },
      { key: "replies", icon: "fa-reply", value: engagement.replies },
      { key: "quotes", icon: "fa-quote-right", value: engagement.quotes },
    ] as const
  ).filter((count) => count.value !== undefined);
});

const reactions = computed(() => props.delivery.engagement?.reactions);

const sent = computed(
  () => props.delivery.status === AnnouncementDeliveryStatusEnum.SUCCEEDED,
);

// Why a sent post shows no numbers, when it shows none.
const note = computed(() => {
  if (!sent.value || props.delivery.engagement) return undefined;

  if (props.delivery.channel === AnnouncementChannelEnum.X) {
    return t("labels.admin.announcements.engagement.xUnavailable");
  }

  if (!props.delivery.engagementTrackable) {
    return t("labels.admin.announcements.engagement.untracked");
  }

  return t("labels.admin.announcements.engagement.notFetched");
});
</script>

<template>
  <div
    v-if="sent && props.delivery.channel !== AnnouncementChannelEnum.IN_APP"
    class="announcement-engagement"
    data-test="announcement-engagement"
  >
    <ul v-if="counts.length" class="announcement-engagement__counts">
      <li
        v-for="count in counts"
        :key="count.key"
        class="announcement-engagement__count"
        :data-test="`announcement-engagement-${count.key}`"
      >
        <i class="fa-duotone" :class="count.icon" aria-hidden="true" />
        <strong>{{ count.value }}</strong>
        {{ t(`labels.admin.announcements.engagement.${count.key}`) }}
      </li>
    </ul>

    <template v-else-if="reactions">
      <ul v-if="reactions.length" class="announcement-engagement__counts">
        <li
          v-for="reaction in reactions"
          :key="reaction.id || reaction.emoji"
          class="announcement-engagement__count"
          data-test="announcement-engagement-reaction"
        >
          <span>{{
            reaction.id ? `:${reaction.emoji}:` : reaction.emoji
          }}</span>
          <strong>{{ reaction.count }}</strong>
        </li>
      </ul>
      <span v-else class="announcement-engagement__note">
        {{ t("labels.admin.announcements.engagement.noReactions") }}
      </span>
    </template>

    <span v-if="note" class="announcement-engagement__note">{{ note }}</span>

    <span
      v-if="props.delivery.engagementFetchedAt"
      class="announcement-engagement__note"
    >
      {{
        t("labels.admin.announcements.engagement.fetchedAt", {
          time: l(props.delivery.engagementFetchedAt, "datetime.formats.short"),
        })
      }}
    </span>
  </div>
</template>

<style lang="scss" scoped>
.announcement-engagement {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 4px 16px;
}

.announcement-engagement__counts {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 16px;
  list-style: none;
  margin: 0;
  padding: 0;
}

.announcement-engagement__count {
  display: inline-flex;
  align-items: baseline;
  gap: 6px;

  i {
    color: var(--color-muted, #7a8288);
  }
}

.announcement-engagement__note {
  color: var(--color-text-dim, #959595);
  font-size: 0.875rem;
}
</style>
