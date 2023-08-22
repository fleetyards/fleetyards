<template>
  <BtnDropdown
    :size="size"
    :variant="variant"
    class="panel-edit-menu"
    data-test="vehicle-menu"
    :expand-left="true"
    :inline="true"
  >
    <Btn
      v-if="editable && !hideEdit"
      :aria-label="$t('actions.edit')"
      size="small"
      variant="dropdown"
      data-test="vehicle-edit"
      @click.native="openEditModal"
    >
      <i class="fa fa-pencil" />
      <span>{{ $t("actions.edit") }}</span>
    </Btn>
    <Btn
      v-if="vehicle.model"
      :to="{
        name: 'model',
        params: {
          slug: vehicle.model.slug,
        },
      }"
      size="small"
      variant="dropdown"
    >
      <i class="fad fa-starship" />
      <span>{{ $t("actions.showDetailPage") }}</span>
    </Btn>
    <Btn
      v-if="editable && !wishlist"
      :aria-label="$t('actions.addToWishlist')"
      size="small"
      variant="dropdown"
      :disabled="updating"
      data-test="vehicle-add-to-wishlist"
      @click.native="addToWishlist"
    >
      <i class="fad fa-wand-sparkles" />
      <span>{{ $t("actions.addToWishlist") }}</span>
    </Btn>
    <Btn
      v-if="editable && wishlist"
      :aria-label="$t('actions.addToHangar')"
      size="small"
      variant="dropdown"
      :disabled="updating"
      data-test="vehicle-add-to-hangar"
      @click.native="addToHangar"
    >
      <i class="fad fa-garage" />
      <span>{{ $t("actions.addToHangar") }}</span>
    </Btn>
    <Btn
      v-if="editable"
      :aria-label="$t('actions.hangar.editName')"
      size="small"
      variant="dropdown"
      data-test="vehicle-edit-name"
      @click.native="openNamingModal"
    >
      <i class="fa fa-signature" />
      <span>{{ $t("actions.hangar.editName") }}</span>
    </Btn>
    <Btn
      v-if="editable && !wishlist"
      :aria-label="$t('actions.hangar.editGroups')"
      size="small"
      variant="dropdown"
      data-test="vehicle-edit-groups"
      @click.native="openEditGroupsModal"
    >
      <i class="fad fa-object-group" />
      <span>{{ $t("actions.hangar.editGroups") }}</span>
    </Btn>
    <Btn
      v-if="upgradable"
      :aria-label="$t('labels.model.addons')"
      size="small"
      variant="dropdown"
      @click.native="openAddonsModal"
    >
      <i class="fa fa-plus-octagon" />
      <span>{{ $t("labels.model.addons") }}</span>
    </Btn>
    <Btn
      v-if="editable"
      :aria-label="$t('actions.remove')"
      size="small"
      variant="dropdown"
      :disabled="deleting"
      data-test="vehicle-remove"
      @click.native="remove"
    >
      <i class="fal fa-trash" />
      <span>{{ $t("actions.remove") }}</span>
    </Btn>
  </BtnDropdown>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Prop } from "vue-property-decorator";
import Btn from "@/frontend/core/components/Btn/index.vue";
import BtnDropdown from "@/frontend/core/components/BtnDropdown/index.vue";
import { displayConfirm } from "@/frontend/lib/Noty";
import vehiclesCollection from "@/frontend/api/collections/Vehicles";
import wishlistCollection from "@/frontend/api/collections/Wishlist";

@Component<ContextMenu>({
  components: {
    Btn,
    BtnDropdown,
  },
})
export default class ContextMenu extends Vue {
  deleting = false;

  updating = false;

  @Prop({ default: null }) vehicle!: Vehicle | null;

  @Prop({ default: false }) editable!: boolean;

  @Prop({ default: false }) hideEdit!: boolean;

  @Prop({ default: false }) wishlist!: boolean;

  @Prop({
    default: "link",
    validator(value: string) {
      return (
        ["default", "transparent", "link", "danger", "dropdown"].indexOf(
          value,
        ) !== -1
      );
    },
  })
  variant!: string;

  @Prop({
    default: "small",
    validator(value: string) {
      return ["default", "small", "large"].indexOf(value) !== -1;
    },
  })
  size!: string;

  get hasAddons() {
    if (!this.vehicle) {
      return false;
    }

    return (
      this.vehicle.modelModuleIds.length || this.vehicle.modelUpgradeIds.length
    );
  }

  get upgradable() {
    if (!this.vehicle) {
      return false;
    }

    return (
      (this.editable || this.hasAddons) &&
      (this.vehicle.model.hasModules || this.vehicle.model.hasUpgrades)
    );
  }

  async addToWishlist() {
    if (!this.vehicle) {
      return;
    }

    this.updating = true;

    await vehiclesCollection.addToWishlist(this.vehicle.id);

    this.updating = false;
  }

  async addToHangar() {
    if (!this.vehicle) {
      return;
    }

    this.updating = true;

    await wishlistCollection.addToHangar(this.vehicle.id);

    this.updating = false;
  }

  remove() {
    this.deleting = true;
    displayConfirm({
      text: this.$t("messages.confirm.vehicle.destroy"),
      onConfirm: () => {
        this.destroy();
      },
      onClose: () => {
        this.deleting = false;
      },
    });
  }

  async destroy() {
    if (!this.vehicle) {
      return;
    }

    await vehiclesCollection.destroy(this.vehicle.id);

    this.deleting = false;
  }

  openEditModal() {
    this.$comlink.$emit("open-modal", {
      component: () => import("@/frontend/components/Vehicles/Modal/index.vue"),
      props: {
        vehicle: this.vehicle,
        wishlist: this.wishlist,
      },
    });
  }

  openNamingModal() {
    this.$comlink.$emit("open-modal", {
      component: () =>
        import("@/frontend/components/Vehicles/NamingModal/index.vue"),
      props: {
        vehicle: this.vehicle,
      },
    });
  }

  openEditGroupsModal() {
    this.$comlink.$emit("open-modal", {
      component: () =>
        import("@/frontend/components/Vehicles/GroupsModal/index.vue"),
      props: {
        vehicle: this.vehicle,
      },
    });
  }

  openAddonsModal() {
    this.$comlink.$emit("open-modal", {
      component: () =>
        import("@/frontend/components/Vehicles/AddonsModal/index.vue"),
      props: {
        vehicle: this.vehicle,
        editable: this.editable,
      },
    });
  }
}
</script>
