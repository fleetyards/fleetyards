<script lang="ts">
export default {
  name: "FleetDashboardAnnouncementsPanel",
};
</script>

<script lang="ts" setup>
import Avatar from "@/shared/components/Avatar/index.vue";
import Markdown from "@/shared/components/Markdown/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import {
  PanelTonesEnum,
  PanelVariantsEnum,
} from "@/shared/components/base/Panel/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { liveQuery } from "@/frontend/components/Fleets/Dashboard/liveQuery";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  useFleetAnnouncements,
  type Fleet,
  type FleetAnnouncement,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  canManage?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  canManage: false,
});

const { t, timeDistance, l } = useI18n();

const comlink = useComlink();

// Three at first: what officers want read now. The rest are a click away
// rather than gone, so every one that stands can still be read and taken down.
const SHOWN = 3;

const showAll = ref(false);

const { data } = useFleetAnnouncements(
  computed(() => props.fleet.slug),
  { query: liveQuery },
);

const all = computed(() => data.value?.items ?? []);

const announcements = computed(() =>
  showAll.value ? all.value : all.value.slice(0, SHOWN),
);

const hidden = computed(() => all.value.length - announcements.value.length);

const edit = (announcement: FleetAnnouncement) =>
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Dashboard/AnnouncementModal/index.vue"),
    props: { fleetSlug: props.fleet.slug, announcement },
  });
</script>

<template>
  <div v-if="announcements.length" data-test="fleet-dashboard-announcements">
    <Panel
      v-for="announcement in announcements"
      :key="announcement.id"
      :variant="PanelVariantsEnum.SLIM"
      :tone="PanelTonesEnum.HIGHLIGHT"
      data-test="fleet-dashboard-announcement"
    >
      <PanelBody>
        <div class="announcement">
          <i
            class="fa-light fa-bullhorn announcement__icon"
            aria-hidden="true"
          />
          <div class="announcement__content">
            <!-- Markdown renders a fragment, so it never carries this
                 component's scope id. -->
            <div class="announcement__body">
              <Markdown :source="announcement.body" />
            </div>
            <div class="announcement__meta">
              <template v-if="announcement.author">
                <Avatar
                  :avatar="announcement.author.avatar?.smallUrl"
                  size="small"
                />
                <span>{{ announcement.author.username }}</span>
                ·
              </template>
              <time :datetime="announcement.createdAt">
                {{ timeDistance(announcement.createdAt) }}
              </time>
              <template v-if="announcement.expiresAt">
                ·
                {{
                  t("fleetDashboard.announcements.until", {
                    date: l(announcement.expiresAt, "datetime.formats.short"),
                  })
                }}
              </template>
            </div>
          </div>
          <Btn
            v-if="canManage"
            :size="BtnSizesEnum.SM"
            :variant="BtnVariantsEnum.BARE"
            :aria-label="t('fleetDashboard.announcements.edit')"
            data-test="fleet-dashboard-announcement-edit"
            @click="edit(announcement)"
          >
            <i class="fa-light fa-pen" />
          </Btn>
        </div>
      </PanelBody>
    </Panel>
    <Btn
      v-if="hidden > 0"
      :size="BtnSizesEnum.SM"
      :variant="BtnVariantsEnum.BARE"
      class="announcements__more"
      data-test="fleet-dashboard-announcements-more"
      @click="showAll = true"
    >
      {{ t("fleetDashboard.announcements.more", { count: hidden }) }}
    </Btn>
  </div>
</template>

<style lang="scss" scoped>
.announcements__more {
  margin-bottom: 16px;
}

.announcement {
  display: flex;
  align-items: flex-start;
  gap: 14px;
}

.announcement__icon {
  flex: 0 0 auto;
  margin-top: 4px;
  color: var(--color-muted, #7a8288);
  font-size: 18px;
}

.announcement__content {
  flex: 1 1 auto;
  min-width: 0;
}

.announcement__body :deep(p:last-child) {
  margin-bottom: 0;
}

.announcement__meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
  margin-top: 8px;
  color: var(--color-text-dim, #959595);
  font-size: 13px;
}
</style>
