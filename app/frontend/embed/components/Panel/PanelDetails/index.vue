<template>
  <div
    ref="panelDetails"
    class="panel-details"
    :style="{ height: `${height}px` }"
  >
    <slot />
  </div>
</template>

<script lang="ts" setup>
type Props = {
  visible: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  visible: false,
});

const height = ref(0);

watch(
  () => props.visible,
  () => {
    setupHeight();
  }
);

onMounted(() => {
  setupHeight();
});

const panelDetails = ref<HTMLElement | null>(null);

const setupHeight = () => {
  if (props.visible && panelDetails.value) {
    height.value = panelDetails.value.scrollHeight;
  } else {
    height.value = 0;
  }
};
</script>

<script lang="ts">
export default {
  name: "PanelDetails",
};
</script>
