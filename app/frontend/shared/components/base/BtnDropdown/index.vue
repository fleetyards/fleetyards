<script lang="ts">
export default {
  name: "BaseBtnDropdown",
};
</script>

<script lang="ts" setup>
import debounce from "lodash.debounce";
import Btn from "@/shared/components/base/Btn/index.vue";
import Menu from "@/shared/components/base/BtnDropdown/Menu/index.vue";
import { BTN_CONTAINER } from "@/shared/components/base/Btn/context";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
  BtnTonesEnum,
} from "@/shared/components/base/Btn/types";

type Props = {
  size?: `${BtnSizesEnum}`;
  variant?: `${BtnVariantsEnum}`;
  tone?: `${BtnTonesEnum}`;
  expandLeft?: boolean;
  expandTop?: boolean;
  expandBottom?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  size: undefined,
  variant: BtnVariantsEnum.SOLID,
  tone: BtnTonesEnum.NEUTRAL,
  expandLeft: false,
  expandTop: false,
  expandBottom: false,
});

const visible = ref(false);

const listPosition = ref<Record<string, string>>({});

// Injected, not provided: BtnGroup is an ancestor, and Menu is what provides the
// "menu" context for the list items.
const container = inject(BTN_CONTAINER, null);

const grouped = computed(() => container?.container === "group");

onMounted(() => {
  document.addEventListener("click", documentClick);
});

onUnmounted(() => {
  document.removeEventListener("click", documentClick);
  stopWatching();
});

const wrapper = ref<HTMLElement | undefined>();
// Menu is a component, so the ref is an instance - reach its root element via
// $el for the outside-click test and for measuring it.
const btnList = ref<{ $el?: HTMLElement } | undefined>();

/*
 * The trigger, kept rather than read from the event: the menu is re-placed long
 * after the click that opened it, when a scroll has changed how much room is
 * left around it.
 */
const triggerElement = ref<HTMLElement | null>(null);

// Stands the menu off its trigger. Written once, used by both sides.
const MENU_OFFSET = 10;

/*
 * Which side the menu opens on, measured.
 *
 * This used to guess: "within 300px of an edge" stood in for "does not fit",
 * which is wrong in both directions -- a short menu was pushed upwards with room
 * to spare, and a long one still ran off the bottom. The menu is teleported and
 * visible by the time this runs, so its real size can simply be read.
 *
 * The explicit props still win: a caller that says expandTop means it.
 */
const placeMenu = () => {
  const trigger = triggerElement.value;
  const menu = btnList.value?.$el;

  if (!trigger || !menu) {
    return;
  }

  const bounding = trigger.getBoundingClientRect();
  const { height, width } = menu.getBoundingClientRect();

  const fitsBelow =
    bounding.bottom + MENU_OFFSET + height <= window.innerHeight;
  const fitsAbove = bounding.top - MENU_OFFSET - height >= 0;
  const expandTop =
    !props.expandBottom && (props.expandTop || (!fitsBelow && fitsAbove));

  const fitsRight = bounding.left + width <= window.innerWidth;
  const fitsLeft = bounding.right - width >= 0;
  const expandLeft = props.expandLeft || (!fitsRight && fitsLeft);

  const position: Record<string, string> = {};
  const transform: string[] = [];

  if (expandTop) {
    position.top = `${bounding.top + window.scrollY - MENU_OFFSET}px`;
    transform.push("translateY(-100%)");
  } else {
    position.top = `${bounding.bottom + window.scrollY + MENU_OFFSET}px`;
  }

  if (expandLeft) {
    position.left = `${bounding.right + window.scrollX}px`;
    transform.push("translateX(-100%)");
  } else {
    position.left = `${bounding.left + window.scrollX}px`;
  }

  if (transform.length) {
    position.transform = transform.join(" ");
  }

  listPosition.value = position;
};

/*
 * The side, re-checked once the scrolling stops. Scrolling changes how much room
 * is left around the trigger, so a menu that opened downwards can end up hanging
 * off the bottom of the window -- but turning it over while the scroll is still
 * running is a flip nobody asked for. Waiting for the rest gives both.
 *
 * Where the menu is needs no such handling: it is placed in document
 * coordinates and teleported to the body, so it travels with the page by being
 * left alone.
 */
const reconsiderSide = debounce(placeMenu, 150);

const stopWatching = () => {
  window.removeEventListener("scroll", reconsiderSide, true);
  window.removeEventListener("resize", reconsiderSide);
  reconsiderSide.cancel();
};

watch(visible, async (isVisible) => {
  if (!isVisible) {
    stopWatching();

    return;
  }

  // Measured after it is on screen: the menu is display:none until then, and a
  // hidden element has no size to read.
  await nextTick();

  placeMenu();

  // `true` catches the scrollers on the way up, which do not bubble.
  window.addEventListener("scroll", reconsiderSide, true);
  window.addEventListener("resize", reconsiderSide);
});

const toggle = (event: MouseEvent) => {
  // The trigger, not whatever was clicked inside it: a click landing on a label
  // or an icon would otherwise anchor the menu to that glyph's box.
  triggerElement.value = (event.currentTarget ||
    event.target) as HTMLElement | null;

  visible.value = !visible.value;
};

const documentClick = (event: MouseEvent) => {
  if (!visible.value) return;

  const { target } = event;

  if (
    target !== wrapper.value &&
    !wrapper.value?.contains(target as HTMLElement) &&
    !btnList.value?.$el?.contains(target as HTMLElement)
  ) {
    visible.value = false;
  }
};
</script>

<template>
  <div
    ref="wrapper"
    class="btn-dropdown"
    :class="{
      'btn-dropdown--grouped': grouped,
      'btn-dropdown--custom-trigger': !!$slots.trigger,
    }"
  >
    <slot name="trigger" :toggle="toggle" :visible="visible">
      <Btn
        :size="size"
        :variant="variant"
        :tone="tone"
        :active="visible"
        aria-haspopup="menu"
        :aria-expanded="visible"
        @click="toggle"
      >
        <slot name="label">
          <i class="fa-solid fa-ellipsis-v" />
        </slot>
      </Btn>
    </slot>
    <Teleport to="body">
      <Menu
        ref="btnList"
        :visible="visible"
        :position="listPosition"
        @click="visible = false"
      >
        <slot />
      </Menu>
    </Teleport>
  </div>
</template>

<style scoped>
@reference "../../../../entrypoints/tailwind.css";

.btn-dropdown {
  @apply relative inline-block;
  margin: 0;
}

/*
 * Inside a BtnGroup this wrapper must not form a box, otherwise the trigger is
 * both :first-child and :last-child of *the wrapper* - so it picks up rounded
 * corners on both sides and the group's own :first/:last-child rules never match
 * it. display:contents promotes the trigger to a direct flex child of the group.
 * The outside-click test uses DOM containment, which is unaffected.
 */
.btn-dropdown--grouped {
  display: contents;
}

/*
 * A custom trigger brings its own box, and one that positions itself - the
 * panel tag pins to the bottom of a panel - has to resolve against the panel
 * rather than against this wrapper. Same call as above, for the same reason.
 */
.btn-dropdown--custom-trigger {
  display: contents;
}
</style>
