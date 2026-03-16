<script lang="ts">
export default {
  name: "BaseBtnDropdown",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";

type Props = {
  size?: `${BtnSizesEnum}`;
  variant?: `${BtnVariantsEnum}`;
  expandLeft?: boolean;
  expandTop?: boolean;
  expandBottom?: boolean;
  mobileBlock?: boolean;
  inline?: boolean;
  textInline?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  size: BtnSizesEnum.DEFAULT,
  variant: BtnVariantsEnum.DEFAULT,
  expandLeft: false,
  expandTop: false,
  expandBottom: false,
  mobileBlock: false,
  inline: false,
  textInline: false,
});

const visible = ref(false);

const listPosition = ref<Record<string, string>>({});

const cssClasses = computed(() => {
  return {
    "panel-btn-dropdown--inline": props.inline,
  };
});

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
const btnList = ref<HTMLElement | undefined>();

const documentClick = (event: MouseEvent) => {
  if (!visible.value) return;

  const { target } = event;

  if (
    target !== wrapper.value &&
    !wrapper.value?.contains(target as HTMLElement) &&
    !btnList.value?.contains(target as HTMLElement)
  ) {
    visible.value = false;
  }
};
</script>

<template>
  <div ref="wrapper" class="panel-btn-dropdown" :class="cssClasses">
    <Btn
      :size="size"
      :variant="variant"
      :active="visible"
      :text-inline="textInline"
      :mobile-block="mobileBlock"
      inline
      @click="toggle"
    >
      <slot name="label">
        <i class="fa-solid fa-ellipsis-v" />
      </slot>
    </Btn>
    <Teleport to="body">
      <div
        ref="btnList"
        class="panel-btn-dropdown__list"
        :class="{
          visible,
        }"
        :style="listPosition"
      >
        <slot />
      </div>
    </Teleport>
  </div>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
