<template>
  <section class="container">
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
            <Checkbox
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
  </section>
</template>

<script lang="ts" setup>
import { ref, computed, watch, onMounted } from "vue";
import { useRoute } from "vue-router/composables";
import BreadCrumbs from "@/frontend/core/components/BreadCrumbs/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import Checkbox from "@/frontend/core/components/Form/Checkbox/index.vue";
import FilterGroup from "@/frontend/core/components/Form/FilterGroup/index.vue";
import { displaySuccess, displayAlert } from "@/frontend/lib/Noty";
import fleetMembersCollection from "@/frontend/api/collections/FleetMembers";
import type { FleetMembersCollection } from "@/frontend/api/collections/FleetMembers";
import fleetsCollection from "@/frontend/api/collections/Fleets";
import { fleetRouteGuard } from "@/frontend/utils/RouteGuards/Fleets";
import { useComlink } from "@/frontend/composables/useComlink";
import { useI18n } from "@/frontend/composables/useI18n";
import { useMetaInfo } from "@/frontend/composables/useMetaInfo";

const collection: FleetMembersCollection = fleetMembersCollection;

const submitting = ref(false);

const form = ref<FleetMembershipForm>({
  primary: false,
  shipsFilter: null,
  hangarGroupId: null,
});

const fleet = computed(() => fleetsCollection.record);

const { t } = useI18n();

const metaTitle = computed(() => {
  if (!fleet.value) {
    return undefined;
  }

  return t("title.fleets.settings", { fleet: fleet.value.name });
});

useMetaInfo(metaTitle);

const crumbs = computed(() => {
  if (!fleet.value) {
    return [];
  }

  return [
    {
      to: {
        name: "fleet",
        params: {
          slug: fleet.value.slug,
        },
      },

      label: fleet.value.name,
    },
  ];
});

const shipsFilterIsHangarGroup = computed(
  () => form.value.shipsFilter === "hangar_group"
);

const shipsFilterOptions = computed(() => [
  {
    name: t("labels.fleet.members.shipsFilter.values.all"),
    value: "all",
  },
  {
    name: t("labels.fleet.members.shipsFilter.values.hangar_group"),
    value: "hangar_group",
  },
  {
    name: t("labels.fleet.members.shipsFilter.values.hide"),
    value: "hide",
  },
]);

const membership = computed(() => collection.record);

const setupForm = () => {
  if (!membership.value) {
    return;
  }

  form.value = {
    primary: membership.value.primary,
    shipsFilter: membership.value.shipsFilter,
    hangarGroupId: membership.value.hangarGroupId,
  };
};

const route = useRoute();

const fetch = async () => {
  await collection.findByFleet(route.params.slug);

  setupForm();
};

const fetchFleet = async () => {
  await fleetsCollection.findBySlug(route.params.slug);
};

watch(
  () => route,
  () => {
    fetchFleet();
  },
  { deep: true }
);

watch(
  () => fleet.value,
  () => {
    fetch();
  }
);

watch(
  () => shipsFilterIsHangarGroup.value,
  () => {
    if (!shipsFilterIsHangarGroup.value) {
      form.value.hangarGroupId = null;
    }
  }
);

onMounted(() => {
  fetchFleet();
  fetch();
});

const comlink = useComlink();

const submit = async () => {
  submitting.value = true;

  const response = await collection.update(route.params.slug, form.value);

  submitting.value = false;

  if (!response.error) {
    displaySuccess({
      text: t("messages.fleet.members.update.success"),
    });

    comlink.$emit("fleet-update");
  } else {
    displayAlert({
      text: t("messages.fleet.members.update.failure"),
    });
  }
};
</script>

<script lang="ts">
export default {
  name: "FleetMembershipSettings",
  beforeRouteEnter: fleetRouteGuard,
};
</script>
