<script lang="ts">
export default {
  name: "AdminFeaturePage",
};
</script>

<script lang="ts" setup>
import { useAdminFeature } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useSessionStore } from "@/admin/stores/session";
import { routes as featureRoutes } from "./[name]/routes";
import { useFeatureState } from "@/admin/composables/useFeatureState";

const route = useRoute();
const sessionStore = useSessionStore();
const { t } = useI18n();
const { stateVariant, stateLabel } = useFeatureState();

const featureName = computed(() => route.params.name as string);

const { data: feature, ...asyncStatus } = useAdminFeature(featureName);

const actorCount = (type: string) =>
  feature.value?.actors.filter((actor) => actor.type === type).length ?? 0;

const badges = computed(() => ({
  "admin-feature-users": actorCount("User"),
  "admin-feature-fleets": actorCount("Fleet"),
}));

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "admin-features" },
    label: t("headlines.admin.features.index"),
  },
]);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <template v-if="feature">
        <BreadCrumbs :crumbs="crumbs" />

        <Heading hero data-test="feature-heading">
          {{ feature.name }}
          <template #subHeading>
            <BasePill
              :variant="stateVariant(feature.state)"
              uppercase
              margin-right
              data-test="feature-state"
            >
              {{ stateLabel(feature.state) }}
            </BasePill>
            <BasePill v-if="feature.permanent" margin-right>
              {{ t("labels.features.permanent") }}
            </BasePill>
          </template>
        </Heading>

        <TabNavView
          :routes="featureRoutes"
          :resource-access="sessionStore.resourceAccess"
          :super-admin="sessionStore.isSuperAdmin"
          :badges="badges"
          authenticated
        >
          <template #content>
            <router-view :feature="feature" />
          </template>
        </TabNavView>
      </template>
    </template>
  </AsyncData>
</template>
