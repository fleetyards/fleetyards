<script lang="ts">
export default {
  name: "FleetDashboardActivityList",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import Avatar from "@/shared/components/Avatar/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  FleetActivityKindEnum,
  FleetActivitySubjectTypeEnum,
  type Fleet,
  type FleetActivity,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  entries: FleetActivity[];
  // Who did it, beside the entry. A list of new members is a list of people,
  // so there the face is the entry and the kind goes without saying.
  showActor?: boolean;
  showKind?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  showActor: true,
  showKind: true,
});

const { t, timeDistance } = useI18n();

const ICONS: Record<FleetActivityKindEnum, string> = {
  [FleetActivityKindEnum.MEMBER_JOINED]: "fa-user-plus",
  [FleetActivityKindEnum.EVENT_PUBLISHED]: "fa-calendar-star",
  [FleetActivityKindEnum.EVENT_CANCELLED]: "fa-calendar-xmark",
  [FleetActivityKindEnum.CONTRACT_PUBLISHED]: "fa-file-contract",
  [FleetActivityKindEnum.CONTRACT_CLAIMED]: "fa-handshake",
  [FleetActivityKindEnum.CONTRACT_FULFILLED]: "fa-badge-check",
  [FleetActivityKindEnum.INVENTORY_TRANSFER_COMPLETED]: "fa-truck-ramp-box",
  [FleetActivityKindEnum.INVENTORY_ITEM_DEPOSITED]: "fa-arrow-down-to-bracket",
  [FleetActivityKindEnum.INVENTORY_ITEM_WITHDRAWN]: "fa-arrow-up-from-bracket",
};

// A transfer has no name of its own unless somebody wrote a note, so the store
// it went through stands in for one.
const titleFor = (entry: FleetActivity) =>
  entry.subject.title || entry.inventory?.name || t("fleetDashboard.unnamed");

const linkFor = (entry: FleetActivity): RouteLocationRaw | undefined => {
  const slug = props.fleet.slug;

  switch (entry.subject.type) {
    case FleetActivitySubjectTypeEnum.EVENT:
      return entry.subject.slug
        ? { name: "fleet-event", params: { slug, event: entry.subject.slug } }
        : undefined;
    case FleetActivitySubjectTypeEnum.CONTRACT:
      return entry.subject.slug
        ? {
            name: "fleet-contract",
            params: { slug, contract: entry.subject.slug },
          }
        : undefined;
    case FleetActivitySubjectTypeEnum.MEMBER:
      return { name: "fleet-members-index", params: { slug } };
    default:
      return entry.inventory
        ? {
            name: "fleet-logistics-inventory",
            params: { slug, inventory: entry.inventory.slug },
          }
        : undefined;
  }
};

const metaFor = (entry: FleetActivity) =>
  [
    props.showKind ? t(`fleetDashboard.activity.kinds.${entry.kind}`) : null,
    entry.inventory && entry.subject.title ? entry.inventory.name : null,
    // Somebody joining is their own subject; naming them twice says nothing.
    props.showActor &&
    entry.actor &&
    entry.subject.type !== FleetActivitySubjectTypeEnum.MEMBER
      ? entry.actor.username
      : null,
    timeDistance(entry.occurredAt),
  ].filter(Boolean);
</script>

<template>
  <ul class="activity-list">
    <li
      v-for="entry in entries"
      :key="entry.id"
      class="activity-list__entry"
      :class="{ 'activity-list__entry--mine': entry.involvesViewer }"
      :data-test="`fleet-activity-${entry.kind}`"
    >
      <Avatar
        v-if="!showKind && entry.actor"
        :avatar="entry.actor.avatar?.smallUrl"
        size="small"
      />
      <i
        v-else
        class="fa-light activity-list__icon"
        :class="ICONS[entry.kind]"
        aria-hidden="true"
      />
      <div class="activity-list__text">
        <component
          :is="linkFor(entry) ? 'router-link' : 'span'"
          :to="linkFor(entry)"
          class="activity-list__title"
        >
          {{ titleFor(entry) }}
        </component>
        <span class="activity-list__meta">
          <span
            v-if="entry.involvesViewer"
            class="activity-list__mine"
            data-test="fleet-activity-mine"
          >
            {{ t("fleetDashboard.activity.you") }}
          </span>
          {{ metaFor(entry).join(" · ") }}
        </span>
      </div>
    </li>
  </ul>
</template>

<style lang="scss" scoped>
.activity-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.activity-list__entry {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  min-width: 0;
}

.activity-list__icon {
  flex: 0 0 20px;
  margin-top: 3px;
  color: var(--color-muted, #7a8288);
  text-align: center;
}

.activity-list__text {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.activity-list__title {
  overflow: hidden;
  color: var(--color-lifted, #eee);
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.activity-list__meta {
  color: var(--color-text-dim, #959595);
  font-size: 13px;
}

.activity-list__mine {
  margin-right: 4px;
  padding: 0 6px;
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: 999px;
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}
</style>
