<script lang="ts">
export default {
  name: "AnnouncementRow",
};
</script>

<script lang="ts" setup>
import AnnouncementActions from "@/admin/components/Announcements/Actions/index.vue";
import AnnouncementDeliverySummary from "@/admin/components/Announcements/DeliverySummary/index.vue";
import AnnouncementStatusPill from "@/admin/components/Announcements/StatusPill/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type Announcement } from "@/services/fyAdminApi";

type Props = {
  announcement: Announcement;
};

const props = defineProps<Props>();

const { t, l } = useI18n();

// One date, whichever one the announcement has: the pill beside it already says
// whether that is a send that happened or one that is still coming.
const date = computed(() => {
  const value = props.announcement.publishedAt || props.announcement.publishAt;

  return value ? l(value, "datetime.formats.short") : undefined;
});
</script>

<template>
  <div class="announcement-row" data-test="announcement-row">
    <div class="announcement-row__head">
      <i
        class="announcement-row__icon"
        :class="props.announcement.icon"
        aria-hidden="true"
      />

      <span class="announcement-row__main">
        <router-link
          class="announcement-row__title"
          :to="{
            name: 'admin-announcement',
            params: { id: props.announcement.id },
          }"
        >
          {{ props.announcement.title }}
        </router-link>

        <span class="announcement-row__sub">
          <span v-if="date">{{ date }}</span>
          <span v-if="props.announcement.author">
            {{ props.announcement.author }}
          </span>
          <span v-if="props.announcement.recipientsCount">
            {{
              t("labels.admin.announcements.recipientsCount", {
                count: props.announcement.recipientsCount,
              })
            }}
          </span>
        </span>
      </span>

      <span class="announcement-row__badges">
        <AnnouncementDeliverySummary
          v-if="props.announcement.deliveries.length"
          :deliveries="props.announcement.deliveries"
        />
        <AnnouncementStatusPill :status="props.announcement.status" />
      </span>

      <span class="announcement-row__actions">
        <AnnouncementActions :announcement="props.announcement" />
      </span>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
