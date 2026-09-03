<script lang="ts">
export default {
  name: "DashboardEditFeed",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useRecentVersions as useRecentVersionsQuery } from "@/services/fyAdminApi";

const { t, lUtc: l, timeDistance } = useI18n();

const { data: versions } = useRecentVersionsQuery();

const items = computed(() => versions.value?.items || []);

/*
 * The item types the feed can carry each have an edit page, but the version row
 * only knows an id and a type - so the link is built here rather than shipped in
 * the payload.
 */
const ROUTE_BY_ITEM_TYPE: Record<string, string> = {
  Model: "admin-model-edit",
  ModelModule: "admin-model-module-edit",
  Fleet: "admin-fleet-edit",
};

const routeFor = (itemType: string, itemId: string) => {
  const name = ROUTE_BY_ITEM_TYPE[itemType];

  return name ? { name, params: { id: itemId } } : undefined;
};

// A revert writes a version of its own, so a field can appear more than once in
// one feed. The list stays chronological; this only shortens a long changeset.
const VISIBLE_FIELDS = 3;

const whenTooltip = (createdAt?: string | null) =>
  createdAt ? l(createdAt, "datetime.formats.short") : false;
</script>

<template>
  <Panel>
    <PanelHeading>
      {{ t("headlines.admin.dashboard.recentEdits") }}
    </PanelHeading>
    <PanelBody>
      <Empty
        v-if="!items.length"
        inline
        hide-actions
        :title="t('empty.admin.recentEdits')"
      />
      <ul v-else class="edit-feed" data-test="edit-feed">
        <li v-for="version in items" :key="version.id" class="edit-feed__row">
          <div class="edit-feed__head">
            <component
              :is="
                routeFor(version.itemType, version.itemId)
                  ? 'router-link'
                  : 'span'
              "
              :to="routeFor(version.itemType, version.itemId)"
              class="edit-feed__item"
            >
              {{ version.itemName || version.itemType }}
            </component>
            <span class="edit-feed__type">{{ version.itemType }}</span>
            <span class="edit-feed__author">
              {{
                version.author?.username ||
                t("labels.admin.dashboard.systemAuthor")
              }}
            </span>
            <span
              v-tooltip="whenTooltip(version.createdAt)"
              class="edit-feed__when"
            >
              {{ version.createdAt ? timeDistance(version.createdAt) : "" }}
            </span>
          </div>
          <div class="edit-feed__fields">
            <span
              v-for="change in version.changes.slice(0, VISIBLE_FIELDS)"
              :key="change.field"
              class="edit-feed__field"
            >
              <span class="edit-feed__field-name">{{ change.field }}</span>
              <span class="edit-feed__field-from">{{
                change.from || "—"
              }}</span>
              <i class="fa-duotone fa-arrow-right edit-feed__arrow" />
              <span class="edit-feed__field-to">{{ change.to || "—" }}</span>
            </span>
            <span
              v-if="version.changes.length > VISIBLE_FIELDS"
              class="edit-feed__more"
            >
              {{
                t("labels.admin.dashboard.moreFields", {
                  count: version.changes.length - VISIBLE_FIELDS,
                })
              }}
            </span>
          </div>
        </li>
      </ul>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.edit-feed {
  list-style: none;
  margin: 0;
  padding: 0;
}

.edit-feed__row {
  padding: 10px 0;
  border-bottom: 1px solid rgba($gray-light, 0.16);

  &:last-child {
    border-bottom: 0;
  }
}

.edit-feed__head {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  gap: 4px 10px;
}

.edit-feed__item {
  font-weight: 600;
}

.edit-feed__type {
  color: $gray;
  font-size: 11px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.edit-feed__author {
  color: $gray-lighter;
  font-size: 13px;
}

.edit-feed__when {
  color: $gray;
  font-size: 12px;
  margin-left: auto;
  white-space: nowrap;
}

.edit-feed__fields {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 16px;
  margin-top: 4px;
  font-size: 12.5px;
  color: $gray-lighter;
}

.edit-feed__field {
  display: inline-flex;
  align-items: baseline;
  gap: 5px;
  min-width: 0;
}

.edit-feed__field-name {
  color: $gray;
}

// The values are user data of unknown length - a description can run to a
// paragraph - so each side is capped rather than allowed to push the row wide.
.edit-feed__field-from,
.edit-feed__field-to {
  max-width: 18ch;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.edit-feed__field-from {
  text-decoration: line-through;
  color: $gray;
}

.edit-feed__arrow {
  font-size: 9px;
  color: $gray;
}

.edit-feed__more {
  color: $gray;
}
</style>
