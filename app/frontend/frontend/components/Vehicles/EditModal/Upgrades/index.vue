<script lang="ts">
export default {
  name: "VehicleEditModalUpgrades",
};
</script>

<script lang="ts" setup>
import { useField } from "vee-validate";
import AsyncData from "@/shared/components/AsyncData.vue";
import Addons from "../Addons/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Vehicle,
  useModelUpgrades as useModelUpgradesQuery,
} from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { value: modelUpgradeIds } = useField<string[]>("modelUpgradeIds");

const { data: upgradesData, ...upgradesAsyncStatus } = useModelUpgradesQuery(
  computed(() => props.vehicle.model?.slug ?? ""),
);

// Upgrades come back as a bare array, where modules and packages are paginated.
const upgrades = computed(() => upgradesData.value ?? []);
</script>

<template>
  <AsyncData :async-status="upgradesAsyncStatus">
    <template #resolved>
      <Addons
        v-model="modelUpgradeIds"
        :addons="upgrades"
        editable
        :empty-label="t('addon.empty.upgrades')"
      />
    </template>
  </AsyncData>
</template>
