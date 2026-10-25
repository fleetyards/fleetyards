<script lang="ts">
export default {
  name: "FleetContractsScopeLabel",
};
</script>

<script lang="ts" setup>
import AppIcon from "@/shared/components/AppIcon/index.vue";
import { FLEET_GLYPH } from "@/shared/glyphs/fleets";
import { type Fleet } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  fleet: Fleet;
  personal: boolean;
};

defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <span
    v-if="personal"
    class="contract-scope-label"
    data-test="contract-personal"
  >
    <i class="fa-light fa-user" />
    {{ t("labels.fleets.contracts.personalBadge") }}
  </span>
  <span v-else class="contract-scope-label" data-test="contract-fleet">
    <img
      v-if="fleet.logo?.smallUrl"
      :src="fleet.logo.smallUrl"
      alt=""
      class="contract-scope-label__logo"
    />
    <AppIcon v-else :icon="FLEET_GLYPH" />
    {{ fleet.name }}
  </span>
</template>

<style lang="scss" scoped>
.contract-scope-label {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;

  &__logo {
    flex: none;
    width: 14px;
    height: 14px;
    border-radius: 50%;
    object-fit: cover;
  }
}
</style>
