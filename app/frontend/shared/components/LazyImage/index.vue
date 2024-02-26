<template>
  <component
    :is="componentType"
    v-if="src"
    :key="`${src}-${uuid}`"
    v-lazy:background-image="src"
    v-bind="componentProps"
    class="lazy-image"
  >
    <slot />
  </component>
</template>

<script lang="ts" setup>
import { v4 as uuidv4 } from "uuid";
import { RouteLocationRaw } from "vue-router";

type Props = {
  src: string;
  alt?: string;
  href?: string;
  to?: RouteLocationRaw;
};

const props = withDefaults(defineProps<Props>(), {
  alt: "image",
  href: undefined,
  to: undefined,
});

const uuid = ref<string>(uuidv4());

onMounted(() => {
  uuid.value = uuidv4();
});

const componentType = computed(() => {
  if (props.to) {
    return "router-link";
  }
  if (props.href) {
    return "a";
  }
  return "div";
});

const componentProps = computed(() => {
  if (props.to) {
    return {
      to: props.to,
    };
  }

  if (props.href) {
    return {
      href: props.href,
    };
  }

  return {};
});
</script>

<script lang="ts">
export default {
  name: "LazyImage",
};
</script>
