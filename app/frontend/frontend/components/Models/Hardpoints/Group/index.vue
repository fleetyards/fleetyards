<script lang="ts">
export default {
  name: "HardpointGroup",
};
</script>

<script lang="ts" setup>
import { groupBy, sortBy } from "@/shared/utils/Array";
import radarIconUrl from "@/images/hardpoints/radar.svg";
import computersIconUrl from "@/images/hardpoints/computers.svg";
import powerPlantsIconUrl from "@/images/hardpoints/power_plants.svg";
import coolersIconUrl from "@/images/hardpoints/coolers.svg";
import shieldGeneratorsIconUrl from "@/images/hardpoints/shield_generators.svg";
import fuelIntakesIconUrl from "@/images/hardpoints/fuel_intakes.svg";
import fuelTanksIconUrl from "@/images/hardpoints/fuel_tanks.svg";
import quantumDrivesIconUrl from "@/images/hardpoints/quantum_drives.svg";
import jumpModulesIconUrl from "@/images/hardpoints/jump_modules.svg";
import quantumFuelTanksIconUrl from "@/images/hardpoints/quantum_fuel_tanks.svg";
import mainThrustersIconUrl from "@/images/hardpoints/main_thrusters.svg";
import maneuveringThrustersIconUrl from "@/images/hardpoints/maneuvering_thrusters.svg";
import weaponsIconUrl from "@/images/hardpoints/weapons.svg";
import turretsIconUrl from "@/images/hardpoints/turrets.svg";
import missilesIconUrl from "@/images/hardpoints/missiles.svg";
import utilityItemsIconUrl from "@/images/hardpoints/utility_items.svg";
import qedIconUrl from "@/images/hardpoints/qed.svg";
import empIconUrl from "@/images/hardpoints/emp.svg";
import Panel from "@/shared/components/Panel/index.vue";
import {
  type Model,
  type Hardpoint,
  type HardpointGroupEnum,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import HardpointItems from "@/frontend/components/Models/Hardpoints/Items/index.vue";
import { HardpointCategoryEnum } from "@/services/fyAdminApi";

type Props = {
  model: Model;
  group: HardpointGroupEnum;
  hardpoints: Hardpoint[];
  withoutTitle?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withoutTitle: false,
});

const { t } = useI18n();

const icons = {
  radar: radarIconUrl,
  computers: computersIconUrl,
  powerplant: powerPlantsIconUrl,
  cooler: coolersIconUrl,
  shieldgenerator: shieldGeneratorsIconUrl,
  fuel_intakes: fuelIntakesIconUrl,
  fueltanks: fuelTanksIconUrl,
  quantumdrive: quantumDrivesIconUrl,
  jump_modules: jumpModulesIconUrl,
  quantum_fuel_tanks: quantumFuelTanksIconUrl,
  main_thrusters: mainThrustersIconUrl,
  maneuvering_thrusters: maneuveringThrustersIconUrl,
  weapons: weaponsIconUrl,
  weapon_mounts: weaponsIconUrl,
  turret: turretsIconUrl,
  missiles: missilesIconUrl,
  missile_racks: missilesIconUrl,
  utility_items: utilityItemsIconUrl,
  quantumenforcementdevice: qedIconUrl,
  emp: empIconUrl,
};

const categories = computed(() => {
  const items = groupByCategory(props.hardpoints);

  const availableCategories: Record<string, Hardpoint[]> = {};

  Object.keys(items).forEach((category) => {
    if (
      [
        HardpointCategoryEnum.CONTROLLER,
        HardpointCategoryEnum.UNKNOWN,
      ].includes(category as HardpointCategoryEnum)
    ) {
      return;
    }

    availableCategories[category as HardpointCategoryEnum] = items[category];
  });

  return availableCategories;
});

const groupByCategory = (items: Hardpoint[]) => {
  return groupBy<Hardpoint>(sortBy<Hardpoint>(items, "category"), "category");
};
</script>

<template>
  <div v-if="hardpoints.length" class="hardpoint-group">
    <h2 v-if="!withoutTitle" class="hardpoint-group-label">
      {{ t(`labels.hardpoint.groups.${group.toLowerCase()}`) }}
    </h2>
    <Panel slim>
      <div class="hardpoint-group__inner">
        <div
          v-for="(items, category) in categories"
          :key="category"
          class="hardpoint-category"
        >
          <div class="hardpoint-category__label">
            <span
              v-if="category === HardpointCategoryEnum.CARGOGRID"
              class="hardpoint-category__icon"
            >
              <i class="fad fa-boxes fa-lg" />
            </span>
            <span
              v-else-if="category === HardpointCategoryEnum.SEAT"
              class="hardpoint-category__icon"
            >
              <i class="fad fa-person-seat-reclined fa-lg" />
            </span>
            <img
              v-else
              :src="icons[category as keyof typeof icons]"
              class="hardpoint-category__icon"
              :alt="`icon-${category}`"
            />
            {{ t(`labels.hardpoint.categories.${category}`) }}
          </div>
          <HardpointItems
            :hardpoints="items"
            :category="category as HardpointCategoryEnum"
          />
        </div>
      </div>
    </Panel>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
