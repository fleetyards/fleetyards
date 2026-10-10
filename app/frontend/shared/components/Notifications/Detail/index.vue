<script lang="ts">
export default {
  name: "SharedNotificationsDetail",
};
</script>

<script lang="ts" setup generic="T extends NotificationEntry">
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import Markdown from "@/shared/components/Markdown/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { NOTIFICATION_LABELS } from "@/shared/components/Notifications/labels";
import type {
  NotificationEntry,
  NotificationScope,
} from "@/shared/components/Notifications/types";

type Props = {
  notification?: T;
  typeLabel?: string;
  scope: NotificationScope;
};

const props = withDefaults(defineProps<Props>(), {
  notification: undefined,
  typeLabel: undefined,
});

const emit = defineEmits<{
  close: [];
  unread: [];
  archive: [];
  unarchive: [];
  destroy: [];
}>();

// Each slot is handed the open notification, typed as the caller's own
// record, so the caller's extras need no guard of their own.
defineSlots<{
  title?: (props: { notification: T }) => unknown;
  meta?: (props: { notification: T }) => unknown;
  actions?: (props: { notification: T }) => unknown;
  footer?: (props: { notification: T }) => unknown;
  facts?: (props: { notification: T }) => unknown;
}>();

const { t, l } = useI18n();

const labels = computed(() => NOTIFICATION_LABELS[props.scope]);

const body = ref<HTMLElement>();

// Reading pane, so a long notification left scrolled down must not carry that
// offset into the next one.
watch(
  () => props.notification?.id,
  () => {
    if (body.value) {
      body.value.scrollTop = 0;
    }
  },
);
</script>

<template>
  <Panel :variant="PanelVariantsEnum.SLIM" :outer-spacing="false">
    <div
      v-if="notification"
      ref="body"
      class="notification-detail"
      data-test="notification-detail"
    >
      <div class="notification-detail__header">
        <Btn
          class="notification-detail__back"
          :aria-label="t('actions.back')"
          @click="emit('close')"
        >
          <i class="fa-duotone fa-arrow-left" />
        </Btn>
        <i
          class="notification-detail__icon"
          :class="notification.icon || 'fa-duotone fa-bell'"
        />
        <div class="notification-detail__heading">
          <h2
            class="notification-detail__title"
            data-test="notification-detail-title"
          >
            {{ notification.title }}
            <slot name="title" :notification="notification" />
          </h2>
          <div class="notification-detail__meta">
            <slot name="meta" :notification="notification" />
            <span>{{ typeLabel }}</span>
            <span>{{ l(notification.createdAt) }}</span>
          </div>
        </div>
        <div class="notification-detail__actions">
          <slot name="actions" :notification="notification" />
          <Btn
            v-if="notification.read"
            v-tooltip="t(labels.unread)"
            :aria-label="t(labels.unread)"
            data-test="notification-detail-unread"
            @click="emit('unread')"
          >
            <i class="fa-duotone fa-envelope-dot" />
          </Btn>
          <Btn
            v-if="notification.archived"
            v-tooltip="t(labels.unarchive)"
            :aria-label="t(labels.unarchive)"
            data-test="notification-detail-unarchive"
            @click="emit('unarchive')"
          >
            <i class="fa-duotone fa-inbox-in" />
          </Btn>
          <Btn
            v-else
            v-tooltip="t(labels.archive)"
            :aria-label="t(labels.archive)"
            data-test="notification-detail-archive"
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

      <Markdown
        v-if="notification.body"
        class="notification-detail__body"
        data-test="notification-detail-body"
        :source="notification.body"
      />
      <p
        v-else
        class="notification-detail__body notification-detail__body--empty"
        data-test="notification-detail-no-body"
      >
        {{ t(labels.noBody) }}
      </p>

      <slot name="footer" :notification="notification" />

      <dl class="notification-detail__facts">
        <slot name="facts" :notification="notification" />
      </dl>
    </div>

    <div
      v-else
      class="notification-detail notification-detail--empty"
      data-test="notification-detail-empty"
    >
      <i class="fa-duotone fa-envelope-open-text" />
      <p>{{ t(labels.selectPrompt) }}</p>
    </div>
  </Panel>
</template>

<style lang="scss" scoped>
.notification-detail {
  padding: 16px 18px;
}

.notification-detail--empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  min-height: 240px;
  color: $gray-lighter;
  text-align: center;

  i {
    font-size: 2.5em;
    opacity: 0.6;
  }

  p {
    margin: 0;
  }
}

// Wraps rather than shrinking past the point where the title is readable: the
// actions drop to a row of their own once the heading would fall below its
// min-width, which is what the reading pane does on a phone.
.notification-detail__header {
  display: flex;
  align-items: flex-start;
  flex-wrap: wrap;
  gap: 14px;
}

.notification-detail__icon {
  flex-shrink: 0;
  margin-top: 4px;
  color: var(--color-primary, #{$primary});
  font-size: 1.5em;
}

// The min-width is what the header measures its line break against - at 0 the
// actions would stay beside a title squeezed to two words a line.
.notification-detail__heading {
  flex: 1;
  min-width: 180px;
}

.notification-detail__title {
  margin: 0;
  font-size: 1.2em;
  font-weight: bold;
}

.notification-detail__meta {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 6px;
  color: $gray-lighter;
  font-size: 0.85em;
}

.notification-detail__actions {
  display: flex;
  flex-shrink: 0;
  flex-wrap: wrap;
  gap: 5px;
}

.notification-detail__body {
  margin: 16px 0 0;
  padding: 12px 14px;
  color: $text-color;
  font-size: 0.9em;
  background-color: rgba($gray-darker, 0.6);
  border-radius: $border-radius-base;

  // The global reset strips list markers, which would turn an enumeration into
  // an indented run of lines with nothing to separate them.
  :deep(ul) {
    margin: 0;
    padding-left: 18px;
    list-style: disc;
  }
}

.notification-detail__body--empty {
  color: $gray-lighter;
  font-style: italic;
}

.notification-detail__facts {
  display: flex;
  flex-wrap: wrap;
  gap: 10px 24px;
  margin: 16px 0 0;
  color: $gray-lighter;
  font-size: 0.8em;

  // The facts are slotted, so they carry the caller's scope, not this one.
  :deep(dt) {
    font-weight: normal;
    opacity: 0.8;
  }

  :deep(dd) {
    margin: 0;
  }
}

// The reading pane only sits beside the list on a wide screen; below that it
// replaces the list, and needs the way back the two-pane layout does not.
.notification-detail__back {
  flex-shrink: 0;
}

@media (max-width: $tablet-breakpoint) {
  .notification-detail {
    padding: 12px 12px 14px;
  }

  .notification-detail__header {
    gap: 10px;
  }
}

@media (min-width: $notifications-two-pane-breakpoint) {
  .notification-detail__back {
    display: none;
  }

  // Only the pane that sits beside the list scrolls on its own: it is sticky,
  // so it has to stay inside the viewport. Alone on the page it is the page
  // that scrolls, and a second scroll region inside it hid the end of a long
  // notification.
  .notification-detail {
    max-height: calc(100vh - 60px);
    overflow: auto;
  }
}
</style>
