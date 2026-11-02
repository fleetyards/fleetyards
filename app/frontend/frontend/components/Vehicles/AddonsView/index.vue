<script lang="ts">
export default {
  name: "VehicleAddonsView",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import Addons from "@/frontend/components/Vehicles/EditModal/Addons/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Vehicle,
  type VehiclePublic,
  useModelModules as useModelModulesQuery,
  useModelUpgrades as useModelUpgradesQuery,
} from "@/services/fyApi";

type Props = {
  vehicle: Vehicle | VehiclePublic;
};

const props = defineProps<Props>();

const { t } = useI18n();

const modelSlug = computed(() => props.vehicle.model?.slug ?? "");

const hasModules = computed(() => !!props.vehicle.model?.hasModules);
const hasUpgrades = computed(() => !!props.vehicle.model?.hasUpgrades);

const { data: modulesData, ...modulesAsyncStatus } = useModelModulesQuery(
  modelSlug,
  undefined,
  { query: { enabled: hasModules } },
);

const { data: upgradesData, ...upgradesAsyncStatus } = useModelUpgradesQuery(
  modelSlug,
  { query: { enabled: hasUpgrades } },
);

const modules = computed(() => modulesData.value?.items ?? []);
const upgrades = computed(() => upgradesData.value ?? []);

const eyebrow = computed(() =>
  [props.vehicle.model?.name, props.vehicle.name].filter(Boolean).join(" · "),
);
</script>

<template>
  <Modal :title="t('labels.model.addons')" :eyebrow="eyebrow">
    <div class="vehicle-addons-view" data-test="vehicle-addons-view">
      <section v-if="hasModules">
        <h3>{{ t("labels.model.modules") }}</h3>
        <AsyncData :async-status="modulesAsyncStatus">
          <template #resolved>
            <Addons
              :model-value="vehicle.modelModuleIds"
              :addons="modules"
              :empty-label="t('addon.empty.modules')"
            />
          </template>
        </AsyncData>
      </section>

      <section v-if="hasUpgrades">
        <h3>{{ t("labels.model.upgrades") }}</h3>
        <AsyncData :async-status="upgradesAsyncStatus">
          <template #resolved>
            <Addons
              :model-value="vehicle.modelUpgradeIds"
              :addons="upgrades"
              :empty-label="t('addon.empty.upgrades')"
            />
          </template>
        </AsyncData>
      </section>
    </div>
  </Modal>
</template>

<style lang="scss" scoped>
.vehicle-addons-view {
  display: flex;
  flex-direction: column;
  gap: 24px;

  h3 {
    margin-bottom: 10px;
  }
}
</style>
