<template>
  <div v-if="hardpoints.length" class="hardpoint-group">
    <h2 v-if="!withoutTitle" class="hardpoint-group-label">
      {{ $t(`labels.hardpoint.groups.${group.toLowerCase()}`) }}
    </h2>
    <Panel>
      <div class="hardpoint-group-inner">
        <div
          v-for="(items, type) in groupByType(hardpoints)"
          :key="type"
          class="hardpoint-type"
        >
          <div class="hardpoint-type-label">
            <img
              :src="icons[type]"
              class="hardpoint-type-icon"
              :alt="`icon-${type}`"
            />
            {{ $t(`labels.hardpoint.types.${type}`) }}
          </div>
          <div class="hardpoint-items">
            <HardpointItems
              v-for="(groupedItems, key) in groupByKey(items)"
              :key="`${type}-${key}`"
              :hardpoints="groupedItems"
            />
          </div>
        </div>
      </div>
    </Panel>
  </div>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Prop } from "vue-property-decorator";
import { groupBy, sortBy } from "@/frontend/lib/Helpers";
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
import HardpointItems from "../Items/index.vue";

@Component<HardpointGroup>({
  components: {
    HardpointItems,
    Panel,
  },
})
export default class HardpointGroup extends Vue {
  @Prop({ required: true }) group: HardpointGroup;

  @Prop({ required: true }) hardpoints: ModelHardpoint[];

  @Prop({ default: false }) withoutTitle: boolean;

  icons = {
    radar: radarIconUrl,
    computers: computersIconUrl,
    power_plants: powerPlantsIconUrl,
    coolers: coolersIconUrl,
    shield_generators: shieldGeneratorsIconUrl,
    fuel_intakes: fuelIntakesIconUrl,
    fuel_tanks: fuelTanksIconUrl,
    quantum_drives: quantumDrivesIconUrl,
    jump_modules: jumpModulesIconUrl,
    quantum_fuel_tanks: quantumFuelTanksIconUrl,
    main_thrusters: mainThrustersIconUrl,
    maneuvering_thrusters: maneuveringThrustersIconUrl,
    weapons: weaponsIconUrl,
    turrets: turretsIconUrl,
    missiles: missilesIconUrl,
    utility_items: utilityItemsIconUrl,
    qed: qedIconUrl,
    emp: empIconUrl,
  };

  grouped(type) {
    return ["main_thrusters", "maneuvering_thrusters"].includes(type);
  }

  groupByType(hardpoints) {
    return groupBy(sortBy(hardpoints, "type"), "type");
  }

  groupByKey(hardpoints) {
    return groupBy(sortBy(hardpoints, "category"), "key");
  }

  openComponentModal(hardpoint) {
    if (!hardpoint.component) {
      return;
    }

    this.$comlink.$emit("open-modal", {
      component: () =>
        import(
          "@/frontend/components/Models/Hardpoints/ComponentModal/index.vue"
        ),
      props: {
        hardpoint,
      },
    });
  }
}
</script>
