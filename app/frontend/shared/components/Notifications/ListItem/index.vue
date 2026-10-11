<script lang="ts">
export default {
  name: "SharedNotificationsListItem",
};
</script>

<script lang="ts" setup generic="T extends NotificationEntry">
import Btn from "@/shared/components/base/Btn/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type SwipeDirection,
  useSwipeActions,
} from "@/shared/composables/useSwipeActions";
import type {
  NotificationEntry,
  NotificationLabels,
} from "@/shared/components/Notifications/types";

type Props = {
  notification: T;
  typeLabel: string;
  labels: NotificationLabels;
  selected?: boolean;
  selectable?: boolean;
  checked?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  selected: false,
  selectable: false,
  checked: false,
});

const emit = defineEmits<{
  select: [];
  toggle: [checked: boolean];
  read: [];
  unread: [];
  archive: [];
  unarchive: [];
  destroy: [];
  previous: [];
  next: [];
}>();

// Each slot is handed the notification, typed as the caller's own record.
defineSlots<{
  title?: (props: { notification: T }) => unknown;
  meta?: (props: { notification: T }) => unknown;
  actions?: (props: { notification: T }) => unknown;
}>();

const { t, l } = useI18n();

const item = ref<HTMLElement>();

// Right to toggle read, left to file it away: the two a reader does to a row
// without opening it. Deleting stays a deliberate tap in the reading pane.
const toggleRead = () => {
  if (props.notification.read) {
    emit("unread");
  } else {
    emit("read");
  }
};

const toggleArchived = () => {
  if (props.notification.archived) {
    emit("unarchive");
  } else {
    emit("archive");
  }
};

const onSwipe = (direction: SwipeDirection) => {
  if (direction === "right") {
    toggleRead();
  } else {
    toggleArchived();
  }
};

const { offset, swiping, direction, armed } = useSwipeActions({
  target: item,
  onSwipe,
});

// The row eases back after the finger lifts, so the backdrop has to outlast the
// gesture by as long as that takes. A timer rather than `transitionend`: with
// reduced motion there is no transition to end.
const SETTLE_MS = 250;

const shownDirection = ref<SwipeDirection>();

// How much of the backdrop the row last uncovered. Kept through the settle
// too, or the label would vanish the moment the finger lifts.
const reveal = ref(0);

watch(offset, (next) => {
  if (next) {
    reveal.value = Math.abs(next);
  }
});

let settleTimer: ReturnType<typeof setTimeout> | undefined;

watch(direction, (next) => {
  clearTimeout(settleTimer);

  if (next) {
    shownDirection.value = next;
  } else {
    settleTimer = setTimeout(() => {
      shownDirection.value = undefined;
    }, SETTLE_MS);
  }
});

onBeforeUnmount(() => clearTimeout(settleTimer));

const readIcon = computed(() =>
  props.notification.read
    ? "fa-duotone fa-envelope-dot"
    : "fa-duotone fa-envelope-open",
);

const archiveIcon = computed(() =>
  props.notification.archived
    ? "fa-duotone fa-inbox-in"
    : "fa-duotone fa-box-archive",
);

const readLabel = computed(() =>
  props.notification.read ? t(props.labels.unread) : t(props.labels.read),
);

const archiveLabel = computed(() =>
  props.notification.archived
    ? t(props.labels.unarchive)
    : t(props.labels.archive),
);

const select = ref<HTMLButtonElement>();

// The page moves the selection with the arrow keys, and focus has to follow it
// so the next keypress lands on the row the reader is looking at.
defineExpose({ focus: () => select.value?.focus() });
</script>

<template>
  <div
    class="notification-row"
    :class="{
      [`notification-row--${shownDirection}`]: shownDirection,
      'notification-row--armed': armed,
    }"
    :style="{ '--swipe-reveal': `${reveal}px` }"
  >
    <div
      v-if="shownDirection"
      class="notification-row__backdrop"
      aria-hidden="true"
      data-test="notification-swipe-backdrop"
    >
      <span v-if="shownDirection === 'right'" class="notification-row__hint">
        <i :class="readIcon" />
        <span>{{ readLabel }}</span>
      </span>
      <span v-else class="notification-row__hint">
        <span>{{ archiveLabel }}</span>
        <i :class="archiveIcon" />
      </span>
    </div>
    <div
      ref="item"
      class="notification-item"
      data-test="notification-item"
      :class="{
        'notification-item--unread': !notification.read,
        'notification-item--selected': props.selected,
        'notification-item--selectable': props.selectable,
        'notification-item--swiping': swiping,
      }"
      :style="offset ? { transform: `translateX(${offset}px)` } : undefined"
    >
      <FormCheckbox
        v-if="props.selectable"
        v-tooltip="t(labels.select)"
        :model-value="props.checked"
        :aria-label="t(labels.select)"
        class="notification-item__checkbox"
        name="notification-selection"
        data-test="notification-checkbox"
        no-label
        inline
        @update:model-value="emit('toggle', $event)"
      />
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
            <slot name="title" :notification="notification" />
          </span>
          <span class="notification-item__meta">
            <slot name="meta" :notification="notification" />
            <span>{{ typeLabel }}</span>
            <span>
              {{ l(notification.createdAt, "datetime.formats.short") }}
            </span>
          </span>
        </span>
      </button>
      <div class="notification-item__actions">
        <slot name="actions" :notification="notification" />
        <Btn
          v-tooltip="archiveLabel"
          class="notification-item__housekeeping"
          :aria-label="archiveLabel"
          @click="toggleArchived"
        >
          <i :class="archiveIcon" />
        </Btn>
        <Btn
          v-tooltip="t('actions.delete')"
          class="notification-item__housekeeping"
          :aria-label="t('actions.delete')"
          :tone="BtnTonesEnum.DANGER"
          @click="emit('destroy')"
        >
          <i class="fa-duotone fa-trash" />
        </Btn>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
