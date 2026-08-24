<script lang="ts">
export default {
  name: "AdminNotificationsListItem",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import BasePill from "@/shared/components/base/Pill/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  hasSeverityLabel,
  severityPillVariant,
} from "@/admin/components/Notifications/severity";
import { type AdminNotification } from "@/services/fyAdminApi";

type Props = {
  notification: AdminNotification;
  selected?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  selected: false,
});

const emit = defineEmits<{
  select: [];
  archive: [];
  unarchive: [];
  destroy: [];
  previous: [];
  next: [];
}>();

const { t, l } = useI18n();

const select = ref<HTMLButtonElement>();

// The page moves the selection with the arrow keys, and focus has to follow it
// so the next keypress lands on the row the reader is looking at.
defineExpose({ focus: () => select.value?.focus() });
</script>

<template>
  <div
    class="notification-item"
    data-test="notification-item"
    :class="{
      'notification-item--unread': !notification.read,
      'notification-item--selected': props.selected,
    }"
  >
    <button
      ref="select"
      type="button"
      class="notification-item__select"
      data-test="notification-select"
      :aria-current="props.selected ? 'true' : undefined"
      @click="emit('select')"
      @keydown.down.prevent="emit('next')"
      @keydown.up.prevent="emit('previous')"
    >
      <i
        class="notification-item__icon"
        :class="notification.icon || 'fa-duotone fa-bell'"
      />
      <span class="notification-item__content">
        <span class="notification-item__title">
          {{ notification.title }}
          <span
            v-if="notification.occurrences > 1"
            class="notification-item__count"
          >
            &times;{{ notification.occurrences }}
          </span>
        </span>
        <span class="notification-item__meta">
          <BasePill
            v-if="hasSeverityLabel(notification.severity)"
            :variant="severityPillVariant(notification.severity)"
            uppercase
          >
            {{
              t(`labels.adminNotifications.severities.${notification.severity}`)
            }}
          </BasePill>
          <span>
            {{
              t(
                `labels.adminNotifications.types.${notification.notificationType}`,
              )
            }}
          </span>
          <span>
            {{ l(notification.createdAt, "datetime.formats.short") }}
          </span>
        </span>
      </span>
    </button>
    <div class="notification-item__actions">
      <Btn
        v-if="notification.archived"
        v-tooltip="t('actions.adminNotifications.unarchive')"
        :aria-label="t('actions.adminNotifications.unarchive')"
        @click="emit('unarchive')"
      >
        <i class="fa-duotone fa-inbox-in" />
      </Btn>
      <Btn
        v-else
        v-tooltip="t('actions.adminNotifications.archive')"
        :aria-label="t('actions.adminNotifications.archive')"
        @click="emit('archive')"
      >
        <i class="fa-duotone fa-box-archive" />
      </Btn>
      <Btn
        v-tooltip="t('actions.delete')"
        :aria-label="t('actions.delete')"
        :tone="BtnTonesEnum.DANGER"
        @click="emit('destroy')"
      >
        <i class="fa-duotone fa-trash" />
      </Btn>
    </div>
  </div>
</template>

<style lang="scss" scoped>
// The row surface a list of records wears elsewhere (ListGroup): a hairline and
// a tint instead of a Panel's framed edge. The tint is over $panel-bg rather
// than bare, because this page sits on a photo and ListGroup's translucent fill
// alone let the ship show through the titles. Severity used to colour the edge
// per row, which made a list of imports read as an alarm; the pill carries it
// now.
.notification-item {
  position: relative;
  display: flex;
  align-items: flex-start;
  gap: 5px;
  padding: 4px 8px 4px 0;
  background: $panel-bg;
  border: 1px solid rgba(#fff, 0.1);
  border-radius: 6px;
  transition: background 0.15s ease;

  &:hover {
    background: color.mix(#fff, $gray-darker, 6%);
  }
}

.notification-item--selected {
  background: color.mix(#fff, $gray-darker, 10%);

  // A bar rather than a border: an outline inside a row that already has one
  // reads as a box in a box.
  &::before {
    content: "";
    position: absolute;
    top: 6px;
    bottom: 6px;
    left: 0;
    width: 3px;
    background-color: var(--color-primary, #{$primary});
    // Rounded on the inner edge only - the outer edge sits against the row's
    // own border, where a curve would leave a sliver of it showing through.
    border-radius: 0 $border-radius-base $border-radius-base 0;
  }
}

.notification-item__select {
  display: flex;
  flex: 1;
  align-items: flex-start;
  gap: 12px;
  min-width: 0;
  padding: 8px 4px 8px 14px;
  color: inherit;
  font: inherit;
  text-align: left;
  background: none;
  border: 0;
  cursor: pointer;
}

.notification-item__icon {
  flex-shrink: 0;
  margin-top: 2px;
  color: $gray-lighter;
  font-size: 1.15em;
}

.notification-item--unread .notification-item__icon {
  color: var(--color-primary, #{$primary});
}

.notification-item__content {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: 3px;
  min-width: 0;
}

.notification-item__title {
  display: -webkit-box;
  overflow: hidden;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

.notification-item--unread .notification-item__title {
  font-weight: bold;
}

.notification-item__count {
  color: $gray-lighter;
  font-size: 0.85em;
}

.notification-item__meta {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
  color: $gray-lighter;
  font-size: 0.8em;
}

// Out of the way until the row is pointed at, so a page of notifications is
// titles rather than a column of buttons. Focus counts as pointing at it, and a
// device without a pointer never gets the chance to hover.
.notification-item__actions {
  display: flex;
  flex-shrink: 0;
  gap: 5px;
  margin-top: 4px;
  opacity: 0;
  transition: opacity 0.15s ease;
}

.notification-item:hover .notification-item__actions,
.notification-item:focus-within .notification-item__actions {
  opacity: 1;
}

@media (hover: none) {
  .notification-item__actions {
    opacity: 1;
  }
}
</style>
