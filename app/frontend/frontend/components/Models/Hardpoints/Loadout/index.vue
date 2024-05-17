<template>
  <div v-if="loadout" class="hardpoint-item-loadout">
    <div class="hardpoint-item-loadout-quantity">
      <img
        :src="loadoutListIcon"
        class="hardpoint-item-loadout-quantity-icon"
        alt="hardpoint-list-icon"
      />
      {{ loadoutsCount }}
      <span class="text-muted">x</span>
    </div>
    <div
      class="hardpoint-item-inner"
      :class="{ 'has-component': loadout.component }"
    >
      <div
        v-if="loadout.name === 'hardpoint_Jump_Drive'"
        class="hardpoint-item-size"
      >
        {{ $t("labels.hardpoint.size") }} {{ hardpoint.sizeLabel }}
      </div>
      <div v-else-if="showComponent" class="hardpoint-item-size">
        {{ $t("labels.hardpoint.size") }} {{ loadout.component?.size }}
      </div>
      <div class="hardpoint-item-component">
        <template v-if="loadout.name === 'hardpoint_Jump_Drive'">
          {{ $t("labels.hardpoint.jumpDrive") }}
        </template>
        <template v-else-if="showComponent">
          {{ loadout.component?.name }}
        </template>
        <template v-else>TBD</template>
      </div>
      <div
        v-if="loadout && loadout.component && loadout.component.manufacturer"
        class="hardpoint-item-component-manufacturer"
        v-html="loadout.component.manufacturer.name"
      />
    </div>
  </div>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Prop } from "vue-property-decorator";
import loadoutListIconUrl from "@/images/icons/loadout-list-icon.svg";

@Component<HardpointItem>({})
export default class HardpointItem extends Vue {
  @Prop({ required: true }) hardpoint: Hardpoint;

  loadoutListIcon = loadoutListIconUrl;

  get showComponent() {
    return this.loadout.component;
  }

  get loadoutsCount() {
    return this.hardpoint.loadouts.length;
  }

  get loadout() {
    if (!this.hardpoint.loadouts.length) {
      return null;
    }

    return this.hardpoint.loadouts[0];
  }
}
</script>
