<template>
  <section v-if="fleet" class="container">
    <div class="row">
      <div class="col-12">
        <BreadCrumbs :crumbs="crumbs" />
      </div>
      <div class="col-8">
        <h1>
          {{ $t("headlines.fleets.members") }}
          <small v-if="collection.stats" class="text-muted">
            {{
              $t("labels.fleet.members.total", {
                count: collection.stats.total,
              })
            }}
          </small>
        </h1>
      </div>
      <div class="col-4">
        <div v-if="!mobile" class="page-main-actions">
          <Btn
            v-if="canInvite"
            :inline="true"
            @click.native="openInviteUrlModal"
          >
            <i class="fal fa-plus" />
            {{ $t("actions.fleet.createInviteUrl") }}
          </Btn>
          <Btn v-if="canInvite" :inline="true" @click.native="openInviteModal">
            <i class="fad fa-user-plus" />
            {{ $t("actions.fleet.inviteMember") }}
          </Btn>
        </div>
      </div>
    </div>

    <FilteredList
      key="fleet-members"
      :collection="collection"
      :name="$route.name"
      :route-query="$route.query"
      :params="$route.params"
      :hash="$route.hash"
      :paginated="true"
    >
      <template v-if="mobile && canInvite" slot="actions">
        <BtnDropdown size="small">
          <Btn
            size="small"
            variant="dropdown"
            @click.native="openInviteUrlModal"
          >
            <i class="fal fa-plus" />
            <span>{{ $t("actions.fleet.createInviteUrl") }}</span>
          </Btn>
          <Btn size="small" variant="dropdown" @click.native="openInviteModal">
            <i class="fad fa-user-plus" />
            <span>{{ $t("actions.fleet.inviteMember") }}</span>
          </Btn>
        </BtnDropdown>
      </template>

      <FleetMembersFilterForm slot="filter" />

      <template #default="{ records }">
        <FleetMembersList :members="records" :role="fleet.myRole" />
      </template>
    </FilteredList>
  </section>
</template>

<script lang="ts">
import Vue from "vue";
import { Component } from "vue-property-decorator";
import { Getter } from "vuex-class";
import fleetMembersCollection from "@/frontend/api/collections/FleetMembers";
import { fleetRouteGuard } from "@/frontend/utils/RouteGuards/Fleets";
import fleetsCollection from "@/frontend/api/collections/Fleets";
import debounce from "lodash.debounce";
import Panel from "@/frontend/core/components/Panel/index.vue";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import BreadCrumbs from "@/frontend/core/components/BreadCrumbs/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import BtnDropdown from "@/frontend/core/components/BtnDropdown/index.vue";
import FleetMembersFilterForm from "@/frontend/components/Fleets/MembersFilterForm/index.vue";
import Avatar from "@/frontend/core/components/Avatar/index.vue";
import FleetMembersList from "@/frontend/components/Fleets/MembersList/index.vue";

@Component<FleetMembers>({
  components: {
    Btn,
    BtnDropdown,
    BreadCrumbs,
    Panel,
    FilteredList,
    FleetMembersFilterForm,
    Avatar,
    FleetMembersList,
  },
  beforeRouteEnter: fleetRouteGuard,
})
export default class FleetMemmbers extends Vue {
  collection: FleetMembersCollection = fleetMembersCollection;

  fleetMembersChannel = null;

  @Getter("mobile") mobile;

  get fleet() {
    return fleetsCollection.record;
  }

  get metaTitle(): string {
    if (!this.fleet) {
      return null;
    }

    return this.$t("title.fleets.members", { fleet: this.fleet.name });
  }

  get crumbs(): BreadCumb[] {
    if (!this.fleet) {
      return [];
    }

    return [
      {
        to: {
          name: "fleet",
          params: {
            slug: this.fleet.slug,
          },
        },
        label: this.fleet.name,
      },
    ];
  }

  get filters(): FleetMembersParams {
    return {
      slug: this.$route.params.slug,
      filters: this.$route.query.q,
      page: this.$route.query.page,
    };
  }

  get canInvite(): boolean {
    return ["admin", "officer"].includes(this.fleet.myRole);
  }

  mounted() {
    this.fetchFleet();
    this.fetch();
    this.setupUpdates();

    this.$comlink.$on("fleet-member-invited", this.fetch);
    this.$comlink.$on("fleet-member-update", this.fetch);
  }

  beforeDestroy() {
    this.$comlink.$off("fleet-member-invited");
    this.$comlink.$off("fleet-member-update");
  }

  async fetch() {
    await this.collection.findAll(this.filters);
    await this.collection.findStats(this.filters);
  }

  openInviteUrlModal() {
    this.$comlink.$emit("open-modal", {
      component: () =>
        import("@/frontend/components/Fleets/InviteUrlModal/index.vue"),
      props: {
        fleet: this.fleet,
      },
    });
  }

  openInviteModal() {
    this.$comlink.$emit("open-modal", {
      component: () =>
        import("@/frontend/components/Fleets/MemberModal/index.vue"),
      props: {
        fleet: this.fleet,
      },
    });
  }

  setupUpdates() {
    if (this.fleetMembersChannel) {
      this.fleetMembersChannel.unsubscribe();
    }

    this.fleetMembersChannel = this.$cable.consumer.subscriptions.create(
      {
        channel: "FleetMembersChannel",
      },
      {
        received: debounce(this.fetch, 500),
      }
    );
  }

  async fetchFleet() {
    await fleetsCollection.findBySlug(this.$route.params.slug);
  }
}
</script>
