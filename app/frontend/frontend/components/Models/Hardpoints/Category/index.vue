<script lang="ts">
export default {
  name: "HardpointCategory",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { HardpointCategoryEnum } from "@/services/fyAdminApi";
import { type Hardpoint } from "@/services/fyApi";
import HardpointItems from "@/frontend/components/Models/Hardpoints/Items/index.vue";
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
import vtolThrustersIconUrl from "@/images/hardpoints/vtol_thrusters.svg";
import retroThrustersIconUrl from "@/images/hardpoints/retro_thrusters.svg";
import maneuveringThrustersIconUrl from "@/images/hardpoints/maneuvering_thrusters.svg";
import weaponsIconUrl from "@/images/hardpoints/weapons.svg";
import turretsIconUrl from "@/images/hardpoints/turrets.svg";
import missilesIconUrl from "@/images/hardpoints/missiles.svg";
import utilityItemsIconUrl from "@/images/hardpoints/utility_items.svg";
import qedIconUrl from "@/images/hardpoints/qed.svg";
import empIconUrl from "@/images/hardpoints/emp.svg";

type Props = {
  hardpoints: Hardpoint[];
  category: HardpointCategoryEnum;
};

defineProps<Props>();

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
  jumpdrive: jumpModulesIconUrl,
  quantum_fuel_tanks: quantumFuelTanksIconUrl,
  main_thrusters: mainThrustersIconUrl,
  vtol_thrusters: vtolThrustersIconUrl,
  retro_thrusters: retroThrustersIconUrl,
  maneuvering_thrusters: maneuveringThrustersIconUrl,
  weapons: weaponsIconUrl,
  weapon_mounts: weaponsIconUrl,
  turret: turretsIconUrl,
  missiles: missilesIconUrl,
  missile_racks: missilesIconUrl,
  utility: utilityItemsIconUrl,
  utility_items: utilityItemsIconUrl,
  quantumenforcementdevice: qedIconUrl,
  emp: empIconUrl,
};
</script>

<template>
  <div class="hardpoint-category">
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
      <span
        v-else-if="category === HardpointCategoryEnum.MODULE"
        class="hardpoint-category__icon"
      >
        <i class="fad fa-puzzle fa-lg" />
      </span>
      <span
        v-else-if="category === HardpointCategoryEnum.SALVAGEFILLERSTATION"
        class="hardpoint-category__icon"
      >
        <i class="fad fa-bin-recycle fa-lg" />
      </span>
      <span
        v-else-if="category === HardpointCategoryEnum.ARMOR"
        class="hardpoint-category__icon"
      >
        <i class="fad fa-shield-halved fa-lg" />
      </span>
      <span
        v-else-if="category === HardpointCategoryEnum.COUNTERMEASURES"
        class="hardpoint-category__icon"
      >
        <i class="fad fa-shield-quartered fa-lg" />
      </span>
      <span
        v-else-if="category === HardpointCategoryEnum.LIFESUPPORT"
        class="hardpoint-category__icon"
      >
        <i class="fad fa-star-of-life fa-lg" />
      </span>
      <span
        v-else-if="category === HardpointCategoryEnum.RELAY"
        class="hardpoint-category__icon"
      >
        <i class="fad fa-transformer-bolt fa-lg" />
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
      :hardpoints="hardpoints"
      :category="category as HardpointCategoryEnum"
    />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
