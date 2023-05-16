<template>
  <transition name="fade">
    <div v-if="loading" class="text-center">
      <div
        :class="{
          fixed: fixed,
        }"
        class="loader"
      >
        <div class="cube1 cube" />
        <div class="cube2 cube" />
        <div class="cube4 cube" />
        <div class="cube3 cube" />
      </div>
    </div>
  </transition>
</template>

<script lang="ts" setup>
type Props = {
  loading?: boolean;
  fixed?: boolean;
};

withDefaults(defineProps<Props>(), {
  loading: false,
  fixed: false,
});
</script>

<script lang="ts">
export default {
  name: "LoaderComponent",
};
</script>
