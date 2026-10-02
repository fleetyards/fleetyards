<script lang="ts">
export default {
  name: "LocationName",
};
</script>

<script lang="ts" setup>
type Props = {
  // The text the record keeps.
  text?: string | null;
  // The place it is linked to, where it names one of ours.
  linked?: { slug: string; name?: string | null } | null;
};

defineProps<Props>();
</script>

<!-- A place a record names: a link to its page where it is one of ours, its
     text where it is not. -->
<template>
  <router-link
    v-if="linked"
    :to="{ name: 'location', params: { slug: linked.slug } }"
    class="location-name"
    data-test="location-name"
  >
    {{ text || linked.name }}
  </router-link>
  <span v-else-if="text" class="location-name">{{ text }}</span>
</template>
