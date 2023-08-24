<template>
  <div ref="wrapper" class="panel-btn-dropdown" :class="cssClasses">
    <Btn
      :size="size"
      :variant="variant"
      :active="visible"
      :inline="true"
      :text-inline="textInline"
      :mobile-block="mobileBlock"
      :in-group="inGroup"
      @click="toggle"
    >
      <slot name="label">
        <i class="fas fa-ellipsis-v" />
      </slot>
    </Btn>
    <div
      ref="btnList"
      class="panel-btn-dropdown-list"
      :class="{
        visible,
        'expand-left': innerExpandLeft,
        'expand-top': innerExpandTop,
      }"
    >
      <slot />
    </div>
  </div>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/BaseBtn/index.vue";
import type {
  BtnSizes,
  BtnVariants,
} from "@/shared/components/BaseBtn/index.vue";

type Props = {
  size?: BtnSizes;
  variant?: BtnVariants;
  expandLeft?: boolean;
  expandTop?: boolean;
  mobileBlock?: boolean;
  inline?: boolean;
  textInline?: boolean;
  inGroup?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  size: "default",
  variant: "default",
  expandLeft: false,
  expandTop: false,
  mobileBlock: false,
  inline: false,
  textInline: false,
  inGroup: false,
});

const visible = ref(false);

const innerExpandLeft = ref(false);

const innerExpandTop = ref(false);

const cssClasses = computed(() => {
  return {
    "panel-btn-dropdown-inline": props.inline,
    "panel-btn-dropdown-in-group": props.inGroup,
  };
});

onMounted(() => {
  document.addEventListener("click", documentClick);

  innerExpandLeft.value = props.expandLeft;
  innerExpandTop.value = props.expandTop;
});

onUnmounted(() => {
  document.removeEventListener("click", documentClick);
});

const toggle = (event: MouseEvent) => {
  const { target } = event;

  if (target) {
    const bounding = (target as HTMLElement).getBoundingClientRect();

    innerExpandLeft.value =
      props.expandLeft || window.innerWidth - bounding.left < 200;
    innerExpandTop.value =
      props.expandTop || window.innerHeight - bounding.top < 200;
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
    (!wrapper.value?.contains(target as HTMLElement) ||
      btnList.value?.contains(target as HTMLElement))
  ) {
    visible.value = false;
  }
};
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
