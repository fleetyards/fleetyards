<script lang="ts">
export default {
  name: "NavItem",
};
</script>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import type { RouteLocationNamedRaw, RouterLinkProps } from "vue-router";
import NavItemInner from "./NavItemInner/index.vue";
import { NAV_EXPANDED, openFlyout } from "./context";
import { useMobile } from "@/shared/composables/useMobile";
import Collapsed from "@/shared/components/Collapsed.vue";
import { storeToRefs } from "pinia";
import { useNavStore } from "@/shared/stores/nav";

type Props = {
  to?: RouterLinkProps["to"];
  action?: () => void;
  href?: string;
  label?: string;
  // Shown in both states, where `label` stands in only once the navigation
  // collapses. For a row whose slot carries something the label does not say.
  tooltip?: string;
  icon?: string;
  image?: string;
  avatar?: boolean;
  menuKey?: string;
  divider?: boolean;
  active?: boolean;
  submenuActive?: boolean;
  submenuDirection?: string;
  badge?: number;
};

const props = withDefaults(defineProps<Props>(), {
  to: undefined,
  action: undefined,
  href: undefined,
  label: undefined,
  tooltip: undefined,
  icon: undefined,
  image: undefined,
  avatar: false,
  menuKey: undefined,
  divider: false,
  active: false,
  submenuActive: false,
  submenuDirection: "down",
  badge: 0,
});

const open = ref(false);

const route = useRoute();

const mobile = useMobile();

const navStore = useNavStore();

const { slim: navSlim } = storeToRefs(navStore);

const expanded = inject(NAV_EXPANDED, undefined);

const slim = computed(() => navSlim.value && !mobile.value && !expanded?.value);

const slots = useSlots();

const hasSubmenuSlot = computed(() => !!slots.submenu);

/*
 * A collapsed rail has no width to nest rows in -- an icon indented under
 * another icon says nothing -- so a section opens beside the rail instead of
 * inside it, where its rows can carry their labels.
 */
const flyout = computed(() => hasSubmenuSlot.value && slim.value);

provide(
  NAV_EXPANDED,
  computed(() => flyout.value || !!expanded?.value),
);

const routeActive = computed(() => {
  if (props.to) {
    return (props.to as RouteLocationNamedRaw).name === route.name;
  }
  return false;
});

const tooltipOptions = computed(() => {
  // The flyout heads itself with the section's name, so a tooltip would
  // otherwise say it twice -- the second time laid over the panel saying it.
  if (flyout.value && !props.tooltip) {
    return null;
  }

  const content = props.tooltip ?? (slim.value ? props.label : null);

  if (!content) {
    return null;
  }

  return {
    content,
    placement: "right",
  };
});

const navKey = computed(() => {
  if (props.menuKey) {
    return props.menuKey;
  }

  if (props.to && (props.to as RouteLocationNamedRaw).name) {
    return String((props.to as RouteLocationNamedRaw).name);
  }

  return "nav-item";
});

const root = ref<HTMLElement | null>(null);

const trigger = ref<HTMLElement | null>(null);

const panel = ref<HTMLElement | null>(null);

const flyoutOpen = ref(false);

const flyoutId = Symbol("navFlyout");

/*
 * A pointer opens the panel on its way past; a click says to keep it there. The
 * two have to be told apart: a tap fires both, so without the distinction it
 * would open and close again in one gesture -- and a tablet wide enough for the
 * collapsed rail has no hover to fall back on.
 */
const pinned = ref(false);

const panelStyle = ref<Record<string, string>>({});

/*
 * `position: fixed` is what lets the panel out of the rail: the wrapper around
 * it scrolls on one axis and clips on the other, and no `overflow: visible`
 * can undo that pairing -- but a fixed box is laid out against the viewport and
 * escapes both. It pays for that by not moving with the rail, so the rail's own
 * scrolling has to push it by hand.
 *
 * It holds only while no ancestor is transformed, which would take the
 * containing block back off the viewport. One place does that: the admin's
 * `nav-panel` transition puts `translateX(-100%)` on the wrapper (see
 * stylesheets/shared/transitions.scss) while the whole navigation enters or
 * leaves. A panel open across those 500ms is clipped and misplaced.
 *
 * Left alone deliberately. `Teleport` would fix it and cost more than it is
 * worth: outside the row's `li` the panel is no longer in the navigation's tab
 * order, so its rows stop being reachable by keyboard -- which is the reason
 * this is not teleported already -- and every pointer, focus and outside-click
 * check would have to consult two roots instead of one. The window is a
 * navigation that is on its way off screen anyway.
 */
