<script lang="ts">
export default {
  name: "AnnouncementRow",
};
</script>

<script lang="ts" setup>
import AnnouncementActions from "@/admin/components/Announcements/Actions/index.vue";
import AnnouncementDeliveries from "@/admin/components/Announcements/Deliveries/index.vue";
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
        <!-- A published announcement has nothing left to edit, which is what
             `publishable` says - the same call the table made. -->
        <router-link
          v-if="props.announcement.publishable"
          class="announcement-row__title"
          :to="{
            name: 'admin-announcement-edit',
            params: { id: props.announcement.id },
          }"
        >
          {{ props.announcement.title }}
        </router-link>
        <span v-else class="announcement-row__title">
          {{ props.announcement.title }}
        </span>

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

      <AnnouncementStatusPill :status="props.announcement.status" />

      <span class="announcement-row__actions">
        <AnnouncementActions :announcement="props.announcement" />
      </span>
    </div>

    <!-- On its own line rather than in a cell. As a column this was
         `mobile: false`, so the half of the row a send actually moves was
         invisible on a phone exactly while it was moving. -->
    <AnnouncementDeliveries
      v-if="props.announcement.deliveries.length"
      class="announcement-row__deliveries"
      :announcement="props.announcement"
    />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
