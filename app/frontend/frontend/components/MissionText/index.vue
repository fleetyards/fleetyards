<script lang="ts">
export default {
  name: "MissionText",
};
</script>

<script lang="ts" setup>
import {
  type MissionTextValue,
  missionTextParts,
} from "@/frontend/components/MissionText/index";

type Props = {
  text?: string | null;
  /** Keeps the line breaks the game writes. Off for a title, on for prose. */
  multiline?: boolean;
  /** What the files state for its placeholders, filled in before rendering. */
  values?: MissionTextValue[] | null;
};

const props = defineProps<Props>();

const parts = computed(() => missionTextParts(props.text, props.values));
</script>

<template>
  <span class="mission-text" :class="{ 'mission-text--multiline': multiline }">
    <template v-for="(part, index) in parts" :key="index">
      <em v-if="part.kind === 'emphasis'" class="mission-text__emphasis">{{
        part.value
      }}</em>
      <!-- What the game will fill in, named rather than guessed at: a
           placeholder left here is one the files state no value for. -->
      <span v-else-if="part.kind === 'token'" class="mission-text__token">{{
        part.value
      }}</span>
      <template v-else>{{ part.value }}</template>
    </template>
  </span>
</template>

<style lang="scss" scoped>
@import "index";
</style>
