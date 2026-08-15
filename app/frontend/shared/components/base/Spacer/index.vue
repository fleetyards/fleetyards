<script lang="ts">
export default {
  name: "BaseSpacer",
};
</script>

<script lang="ts" setup>
type Props = {
  large?: boolean;
  slim?: boolean;
  mb?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  large: false,
  slim: false,
  mb: false,
});

/*
 * The classes the global `hr` rule already defines. This component used to carry
 * a stylesheet restating that rule - and emitted `spacer-large` against a
 * `.spacer--large` selector, so every modifier on it had been dead: large, slim
 * and mb all rendered as the plain rule.
 */
const cssClasses = computed(() => ({
  "large-spacer": props.large,
  "slim-spacer": props.slim,
  "space-bottom": props.mb,
}));
</script>

<template>
  <hr :class="cssClasses" />
</template>
