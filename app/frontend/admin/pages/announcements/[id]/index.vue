<script lang="ts">
export default {
  name: "AdminAnnouncementPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Markdown from "@/shared/components/Markdown/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import AnnouncementActions from "@/admin/components/Announcements/Actions/index.vue";
import AnnouncementDeliveries from "@/admin/components/Announcements/Deliveries/index.vue";
import AnnouncementStatusPill from "@/admin/components/Announcements/StatusPill/index.vue";
import {
  type Announcement,
  useRefreshAnnouncementEngagement,
} from "@/services/fyAdminApi";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  announcement: Announcement;
};

const props = defineProps<Props>();

const { t, l } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();

const date = computed(() => {
  const value = props.announcement.publishedAt || props.announcement.publishAt;

  return value ? l(value, "datetime.formats.short") : undefined;
});

const refreshable = computed(() =>
  props.announcement.deliveries.some(
    (delivery) => delivery.engagementTrackable,
  ),
);

// The counts come back over the announcements channel as each job lands, so
// there is nothing to invalidate here.
const refreshMutation = useRefreshAnnouncementEngagement();

const refresh = async () => {
  await refreshMutation
    .mutateAsync({ id: props.announcement.id })
    .then(() => {
      displaySuccess({ text: t("messages.announcement.refreshQueued") });
    })
    .catch(() => {
      displayAlert({ text: t("messages.announcement.refreshFailed") });
    });
};
</script>

<template>
  <BreadCrumbs
    :crumbs="[
      {
        to: { name: 'admin-announcements' },
        label: t('headlines.admin.announcements.index'),
      },
    ]"
  />

  <div class="announcement-page__head">
    <div class="announcement-page__title">
      <Heading hero>{{ props.announcement.title }}</Heading>
      <div class="announcement-page__meta">
        <AnnouncementStatusPill :status="props.announcement.status" />
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
      </div>
    </div>
    <AnnouncementActions :announcement="props.announcement" />
  </div>

  <div class="row">
    <div
      class="col-12"
      :class="{ 'col-md-6': props.announcement.deliveries.length }"
    >
      <Panel>
        <PanelHeading :size="HeadingSizeEnum.LG">
          {{ t("labels.admin.announcements.content") }}
        </PanelHeading>
        <PanelBody>
          <Markdown :source="props.announcement.body" />
          <!-- A path on the public site, so no href: resolved here it would
               point into the admin app. -->
          <code v-if="props.announcement.link" class="announcement-page__link">
            {{ props.announcement.link }}
          </code>
        </PanelBody>
      </Panel>
    </div>
    <div v-if="props.announcement.deliveries.length" class="col-12 col-md-6">
      <Panel data-test="announcement-deliveries-panel">
        <PanelHeading :size="HeadingSizeEnum.LG">
          {{ t("headlines.admin.announcements.deliveries") }}
          <template v-if="refreshable" #actions>
            <Btn
              :size="BtnSizesEnum.SM"
              :loading="refreshMutation.isPending.value"
              data-test="announcement-refresh-engagement"
              @click="refresh"
            >
              <i class="fa-duotone fa-arrows-rotate" />
              {{ t("actions.announcements.refreshEngagement") }}
            </Btn>
          </template>
        </PanelHeading>
        <PanelBody>
          <AnnouncementDeliveries :announcement="props.announcement" />
        </PanelBody>
      </Panel>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.announcement-page__head {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 16px;
}

.announcement-page__title {
  min-width: 0;
}

.announcement-page__meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 4px 12px;
  color: var(--color-text-dim, #959595);
  font-size: 0.875rem;
}

.announcement-page__link {
  display: inline-block;
  margin-top: 8px;
  word-break: break-all;
}
</style>
