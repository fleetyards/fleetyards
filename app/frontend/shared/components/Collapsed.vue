<template>
  <transition
    :css="false"
    :on-before-enter="onBeforeEnter"
    :on-enter="enterTransition"
    :on-before-leave="onBeforeLeave"
    :on-leave="leaveTransition"
  >
    <component :is="as" v-if="visible" v-bind="$attrs">
      <slot />
    </component>
  </transition>
</template>

<script lang="ts" setup>
interface InitialElementStyle {
  height: string;
  width: string;
  position: string;
  visibility: string;
  overflow: string;
  paddingTop: string;
  paddingBottom: string;
  borderTopWidth: string;
  borderBottomWidth: string;
  marginTop: string;
  marginBottom: string;
}

type Props = {
  visible?: boolean;
  duration?: number;
  timingFunction?: string;
  timingFunctionEnter?: string;
  timingFunctionLeave?: string;
  as?: string;
};

const props = withDefaults(defineProps<Props>(), {
  visible: false,
  duration: 500,
  timingFunction: "ease",
  timingFunctionEnter: undefined,
  timingFunctionLeave: undefined,
  as: "div",
});

const emit = defineEmits([
  "open-start",
  "open-end",
  "close-start",
  "close-end",
]);

const getElementStyle = (element: HTMLElement) => ({
  height: element.style.height,
  width: element.style.width,
  position: element.style.position,
  visibility: element.style.visibility,
  overflow: element.style.overflow,
  paddingTop: element.style.paddingTop,
  paddingBottom: element.style.paddingBottom,
  borderTopWidth: element.style.borderTopWidth,
  borderBottomWidth: element.style.borderBottomWidth,
  marginTop: element.style.marginTop,
  marginBottom: element.style.marginBottom,
});

const prepareElement = (
  closedRef: Ref<string>,
  element: HTMLElement,
  initialStyle: InitialElementStyle,
) => {
  const closed = unref(closedRef);

  const { width } = getComputedStyle(element);
  element.style.width = width;
  element.style.position = "absolute";
  element.style.visibility = "hidden";
  element.style.height = "";

  const { height } = getComputedStyle(element);
  element.style.width = initialStyle.width;
  element.style.position = initialStyle.position;
  element.style.visibility = initialStyle.visibility;
  element.style.height = closed;
  element.style.overflow = "hidden";

  return initialStyle.height && initialStyle.height !== closed
    ? initialStyle.height
    : height;
};

const animateTransition = (
  element: HTMLElement,
  initialStyle: InitialElementStyle,
  done: () => void,
  keyframes: Keyframe[] | PropertyIndexedKeyframes | null,
  options?: number | KeyframeAnimationOptions,
) => {
  const animation = element.animate(keyframes, options);

  // Set height to 'auto' to restore it after animation
  element.style.height = initialStyle.height;

  animation.onfinish = () => {
    element.style.overflow = initialStyle.overflow;
    done();
  };
};

const getEnterKeyframes = (
  closedRef: Ref<string>,
  height: string,
  initialStyle: InitialElementStyle,
) => {
  const closed = unref(closedRef);

  return [
    {
      height: closed,
      paddingTop: closed,
      paddingBottom: closed,
      borderTopWidth: closed,
      borderBottomWidth: closed,
      marginTop: closed,
      marginBottom: closed,
    },
    {
      height,
      paddingTop: initialStyle.paddingTop || 0,
      paddingBottom: initialStyle.paddingBottom || 0,
      borderTopWidth: initialStyle.borderTopWidth || 0,
      borderBottomWidth: initialStyle.borderBottomWidth || 0,
      marginTop: initialStyle.marginTop || 0,
      marginBottom: initialStyle.marginBottom || 0,
    },
  ];
};

const closed = ref("0px");

const easingEnter = computed(
  () => props.timingFunctionEnter || props.timingFunction,
);

const easingLeave = computed(
  () => props.timingFunctionLeave || props.timingFunction,
);

const onBeforeEnter = () => {
  emit("open-start");
};

const enterTransition = (element: Element, done: () => void) => {
  const HTMLElement = element as HTMLElement;
  const initialStyle = getElementStyle(HTMLElement);
  const height = prepareElement(closed, HTMLElement, initialStyle);
  const keyframes = getEnterKeyframes(closed, height, initialStyle);
  const options = { duration: props.duration, easing: easingEnter.value };

  const doneCallback = () => {
    done();
    emit("open-end");
  };

  animateTransition(
    HTMLElement,
    initialStyle,
    doneCallback,
    keyframes,
    options,
  );
};

const onBeforeLeave = () => {
  emit("close-start");
};

const leaveTransition = (element: Element, done: () => void) => {
  const HTMLElement = element as HTMLElement;
  const initialStyle = getElementStyle(HTMLElement);

  const { height } = getComputedStyle(HTMLElement);
  HTMLElement.style.height = height;
  HTMLElement.style.overflow = "hidden";
  const keyframes = getEnterKeyframes(closed, height, initialStyle).reverse();
  const options = { duration: props.duration, easing: easingLeave.value };

  const doneCallback = () => {
    done();
    emit("close-end");
  };

  animateTransition(
    HTMLElement,
    initialStyle,
    doneCallback,
    keyframes,
    options,
  );
};
</script>

<script lang="ts">
export default {
  name: "CollapsedComponent",
};
</script>