const positionPanel = () => {
  const element = trigger.value;

  if (!element) {
    return;
  }

  const rect = element.getBoundingClientRect();
  const height = panel.value?.offsetHeight ?? 0;

  panelStyle.value = {
    top: `${Math.max(8, Math.min(rect.top, window.innerHeight - height - 8))}px`,
    left: `${rect.right}px`,
  };
};

let closeTimer: ReturnType<typeof setTimeout> | undefined;

const clearCloseTimer = () => {
  if (closeTimer) {
    clearTimeout(closeTimer);
    closeTimer = undefined;
  }
};

/*
 * Set when the section is dismissed on purpose -- Escape, or a click on its own
 * row -- and cleared once the pointer and the focus have both left. Without it
 * Escape cannot close the panel at all: handing focus back to the trigger is
 * itself a `focusin` on the row, which reopens what was just dismissed.
 */
const dismissed = ref(false);

const closeFlyout = (deliberate = false) => {
  clearCloseTimer();
  dismissed.value = deliberate;
  pinned.value = false;
  flyoutOpen.value = false;

  if (openFlyout.value === flyoutId) {
    openFlyout.value = null;
  }
};

const showFlyout = async (pin = false) => {
  clearCloseTimer();

  pinned.value = pinned.value || pin;
  openFlyout.value = flyoutId;

  if (flyoutOpen.value) {
    return;
  }

  /*
   * Placed before it is shown, not after. Parking it off-screen for a frame
   * left a window in which the pointer could arrive where the panel was about
   * to be and find nothing there. The trigger's rect is enough for that first
   * placement; only the clamp that keeps a long panel inside the viewport needs
   * the panel's own height, so that pass runs once it exists.
   */
  positionPanel();
  flyoutOpen.value = true;

  await nextTick();

  positionPanel();
};

watch(openFlyout, (current) => {
  if (flyoutOpen.value && current !== flyoutId) {
    closeFlyout();
  }
});

let pointerX = -1;

let pointerY = -1;

const rememberPointer = (event: PointerEvent) => {
  pointerX = event.clientX;
  pointerY = event.clientY;
};

/*
 * The row and its panel are one hover target wearing two boxes, with a gap
 * between them, so the pointer leaves one of them on the way to the other and
 * every crossing looks like an exit.
 *
 * Cancelling that on the way back in does not work: the panel is a *child* of
 * the row's `li`, so a pointer arriving from the panel never left the `li` and
 * `pointerenter` does not fire again -- the close the panel scheduled as the
 * pointer left it then runs while the pointer sits on the row, and the panel
 * vanishes from under it.
 *
 * So the close asks where the pointer actually is rather than trusting the
 * event that scheduled it. `root` holds both boxes, which is the whole target.
 */
const pointerWithinSection = () => {
  if (pointerX < 0) {
    return false;
  }

  const under = document.elementFromPoint(pointerX, pointerY);

  return !!under && !!root.value?.contains(under);
};

const scheduleClose = () => {
  clearCloseTimer();

  closeTimer = setTimeout(() => {
    if (pointerWithinSection()) {
      return;
    }

    closeFlyout();
  }, 220);
};

const onPointerEnter = (event: PointerEvent) => {
  rememberPointer(event);

  if (!flyout.value || dismissed.value) {
    return;
  }

  void showFlyout();
};

const onPointerLeave = (event: PointerEvent) => {
  rememberPointer(event);

  if (!flyout.value || pinned.value) {
    return;
  }

  dismissed.value = false;
  scheduleClose();
};

const onPanelEnter = (event: PointerEvent) => {
  rememberPointer(event);
  clearCloseTimer();
};

const onPanelLeave = (event: PointerEvent) => {
  rememberPointer(event);
  scheduleClose();
};

const onFocusIn = () => {
  if (!flyout.value || dismissed.value) {
    return;
  }

  void showFlyout();
};

// Tabbing past the last row in the panel, or back past the trigger, is the only
// way a keyboard says it is done with the section.
const onFocusOut = (event: FocusEvent) => {
  if (!flyout.value) {
    return;
  }

  const next = event.relatedTarget as Node | null;

  if (next && (event.currentTarget as HTMLElement).contains(next)) {
    return;
  }

  closeFlyout();
};

const onKeydown = (event: KeyboardEvent) => {
  if (event.key !== "Escape") {
    return;
  }

  closeFlyout(true);
  trigger.value?.focus();
};

// A pinned panel outlives the pointer that opened it, so something on the page
// has to be able to put it away again.
const onPointerDown = (event: Event) => {
  if (root.value?.contains(event.target as Node)) {
    return;
  }

  closeFlyout();
};

