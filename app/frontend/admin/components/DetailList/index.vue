<script lang="ts">
export default {
  name: "AdminDetailList",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import { type Detail } from "@/admin/components/DetailList/types";

type Props = {
  details: Detail[];
};

const props = defineProps<Props>();

const display = (value: Detail["value"]) =>
  value === null || value === undefined || value === "" ? "—" : String(value);
</script>

<template>
  <Panel inset :outer-spacing="false">
    <dl class="detail-list">
      <template v-for="detail in props.details" :key="detail.label">
        <dt>{{ detail.label }}</dt>
        <dd>{{ display(detail.value) }}</dd>
      </template>
    </dl>
  </Panel>
</template>

<style scoped>
@reference "../../../entrypoints/tailwind.css";

/*
 * Two columns on anything but a phone, where a label above its value reads
 * better than a label squeezed into a third of the width.
 */
.detail-list {
  @apply grid gap-x-6 gap-y-2 pb-5;
  grid-template-columns: 1fr;
}

@media (min-width: 768px) {
  .detail-list {
    grid-template-columns: max-content 1fr;
  }
}

.detail-list dt {
  @apply text-sm text-muted;
}

.detail-list dd {
  @apply m-0 text-white;
}
</style>
