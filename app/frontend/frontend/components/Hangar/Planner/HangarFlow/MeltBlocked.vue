<script lang="ts">
export default {
  name: "HangarPlannerHangarFlowMeltBlocked",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();
</script>

<template>
  <button
    type="button"
    class="melt-blocked"
    disabled
    data-test="hangar-plan-decide-melt"
  >
    <i class="fa-light fa-ban" aria-hidden="true" />
    {{ t("hangarPlanner.pick.notMeltable") }}
  </button>
</template>

<style lang="scss" scoped>
.melt-blocked {
  display: inline-flex;
  gap: 4px;
  align-items: center;
  padding: 3px 6px;
  border: 0;
  background: transparent;
  font: inherit;
  font-size: 0.75rem;
  color: var(--color-text-dim);
  cursor: not-allowed;
}
</style>