// `capture` on the scroll, because the rail scrolls in its own box and that
// event does not bubble to the window.
const trackViewport = (listening: boolean) => {
  const method = listening ? "addEventListener" : "removeEventListener";

  document[method]("keydown", onKeydown as EventListener);
  document[method]("pointerdown", onPointerDown);
  // So the close knows where the pointer is even when it got there without
  // crossing either box's own boundary.
  document[method]("pointermove", rememberPointer as EventListener);
  window[method]("scroll", positionPanel, true);
  window[method]("resize", positionPanel);
};

/*
 * Where the node marking the open page sits on the rail, measured from the top
 * of the list.
 *
 * It travels rather than reappearing on the new row, and that is the whole
 * reason it is one element belonging to the list instead of an `::after` on
 * each row: a pseudo-element cannot animate into another element's. So the row
 * no longer draws its own mark -- the list is told where to put the one node
 * and moves it there.
 */
const railNode = ref<number | null>(null);

// The first placement must not animate, or the node slides down from the top of
// the rail every time a section opens.
const settled = ref(false);

const railNodeStyle = computed(() =>
  railNode.value === null
    ? undefined
    : { "--nav-node-y": `${railNode.value}px` },
);

const measureRailNode = () => {
  const list = root.value?.querySelector(":scope > ul");

  if (!list) {
    railNode.value = null;

    return;
  }

  const active = list.querySelector<HTMLElement>(
    ":scope > li.nav-item--active",
  );

  /*
   * A collapsed list is `display: none`, which takes `offsetParent` and every
   * offset with it. Measuring then would park the node at the top of the rail
   * and let it slide down from there when the section next opens.
   */
  if (!active?.offsetParent) {
    railNode.value = null;

    return;
  }

  railNode.value = active.offsetTop + active.offsetHeight / 2;
};

// Rows arrive after the first render -- a fleet list is fetched, a label wraps
// at a narrower width -- and each changes where the node belongs.
let listObserver: ResizeObserver | undefined;

/*
 * Re-attached rather than bound once at mount: the list is `v-if`-ed away in
 * flyout mode, so the navigation's default -- collapsed -- mounts without one
 * at all, and expanding the rail builds a list nothing is watching. Collapsing
 * again would leave the observer holding a node that is no longer in the
 * document.
 */
const observeList = () => {
  listObserver?.disconnect();
  listObserver = undefined;

  const list = root.value?.querySelector(":scope > ul");

  // The `typeof` guard is load-bearing for eslint-plugin-compat, which reads
  // this shape and not an early return.
  if (list && typeof ResizeObserver !== "undefined") {
    listObserver = new ResizeObserver(() => measureRailNode());
    listObserver.observe(list);
  }
};

const trackRailNode = async () => {
  await nextTick();

  observeList();
  measureRailNode();
};

watch(flyoutOpen, (value) => {
  trackViewport(value);
});

watch([() => route.fullPath, open, flyout], () => {
  void trackRailNode();
});

/*
 * Leaving flyout mode unmounts the panel and says nothing about the state
 * behind it -- the rail expanded, or the viewport narrowed to where the
 * navigation is a drawer. Left open, the section hands a panel nobody asked for
 * straight back the moment flyout mode returns, and its keydown, pointer and
 * viewport listeners stay bound to the document for the whole time in between.
 */
watch(flyout, (isFlyout) => {
  if (isFlyout) {
    return;
  }

  closeFlyout();
});

watch(
  () => route,
  () => {
    checkRoutes();
  },
  { deep: true },
);

watch(
  () => props.submenuActive,
  () => {
    checkRoutes();
  },
);

/*
 * A navigation puts the panel away -- but only a navigation. The deep watcher
 * above fires for any change to the route object at all, and a page rewriting
 * its own query (a filter, a sort order) is not the reader leaving the page.
 * Closing on those took the panel away seconds after it opened, for no reason
 * the reader could see.
 */
watch(
  () => route.path,
  () => {
    closeFlyout();
  },
);

onMounted(async () => {
  checkRoutes();

  await trackRailNode();

  requestAnimationFrame(() => {
    settled.value = true;
  });
});

onBeforeUnmount(() => {
  clearCloseTimer();
  trackViewport(false);
  listObserver?.disconnect();
});

const checkRoutes = () => {
  open.value = props.submenuActive;
};

const toggleMenu = () => {
  if (flyout.value) {
    if (pinned.value) {
      closeFlyout(true);
    } else {
      void showFlyout(true);
    }

    return;
  }

  open.value = !open.value;
};
</script>

