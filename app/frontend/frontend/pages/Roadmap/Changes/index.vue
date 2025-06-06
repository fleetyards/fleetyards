<template>
  <section class="container roadmap">
    <div class="row">
      <div class="col-12">
        <BreadCrumbs :crumbs="crumbs" />
        <h1 class="sr-only">
          {{ $t("headlines.roadmap") }}
        </h1>
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-lg-6">
        <FilterGroup
          v-model="selectedWeek"
          :label="$t('labels.roadmap.selectWeek')"
          name="query"
          :options="options"
          label-attr="label"
          :nullable="false"
          :no-label="true"
          @input="fetch"
        />
      </div>
      <div class="col-12 col-lg-6">
        <div class="page-actions page-actions-right">
          <Btn href="https://robertsspaceindustries.com/roadmap">
            {{ $t("labels.rsiRoadmap") }}
          </Btn>
        </div>
      </div>
    </div>
    <hr class="dark" />
    <div class="row">
      <div class="col-12">
        <transition-group name="fade-list" class="row" tag="div" appear>
          <div
            v-for="(items, release) in groupedByRelease"
            :key="`releases-${release}`"
            class="col-12 fade-list-item release"
          >
            <h2>
              <span class="title">{{ release }}</span>
              <span v-if="items[0].releaseDescription" class="released-label">
                ({{ items[0].releaseDescription }})
              </span>
              <small class="text-muted">
                {{ $t("labels.roadmap.stories", { count: items.length }) }}
              </small>
            </h2>

            <div class="row">
              <div
                v-for="item in items"
                :key="item.id"
                class="col-12 col-lg-6 col-xl-4 col-xxl-2dot4 fade-list-item"
              >
                <RoadmapItem :item="item" :compact="false" />
              </div>
            </div>
          </div>
        </transition-group>
        <EmptyBox :visible="emptyBoxVisible" />
        <Loader :loading="loading" :fixed="true" />
      </div>
    </div>
  </section>
</template>
<script lang="ts">
import Vue from "vue";
import { Component } from "vue-property-decorator";
import Btn from "@/frontend/core/components/Btn/index.vue";
import Loader from "@/frontend/core/components/Loader/index.vue";
import FilterGroup from "@/frontend/core/components/Form/FilterGroup/index.vue";
import RoadmapItem from "@/frontend/components/Roadmap/RoadmapItem/index.vue";
import EmptyBox from "@/frontend/core/components/EmptyBox/index.vue";
import BreadCrumbs from "@/frontend/core/components/BreadCrumbs/index.vue";

@Component<RoadmapChanges>({
  components: {
    Btn,
    Loader,
    FilterGroup,
    EmptyBox,
    RoadmapItem,
    BreadCrumbs,
  },
})
export default class RoadmapChanges extends Vue {
  loading = true;

  compact = false;

  roadmapChanges = [];

  options = [];

  roadmapChannel = null;

  selectedWeek = 0;

  get toggleCompactTooltip() {
    if (this.compact) {
      return this.$t("actions.showDetails");
    }

    return this.$t("actions.hideDetails");
  }

  get emptyBoxVisible() {
    return !this.loading && this.roadmapChanges.length === 0;
  }

  get query() {
    if (!this.options.length) {
      return null;
    }

    return this.options[this.selectedWeek].query;
  }

  get groupedByRelease() {
    return this.roadmapChanges.reduce((rv, x) => {
      const value = JSON.parse(JSON.stringify(rv));

      value[x.release] = rv[x.release] || [];
      value[x.release].push(x);

      return value;
    }, {});
  }

  get crumbs() {
    return [
      {
        to: {
          name: "roadmap",
        },
        label: this.$t("nav.roadmap.index"),
      },
    ];
  }

  async mounted() {
    await this.fetchOptions();
    this.fetch();
    this.setupUpdates();
  }

  beforeDestroy() {
    if (this.roadmapChannel) {
      this.roadmapChannel.unsubscribe();
    }
  }

  setupUpdates() {
    if (this.roadmapChannel) {
      this.roadmapChannel.unsubscribe();
    }

    this.roadmapChannel = this.$cable.consumer.subscriptions.create(
      {
        channel: "RoadmapChannel",
      },
      {
        received: this.fetch,
      },
    );
  }

  toggleCompact() {
    this.compact = !this.compact;
  }

  async fetchOptions() {
    const response = await this.$api.get("roadmap/weeks");

    if (!response.error) {
      this.options = response.data;
    }
  }

  async fetch() {
    if (!this.query) {
      return;
    }

    this.loading = true;
    const response = await this.$api.get("roadmap?changes=1", {
      q: this.query,
    });

    this.loading = false;

    if (!response.error) {
      this.roadmapChanges = response.data.filter((item) => item.lastVersion);
    }
  }
}
</script>
