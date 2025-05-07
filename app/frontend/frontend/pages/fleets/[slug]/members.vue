<script lang="ts">
export default {
  name: "FleetMembersPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  useFleetMembersStats as useFleetMembersStatsQuery,
  type Fleet,
  type FleetMember,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { data: stats } = useFleetMembersStatsQuery(props.fleet.slug);

const crumbs = computed(() => {
  return [
    {
      to: {
        name: "fleet",
        params: {
          slug: props.fleet.slug,
        },
      },
      label: props.fleet.name,
    },
  ];
});

// import Vue from "vue";
// import { Component } from "vue-property-decorator";
// import { Getter } from "vuex-class";
// import fleetMembersCollection from "@/frontend/api/collections/FleetMembers";
// import { fleetRouteGuard } from "@/frontend/utils/RouteGuards/Fleets";
// import fleetsCollection from "@/frontend/api/collections/Fleets";
// import { debounce } from "ts-debounce";
// import FilteredList from "@/shared/components/FilteredList/index.vue";
// import BreadCrumbs from "@/frontend/core/components/BreadCrumbs/index.vue";
// import Btn from "@/shared/components/base/Btn/index.vue";
// import BtnDropdown from "@/frontend/core/components/BtnDropdown/index.vue";
// import FleetMembersFilterForm from "@/frontend/components/Fleets/MembersFilterForm/index.vue";
// import Avatar from "@/frontend/core/components/Avatar/index.vue";
// import FleetMembersList from "@/frontend/components/Fleets/MembersList/index.vue";
// import Panel from "@/shared/components/base/Panel/index.vue";

// @Component<FleetMembers>({
//   components: {
//     Btn,
//     BtnDropdown,
//     BreadCrumbs,
//     Panel,
//     FilteredList,
//     FleetMembersFilterForm,
//     Avatar,
//     FleetMembersList,
//   },
//   beforeRouteEnter: fleetRouteGuard,
// })
// export default class FleetMemmbers extends Vue {
//   collection: FleetMembersCollection = fleetMembersCollection;

//   fleetMembersChannel = null;

//   @Getter("mobile") mobile;

//   get fleet() {
//     return fleetsCollection.record;
//   }

//   get metaTitle(): string {
//     if (!this.fleet) {
//       return null;
//     }

//     return this.$t("title.fleets.members", { fleet: this.fleet.name });
//   }

//   get filters(): FleetMembersParams {
//     return {
//       slug: this.$route.params.slug,
//       filters: this.$route.query.q,
//       page: this.$route.query.page,
//     };
//   }

//   get canInvite(): boolean {
//     return ["admin", "officer"].includes(this.fleet.myRole);
//   }

//   mounted() {
//     this.fetchFleet();
//     this.fetch();
//     this.setupUpdates();

//     this.$comlink.$on("fleet-member-invited", this.fetch);
//     this.$comlink.$on("fleet-member-update", this.fetch);
//   }

//   beforeDestroy() {
//     this.$comlink.$off("fleet-member-invited");
//     this.$comlink.$off("fleet-member-update");
//   }

//   async fetch() {
//     await this.collection.findAll(this.filters);
//     await this.collection.findStats(this.filters);
//   }

//   openInviteUrlModal() {
//     this.$comlink.$emit("open-modal", {
//       component: () =>
//         import("@/frontend/components/Fleets/InviteUrlModal/index.vue"),
//       props: {
//         fleet: this.fleet,
//       },
//     });
//   }

//   openInviteModal() {
//     this.$comlink.$emit("open-modal", {
//       component: () =>
//         import("@/frontend/components/Fleets/MemberModal/index.vue"),
//       props: {
//         fleet: this.fleet,
//       },
//     });
//   }

//   setupUpdates() {
//     if (this.fleetMembersChannel) {
//       this.fleetMembersChannel.unsubscribe();
//     }

//     this.fleetMembersChannel = this.$cable.consumer.subscriptions.create(
//       {
//         channel: "FleetMembersChannel",
//       },
//       {
//         received: debounce(this.fetch, 500),
//       },
//     );
//   }

//   async fetchFleet() {
//     await fleetsCollection.findBySlug(this.$route.params.slug);
//   }
// }
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />
  <Heading>
    {{ t("headlines.fleets.members") }}
    <small v-if="stats" class="text-muted">
      {{
        t("labels.fleet.members.total", {
          count: stats.total,
        })
      }}
    </small>
  </Heading>
  <!-- <div class="col-4">
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
      <template v-if="mobile && canInvite" #actions>
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
  </section> -->
</template>
