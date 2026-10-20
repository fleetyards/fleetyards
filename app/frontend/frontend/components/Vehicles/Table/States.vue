<script lang="ts">
export default {
  name: "VehiclesTableStates",
};
</script>

<script lang="ts" setup>
import { type Vehicle } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  vehicle: Vehicle;
  wishlist?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  wishlist: false,
});

const { t } = useI18n();

const visibility = computed(() => {
  if (props.vehicle.hiddenByUser) {
    return {
      icon: "fa-duotone fa-ghost",
      label: t("labels.vehicle.hiddenByUser"),
    };
  }

  if (props.vehicle.public && props.vehicle.nameVisible) {
    return {
      icon: "fa-duotone fa-eye-evil vehicle-state-full-public",
      label: t("labels.vehicle.fullPublic"),
    };
  }

  if (props.vehicle.public) {
    return { icon: "fa-duotone fa-eye", label: t("labels.vehicle.public") };
  }

  return {
    icon: "fa-duotone fa-lock vehicle-state-private",
    label: t("labels.vehicle.private"),
  };
});
</script>

<template>
  <!-- Every slot keeps its place when empty, so a state sits in the same
       column on every row. -->
  <div class="vehicle-states">
    <span class="vehicle-state" data-test="vehicle-state-on-sale">
      <i
        v-if="vehicle.model.onSale"
        v-tooltip="t('labels.model.onSale')"
        class="fa-duotone fa-dollar-sign vehicle-state-on-sale"
      />
    </span>
    <span class="vehicle-state" data-test="vehicle-state-visibility">
      <i v-tooltip="visibility.label" :class="visibility.icon" />
    </span>
    <span
      v-if="wishlist"
      class="vehicle-state"
      data-test="vehicle-state-sale-notify"
    >
      <i
        v-if="vehicle.saleNotify"
        v-tooltip="t('labels.vehicle.saleNotify')"
        class="fa-duotone fa-bell"
      />
    </span>
  </div>
</template>

<style lang="scss" scoped>
.vehicle-states {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 16px;
}

.vehicle-state {
  width: 22px;
  display: inline-flex;
  justify-content: center;
}

.vehicle-state-on-sale {
  color: $success;
}

.vehicle-state-full-public {
  color: $gray-lighter;
}

.vehicle-state-private {
  color: var(--color-muted, #7a8288);
}
</style>
