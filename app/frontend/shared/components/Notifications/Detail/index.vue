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
import { useMobile } from "@/shared/composables/useMobile";
import { useScrollLock } from "@vueuse/core";
import type {
  NotificationEntry,
  NotificationLabels,
} from "@/shared/components/Notifications/types";

type Props = {
  notification?: T;
  typeLabel?: string;
  labels: NotificationLabels;
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

const body = ref<HTMLElement>();

const pane = ref<{ $el?: HTMLElement }>();

// Reading pane, so a long notification left scrolled down must not carry that
// offset into the next one. On a phone the pane is the page, and the pane's
// own box is what scrolls.
watch(
  () => props.notification?.id,
  () => {
    if (body.value) {
      body.value.scrollTop = 0;
    }
    if (pane.value?.$el) {
      pane.value.$el.scrollTop = 0;
    }
  },
);

const mobile = useMobile();

// On a phone an open notification covers the list rather than replacing it,
// so the list keeps its scroll position for the way back - and the page under
// the cover must not scroll along with a finger that runs off the pane's end.
const scrollLocked = useScrollLock(document.body);

watchEffect(() => {
  scrollLocked.value = mobile.value && !!props.notification;
});

onBeforeUnmount(() => {
  scrollLocked.value = false;
});
</script>

<template>
  <Panel
    ref="pane"
    class="notification-detail-pane"
    :class="{ 'notification-detail-pane--open': !!notification }"
    :variant="PanelVariantsEnum.SLIM"
    :outer-spacing="false"
  >
    <div
      v-if="notification"
      ref="body"
      class="notification-detail"
      data-test="notification-detail"
    >
      <!-- The way back and what can be done to the notification, as one bar
           over it wherever the pane stands alone. Beside the list there is no
           way back to offer, and the actions move up beside the title. A
           sibling of the header rather than part of it, because a sticky bar
           only sticks inside its parent's box. -->
      <div class="notification-detail__toolbar">
        <Btn
          class="notification-detail__back"
          :aria-label="t('actions.back')"
          data-test="notification-detail-back"
          @click="emit('close')"
        >
          <i class="fa-duotone fa-arrow-left" />
        </Btn>
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
      <div class="notification-detail__header">
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
      </div>

      <div
        v-if="notification.body"
        class="notification-detail__body"
        data-test="notification-detail-body"
      >
        <Markdown :source="notification.body" />
      </div>
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

.notification-detail__header {
  display: flex;
  align-items: flex-start;
  gap: 14px;
}

// A row of its own above the title.
.notification-detail__toolbar {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 14px;
}

.notification-detail__icon {
  flex-shrink: 0;
  margin-top: 4px;
  color: var(--color-primary, #{$primary});
  font-size: 1.5em;
}

.notification-detail__heading {
  flex: 1;
  min-width: 0;
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
  justify-content: flex-end;
  gap: 5px;
  margin-left: auto;
}

.notification-detail__body {
  margin: 24px 0 0;
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

  .notification-detail__toolbar {
    margin-bottom: 10px;
  }
}

// A page of its own on a phone: over everything the app puts around a page,
// the navigation included, and under what reports on top of it - the delete
// confirmation, the menus, the toasts. See the z-index scale in AppConfirm and
// BtnDropdown/Menu.
@media (max-width: $desktop-breakpoint) {
  .notification-detail-pane--open {
    position: fixed;
    inset: 0;
    z-index: 2010;
    margin: 0;
    overflow-y: auto;
    overscroll-behavior: contain;
    background-color: $gray-darker;
    border: 0;
    border-radius: 0;
  }

  .notification-detail-pane--open .notification-detail {
    min-height: 100%;
    padding-bottom: calc(14px + env(safe-area-inset-bottom));
  }

  // Held at the top while a long notification scrolls under it: the way back
  // and the actions are what a reader reaches for after reading, which is at
  // the bottom. Edge to edge, so nothing scrolls past beside it.
  .notification-detail-pane--open .notification-detail__toolbar {
    position: sticky;
    top: 0;
    z-index: 1;
    margin: -16px -18px 14px;
    padding: calc(10px + env(safe-area-inset-top)) 18px 10px;
    background-color: $gray-darker;
    border-bottom: 1px solid rgba(#fff, 0.08);
  }
}

@media (max-width: $tablet-breakpoint) {
  .notification-detail-pane--open .notification-detail__toolbar {
    margin: -12px -12px 10px;
    padding: calc(8px + env(safe-area-inset-top)) 12px 8px;
  }
}

// The installed app's band under the status bar (see the navigation header):
// the full-screen pane starts at the very top, so its bar clears the band too.
@media (max-width: $desktop-breakpoint) and (display-mode: standalone),
  (max-width: $desktop-breakpoint) and (display-mode: fullscreen) {
  .notification-detail-pane--open .notification-detail__toolbar {
    padding-top: calc(22px + env(safe-area-inset-top));
  }
}

@media (min-width: $notifications-two-pane-breakpoint) {
  .notification-detail__back {
    display: none;
  }

  // Beside the list the bar has nothing to hold but the actions, and they sit
  // at the end of the title's row: the bar takes the second column of the
  // first row, and everything else spans both.
  .notification-detail:not(.notification-detail--empty) {
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    column-gap: 14px;
  }

  .notification-detail:not(.notification-detail--empty) > :deep(*) {
    grid-column: 1 / -1;
  }

  .notification-detail > .notification-detail__header {
    grid-row: 1;
    grid-column: 1;
  }

  .notification-detail > .notification-detail__toolbar {
    grid-row: 1;
    grid-column: 2;
    align-self: start;
    margin-bottom: 0;
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
