<script lang="ts">
export default {
  name: "NavMenu",
  // Test ids and labels belong to the trigger, not the list item around it.
  inheritAttrs: false,
};
</script>

<script lang="ts" setup>
import { storeToRefs } from "pinia";
import { useNavStore } from "@/shared/stores/nav";
import { useMobile } from "@/shared/composables/useMobile";
import { focusEdgeRow, hasModifier } from "../keyboard";

type Props = {
  // "up" for a menu anchored at the foot of the navigation.
  placement?: "down" | "up";
};

const props = withDefaults(defineProps<Props>(), {
  placement: "down",
});

const open = defineModel<boolean>("open", { default: false });

const mobile = useMobile();

const { slim: navSlim } = storeToRefs(useNavStore());

const slim = computed(() => navSlim.value && !mobile.value);

const route = useRoute();

const menuId = useId();

const root = ref<HTMLElement | null>(null);

const trigger = ref<HTMLButtonElement | null>(null);

const panel = ref<HTMLElement | null>(null);

const panelStyle = ref<Record<string, string>>({});

/*
 * Fixed rather than absolute for the same reason as a section's flyout: the
 * navigation scrolls on one axis and clips on the other, and only a box laid
 * out against the viewport gets out of it. On the collapsed rail the menu opens
 * beside it; expanded, it hangs from the trigger at the trigger's own width.
 */
const positionPanel = () => {
  const rect = trigger.value?.getBoundingClientRect();

  if (!rect) {
    return;
  }

  const style: Record<string, string> = {};

  if (slim.value) {
    style.left = `${rect.right + 8}px`;
  } else {
    style.left = `${rect.left}px`;
    style.width = `${rect.width}px`;
  }

  if (props.placement === "up") {
    const edge = slim.value ? rect.bottom : rect.top - 4;
    style.bottom = `${window.innerHeight - edge}px`;
  } else {
    style.top = `${slim.value ? rect.top : rect.bottom + 4}px`;
  }

  panelStyle.value = style;
};

const close = (returnFocus = false) => {
  open.value = false;

  if (returnFocus) {
    trigger.value?.focus();
  }
};

const toggle = () => {
  if (open.value) {
    close();

    return;
  }

  positionPanel();
  open.value = true;
};

const onKeydown = (event: KeyboardEvent) => {
  if (event.key === "Escape" && !event.defaultPrevented) {
    event.preventDefault();
    close(true);
  }
};

const enterMenu = async (edge: "first" | "last") => {
  open.value = true;

  await nextTick();

  focusEdgeRow(panel.value, edge);
};

const onMenuKeydown = (event: KeyboardEvent) => {
  if (event.defaultPrevented || hasModifier(event)) {
    return;
  }

  const onTrigger = event.target === trigger.value;

  if (
    onTrigger &&
    (event.key === "ArrowRight" || (open.value && event.key === "ArrowDown"))
  ) {
    event.preventDefault();
    void enterMenu("first");
  } else if (onTrigger && open.value && event.key === "ArrowUp") {
    event.preventDefault();
    void enterMenu("last");
  } else if (open.value && event.key === "ArrowLeft") {
    event.preventDefault();
    close(true);
  }
};

const onPointerDown = (event: Event) => {
  if (!root.value?.contains(event.target as Node)) {
    close();
  }
};

// Tabbing out of the menu is how a keyboard says it is done with it.
const onFocusOut = (event: FocusEvent) => {
  if (!open.value) {
    return;
  }

  const next = event.relatedTarget as Node | null;

  if (next && !root.value?.contains(next)) {
    close();
  }
};

// Every row either navigates or acts, and the menu has done its job either way.
const onPanelClick = (event: MouseEvent) => {
  if ((event.target as Element).closest("a, button")) {
    // A keyboard's click has no click count. Its row is about to be removed, and
    // focus would go with it, back to the top of the page.
    close(event.detail === 0);
  }
};

const listen = (listening: boolean) => {
  const method = listening ? "addEventListener" : "removeEventListener";

  document[method]("keydown", onKeydown as EventListener);
  document[method]("pointerdown", onPointerDown);
  window[method]("scroll", positionPanel, true);
  window[method]("resize", positionPanel);
};

watch(open, (value) => {
  if (value) {
    positionPanel();
  }

  listen(value);
});

watch(slim, () => {
  close();
});

watch(
  () => route.path,
  () => {
    close();
  },
);

onBeforeUnmount(() => {
  listen(false);
});
</script>

<template>
  <li
    ref="root"
    class="nav-menu"
    :class="{
      'nav-menu--slim': slim,
      'nav-menu--open': open,
    }"
    @focusout="onFocusOut"
    @keydown="onMenuKeydown"
  >
    <button
      ref="trigger"
      type="button"
      class="nav-menu__trigger"
      :aria-expanded="open"
      :aria-controls="open ? menuId : undefined"
      v-bind="$attrs"
      @click="toggle"
    >
      <slot name="trigger" :slim="slim" :open="open" />
    </button>
    <ul
      v-if="open"
      :id="menuId"
      ref="panel"
      class="nav-menu__panel"
      :class="{ 'nav-menu__panel--slim': slim }"
      :style="panelStyle"
      @click="onPanelClick"
    >
      <slot />
    </ul>
  </li>
</template>

<style lang="scss" scoped>
@import "index";
</style>
