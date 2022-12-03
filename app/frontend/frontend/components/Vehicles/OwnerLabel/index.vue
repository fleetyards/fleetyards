<template>
  <div class="owner">
    <template v-if="modelSlug">
      <Btn
        variant="link"
        :text-inline="true"
        class="owner-more-action"
        @click.native="openOwnersModal"
      >
        {{ $t("labels.vehicle.owner") }} <i class="fa fa-bars-staggered" />
      </Btn>
    </template>
    <template v-else-if="owner">
      {{ $t("labels.vehicle.owner") }}
      <Btn :href="`/hangar/${owner}`" variant="link" :text-inline="true">
        {{ owner }}
      </Btn>
    </template>
  </div>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Prop } from "vue-property-decorator";
import Btn from "@/frontend/core/components/Btn/index.vue";

@Component<ModelPanel>({
  components: {
    Btn,
  },
})
export default class ModelPanel extends Vue {
  @Prop({ required: true }) fleetSlug: string;

  @Prop({ default: null }) owner: string | null;

  @Prop({ default: null }) modelSlug: string | null;

  openOwnersModal() {
    this.$comlink.$emit("open-modal", {
      component: () =>
        import("@/frontend/components/Vehicles/OwnersModal/index.vue"),
      props: {
        fleetSlug: this.fleetSlug,
        modelSlug: this.modelSlug,
      },
    });
  }
}
</script>
