<script lang="ts">
export default {
  name: "FleetMembershipPage",
};
</script>

<script lang="ts" setup>
// import Btn from "@/shared/components/base/Btn/index.vue";
// import FormCheckbox from "@/frontend/core/components/Form/FormCheckbox/index.vue";
// import FilterGroup from "@/frontend/core/components/Form/FilterGroup/index.vue";
import { type Fleet, type FleetMember } from "@/services/fyApi";
import { useFleetMeta } from "@/frontend/composables/useFleetMeta";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

// useFleetMeta(props.fleet);

// collection: FleetMembersCollection = fleetMembersCollection;

// submitting = false;

// form: FleetMembershipForm = {
//   primary: false,
//   shipsFilter: null,
//   hangarGroupId: null,
// };

// get fleet() {
//   return fleetsCollection.record;
// }

// get metaTitle() {
//   if (!this.fleet) {
//     return null;
//   }

//   return this.$t("title.fleets.settings", { fleet: this.fleet.name });
// }

// get crumbs() {
//   if (!this.fleet) {
//     return [];
//   }

//   return [
//     {
//       to: {
//         name: "fleet",
//         params: {
//           slug: this.fleet.slug,
//         },
//       },

//       label: this.fleet.name,
//     },
//   ];
// }

// get shipsFilterIsHangarGroup() {
//   return this.form.shipsFilter === "hangar_group";
// }

// get shipsFilterOptions() {
//   return [
//     {
//       name: this.$t("labels.fleet.members.shipsFilter.values.all"),
//       value: "all",
//     },
//     {
//       name: this.$t("labels.fleet.members.shipsFilter.values.hangar_group"),
//       value: "hangar_group",
//     },
//     {
//       name: this.$t("labels.fleet.members.shipsFilter.values.hide"),
//       value: "hide",
//     },
//   ];
// }

// get membership() {
//   return this.collection.record;
// }

// @Watch("$route")
// onRouteChange() {
//   this.fetchFleet();
// }

// @Watch("fleet")
// onFleetChange() {
//   this.fetch();
// }

// @Watch("shipsFilterIsHangarGroup")
// onShipsFilterChange() {
//   if (!this.shipsFilterIsHangarGroup) {
//     this.form.hangarGroupId = null;
//   }
// }

// mounted() {
//   this.fetchFleet();
//   this.fetch();
// }

// setupForm() {
//   this.form = {
//     primary: this.membership?.primary,
//     shipsFilter: this.membership?.shipsFilter,
//     hangarGroupId: this.membership?.hangarGroupId,
//   };
// }

// async fetch() {
//   await this.collection.findByFleet(this.$route.params.slug);

//   this.setupForm();
// }

// async fetchFleet() {
//   await fleetsCollection.findBySlug(this.$route.params.slug);
// }

// async submit() {
//   this.submitting = true;

//   const response = await this.$api.put(
//     `fleets/${this.$route.params.slug}/members`,
//     this.form,
//   );

//   this.submitting = false;

//   if (!response.error) {
//     displaySuccess({
//       text: this.$t("messages.fleet.members.update.success"),
//     });

//     this.$comlink.$emit("fleet-update");
//   } else {
//     displayAlert({
//       text: this.$t("messages.fleet.members.update.failure"),
//     });
//   }
// }
</script>

<template>
  {{ fleet }}
  {{ membership }}
  <!-- <section class="container">
    <div class="row">
      <div class="col-lg-12">
        <BreadCrumbs :crumbs="crumbs" />
        <h1>{{ $t("headlines.fleets.settings.membership") }}</h1>
      </div>
    </div>
    <ValidationObserver v-slot="{ handleSubmit }" :slim="true">
      <form v-if="fleet && form" @submit.prevent="handleSubmit(submit)">
        <div class="row">
          <div class="col-lg-12 col-xl-6">
            <FormCheckbox
              id="primary"
              v-model="form.primary"
              :label="$t('labels.fleet.members.primary')"
            />
          </div>
        </div>
        <div class="row">
          <div class="col-lg-12 col-xl-6">
            <ValidationProvider
              v-slot="{ errors }"
              vid="shipsFilter"
              rules="required"
              :name="$t('labels.fleet.members.shipsFilter.field')"
              :slim="true"
            >
              <div
                :class="{ 'has-error has-feedback': errors[0] }"
                class="form-group"
              >
                <FilterGroup
                  :key="'ships-filter'"
                  v-model="form.shipsFilter"
                  translation-key="fleet.members.shipsFilter"
                  :options="shipsFilterOptions"
                  name="shipsFilter"
                />
              </div>
            </ValidationProvider>
          </div>
          <div v-if="shipsFilterIsHangarGroup" class="col-lg-12 col-xl-6">
            <ValidationProvider
              v-slot="{ errors }"
              vid="hangarGroupId"
              rules="required"
              :name="$t('labels.fleet.members.hangarGroupId.field')"
              :slim="true"
            >
              <div
                :class="{ 'has-error has-feedback': errors[0] }"
                class="form-group"
              >
                <FilterGroup
                  :key="'hangar-group-id'"
                  v-model="form.hangarGroupId"
                  translation-key="fleet.members.hangarGroupId"
                  fetch-path="hangar-groups"
                  value-attr="id"
                  name="hangarGroupId"
                />
              </div>
            </ValidationProvider>
          </div>
        </div>
        <br />
        <Btn
          :loading="submitting"
          type="submit"
          size="large"
          data-test="fleet-save"
        >
          {{ $t("actions.save") }}
        </Btn>
      </form>
    </ValidationObserver>
  </section> -->
</template>
