<script lang="ts">
export default {
  name: "BaseBtnDropdown",
};
</script>

<script lang="ts" setup>
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
});

const toggle = (event: MouseEvent) => {
  const { target } = event;

  if (target) {
    const bounding = (target as HTMLElement).getBoundingClientRect();

    const expandLeft =
      props.expandLeft || window.innerWidth - bounding.left < 300;
    const expandTop =
      (props.expandTop || window.innerHeight - bounding.top < 300) &&
      !props.expandBottom;

    const position: Record<string, string> = {};

    if (expandTop) {
      position.top = `${bounding.top + window.scrollY - 10}px`;
      position.transform = "translateY(-100%)";
    } else {
      position.top = `${bounding.bottom + window.scrollY + 10}px`;
    }

    if (expandLeft) {
      position.left = `${bounding.right + window.scrollX}px`;
      position.transform = (position.transform || "") + " translateX(-100%)";
    } else {
      position.left = `${bounding.left + window.scrollX}px`;
    }

    listPosition.value = position;
  }

  visible.value = !visible.value;
};

const wrapper = ref<HTMLElement | undefined>();
// Menu is a component, so the ref is an instance - reach its root element via
// $el for the outside-click test.
const btnList = ref<{ $el?: HTMLElement } | undefined>();

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
    :class="{ 'btn-dropdown--grouped': grouped }"
  >
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
</style>