// The surface a swiped row slides off. Painted only while a row is moving, so a
// list at rest is the rows alone.
// Clipped, so a row dragged off its edge never widens the page.
.notification-row {
  position: relative;
  overflow: hidden;
}

$swipe-backdrop-inset: 18px;
$swipe-hint-gap: 12px;

.notification-row__backdrop {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  padding: 0 $swipe-backdrop-inset;
  color: $text-color;
  font-size: 0.85em;
  background: rgba($gray-light, 0.18);
  border-radius: 6px;
  transition: background 0.15s ease;
}

.notification-row--left .notification-row__backdrop {
  justify-content: flex-end;
}

// Past the threshold the backdrop takes on colour, which is the only sign that
// letting go now will act.
.notification-row--armed .notification-row__backdrop {
  background: color-mix(
    in srgb,
    var(--color-primary, #{$primary}) 45%,
    transparent
  );
}

// No wider than what the row has uncovered: a label longer than the travel,
// like the French "move back to inbox", ends in an ellipsis instead of
// running on under the row.
.notification-row__hint {
  display: flex;
  align-items: center;
  gap: 8px;
  max-width: max(
    0px,
    calc(var(--swipe-reveal, 0px) - #{$swipe-backdrop-inset + $swipe-hint-gap})
  );
  overflow: hidden;
  white-space: nowrap;

  > span {
    overflow: hidden;
    text-overflow: ellipsis;
  }
}

// The row surface a list of records wears elsewhere (ListGroup): a hairline and
// a tint instead of a Panel's framed edge. The tint is over $panel-bg rather
// than bare, because this page sits on a photo and ListGroup's translucent fill
// alone let the ship show through the titles.
.notification-item {
  position: relative;
  display: flex;
  align-items: flex-start;
  gap: 5px;
  padding: 4px 8px 4px 0;
  background: $panel-bg;
  border: 1px solid rgba(#fff, 0.1);
  border-radius: 6px;
  // Vertical travel scrolls the page; horizontal travel is the swipe's.
  touch-action: pan-y pinch-zoom;
  transition:
    background 0.15s ease,
    transform 0.2s ease;

  &:hover {
    background: color.mix(#fff, $gray-darker, 6%);
  }
}

// Opaque while it moves: the row's own fill is translucent so the page photo
// reads through it, and the backdrop's label would read through it too. The
// selected fill is opaque already and keeps its highlight.
.notification-row--left .notification-item:not(.notification-item--selected),
.notification-row--right .notification-item:not(.notification-item--selected) {
  background: $gray-darker;
}

// Following the finger, not easing after it - and turning opaque at once, or
// the label shows through for the length of a fade. Two classes, so the
// reduced-motion rule further down cannot bring the fade back.
.notification-item.notification-item--swiping {
  transition: none;
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

// The checkbox brings a form field's bottom margin, which a row has no use
// for, and it lines up with the first line of the title rather than the
// middle of a row that may run to two.
.notification-item__checkbox {
  flex-shrink: 0;
  margin-top: 10px;
  margin-bottom: 0;
  padding-left: 10px;
}

// The checkbox takes over the left inset, so the title stops carrying it.
.notification-item--selectable .notification-item__select {
  padding-left: 4px;
}

.notification-item__icon {
  flex-shrink: 0;
  // A fixed footprint rather than the glyph's own. The icon comes from the
  // notification type, its glyphs are not all the same width, and a column of
  // titles that steps in and out by a few pixels a row reads as a list that
  // cannot line itself up. 1.25em is the width a duotone glyph is drawn in, so
  // nothing is clipped and the placeholders can reserve the same.
  width: 1.25em;
  margin-top: 2px;
  color: $gray-lighter;
  font-size: 1.15em;
  text-align: center;
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

// A touch screen swipes a row to file it away instead, and the two buttons took
// most of the title's width on a phone. They stay in the row for a screen
// reader, which takes the swipe for itself, and come back into view for
// keyboard focus, so a keyboard never lands on an invisible button. Keyboard
// focus only: a tap focuses the row too, and would bring them back on every
// open. The way on stays.
@media (hover: none) and (pointer: coarse) {
  .notification-item:not(:has(:focus-visible))
    .notification-item__housekeeping {
    position: absolute;
    width: 1px;
    height: 1px;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    clip-path: inset(50%);
    white-space: nowrap;
  }
}

@media (prefers-reduced-motion: reduce) {
  .notification-item {
    transition: background 0.15s ease;
  }

  .notification-row__backdrop {
    transition: none;
  }
}

// A phone has no hover, so whatever actions the row still shows are permanently
// part of it and take their width off the title. The row gives back what
// padding it can.
@media (max-width: $tablet-breakpoint) {
  .notification-item {
    gap: 2px;
    padding-right: 6px;
  }

  .notification-item__select {
    gap: 10px;
    padding-left: 10px;
  }

  .notification-item__checkbox {
    padding-left: 6px;
  }

  .notification-item__actions {
    gap: 2px;
  }
}
</style>