<template>
  <li v-if="divider" class="nav-item__divider" />
  <li
    v-else-if="hasSubmenuSlot"
    ref="root"
    :style="railNodeStyle"
    :class="{
      'nav-item__sub-menu--active': active || submenuActive,
      'nav-item__sub-menu--open': open && !flyout,
      'nav-item__sub-menu--flyout': flyout,
      'nav-item__sub-menu--flyout-open': flyoutOpen,
      'nav-item__sub-menu--marked': railNode !== null,
      'nav-item__sub-menu--settled': settled,
      'nav-item--slim': slim,
    }"
    :data-test="`nav-${navKey}`"
    class="nav-item nav-item__sub-menu"
    @pointerenter="onPointerEnter"
    @pointerleave="onPointerLeave"
    @focusin="onFocusIn"
    @focusout="onFocusOut"
  >
    <Collapsed
      v-if="!flyout && submenuDirection === 'up'"
      :id="`${menuKey}-sub-menu`"
      as="ul"
      :visible="open"
    >
      <slot name="submenu" />
    </Collapsed>
    <button
      ref="trigger"
      v-tooltip="tooltipOptions"
      type="button"
      @click="toggleMenu"
    >
      <slot>
        <NavItemInner
          :label="label"
          :icon="icon"
          :image="image"
          :avatar="avatar"
          :slim="slim"
          :badge="badge"
        />
        <!-- The one mark that tells a section from a page, so it has to survive
             the rail collapsing -- where it shrinks to a caret against the
             icon rather than leaving with the labels. -->
        <span
          class="nav-item__submenu-icon"
          :class="{ 'nav-item__submenu-icon--up': submenuDirection === 'up' }"
        >
          <i class="fa-solid fa-chevron-right" />
        </span>
      </slot>
    </button>
    <Collapsed
      v-if="!flyout && submenuDirection === 'down'"
      :id="`${menuKey}-sub-menu`"
      :visible="open"
      as="ul"
    >
      <slot name="submenu" />
    </Collapsed>
    <Transition name="nav-flyout">
      <div
        v-if="flyout && flyoutOpen"
        :id="`${menuKey}-sub-menu`"
        ref="panel"
        class="nav-flyout"
        :style="panelStyle"
        @pointerenter="onPanelEnter"
        @pointerleave="onPanelLeave"
      >
        <div class="nav-flyout__title">
          {{ label }}
        </div>
        <ul class="nav-flyout__items">
          <slot name="submenu" />
        </ul>
      </div>
    </Transition>
  </li>
  <li
    v-else-if="action"
    :class="{
      'nav-item--slim': slim,
    }"
    :data-test="`nav-${navKey}`"
    class="nav-item"
  >
    <!-- A button rather than an anchor with a click handler on the row: an
         anchor with no href is not a tab stop and answers to no key, so a row
         built this way -- logout, the collapse toggle, the build switch -- could
         only ever be reached with a pointer. -->
    <button v-tooltip="tooltipOptions" type="button" @click="action">
      <slot>
        <NavItemInner
          :label="label"
          :icon="icon"
          :image="image"
          :avatar="avatar"
          :slim="slim"
          :badge="badge"
        />
      </slot>
    </button>
  </li>
  <router-link
    v-else-if="to"
    v-slot="{ href: linkHref, navigate }"
    :to="to"
    custom
  >
    <li
      role="link"
      :class="{
        'nav-item--active': active || routeActive,
        'nav-item--slim': slim,
      }"
      :data-test="`nav-${navKey}`"
      class="nav-item"
      @click="navigate"
      @keypress.enter="() => navigate"
    >
      <a v-tooltip="tooltipOptions" :href="linkHref">
        <slot>
          <NavItemInner
            :label="label"
            :icon="icon"
            :image="image"
            :avatar="avatar"
            :slim="slim"
            :badge="badge"
          />
        </slot>
      </a>
    </li>
  </router-link>
  <li
    v-else-if="href"
    :class="{
      'nav-item--slim': slim,
    }"
    class="nav-item"
    :data-test="`nav-${navKey}`"
  >
    <a v-tooltip="tooltipOptions" :href="href" target="_blank" rel="noopener">
      <slot>
        <NavItemInner
          :label="label"
          :icon="icon"
          :image="image"
          :avatar="avatar"
          :slim="slim"
          :badge="badge"
        />
      </slot>
    </a>
  </li>
  <li
    v-else
    :class="{
      'nav-item--slim': slim,
    }"
    class="nav-item"
  >
    <span>
      <slot>
        <NavItemInner
          :label="label"
          :icon="icon"
          :image="image"
          :avatar="avatar"
          :slim="slim"
          :badge="badge"
        />
      </slot>
    </span>
  </li>
</template>

<style lang="scss">
@import "index";
</style>
