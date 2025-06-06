<template>
  <div id="hardpoints">
    <div v-if="erkulUrl" class="d-flex justify-content-center">
      <BtnGroup>
        <span v-if="!mobile" class="text-muted">{{
          $t("labels.hardpointTools.prefix")
        }}</span>
        <Btn
          :href="erkulUrl"
          variant="dropdown"
          :mobile-block="true"
          class="erkul-link"
        >
          <i />
          {{ $t("labels.hardpointTools.erkul") }}
        </Btn>
        <Btn
          :href="spviewerUrl"
          variant="dropdown"
          :mobile-block="true"
          class="spviewer-link"
        >
          <i />
          {{ $t("labels.hardpointTools.spviewer") }}
        </Btn>
      </BtnGroup>
    </div>
    <div class="row">
      <div class="col-12 col-md-6 col-lg-4">
        <HardpointGroup
          v-for="group in ['avionic', 'system']"
          :key="group"
          :group="group"
          :hardpoints="hardpointsForGroup(group)"
        />
      </div>
      <div class="col-12 col-md-6 col-lg-4">
        <HardpointGroup
          v-for="group in ['propulsion', 'thruster']"
          :key="group"
          :group="group"
          :hardpoints="hardpointsForGroup(group)"
        />
      </div>
      <div class="col-12 col-md-6 col-lg-4">
        <HardpointGroup
          v-for="group in ['weapon']"
          :key="group"
          :group="group"
          :hardpoints="hardpointsForGroup(group)"
        />
      </div>
    </div>
    <div v-if="scunpackedUrl" class="d-flex justify-content-end">
      <Btn
        :href="scunpackedUrl"
        variant="link"
        :mobile-block="true"
        class="scunpacked-link"
      >
        <small>{{ $t("labels.scunpacked.prefix") }}</small>
        <i>
          {{ $t("labels.scunpacked.link") }}
        </i>
      </Btn>
    </div>
    <Loader :loading="loading" :fixed="true" />
  </div>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Prop, Watch } from "vue-property-decorator";
import Btn from "@/frontend/core/components/Btn/index.vue";
import BtnGroup from "@/frontend/core/components/BtnGroup/index.vue";
import Loader from "@/frontend/core/components/Loader/index.vue";
import modelHardpointsCollection from "@/frontend/api/collections/ModelHardpoints";
import Store from "@/frontend/lib/Store";
import HardpointGroup from "./Group/index.vue";

@Component<Hardpoints>({
  components: {
    HardpointGroup,
    Loader,
    Btn,
    BtnGroup,
  },
})
export default class Hardpoints extends Vue {
  @Prop({ required: true }) model!: Model;

  collection: ModelHardpointsCollection = modelHardpointsCollection;

  loading = false;

  mobile = computed(() => Store.getters.mobile);

  get hardpoints() {
    return this.collection.records || [];
  }

  get erkulUrl(): string | null {
    if (
      !this.model ||
      this.model.productionStatus !== "flight-ready" ||
      !this.model.erkulIdentifier
    ) {
      return null;
    }

    return `https://www.erkul.games/ship/${this.model.erkulIdentifier}`;
  }

  get spviewerUrl(): string | null {
    if (
      !this.model ||
      this.model.productionStatus !== "flight-ready" ||
      !this.model.scIdentifier
    ) {
      return null;
    }

    return `https://www.spviewer.eu/performance?ship=${this.model.scIdentifier}`;
  }

  get scunpackedUrl(): string | null {
    if (!this.model.scIdentifier) {
      return null;
    }

    return `https://scunpacked.com/ships/${this.model.scIdentifier}`;
  }

  hardpointsForGroup(group) {
    return this.hardpoints.filter((hardpoint) => hardpoint.group === group);
  }

  @Watch("model")
  onModelChange() {
    this.fetch();
  }

  mounted() {
    this.fetch();
  }

  async fetch() {
    if (!this.model) {
      return;
    }

    this.loading = true;

    await this.collection.findAllByModel(this.model.slug);

    this.loading = false;
  }
}
</script>
