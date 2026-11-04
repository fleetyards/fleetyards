<script lang="ts">
export default {
  name: "HangarFleetchartSharedPage",
};
</script>

<script lang="ts" setup>
import { useRoute, useRouter } from "vue-router";
import Alert from "@/shared/components/base/Alert/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import VehiclePanel from "@/frontend/components/Vehicles/Panel/index.vue";
import { placementsFromLayout } from "@/frontend/components/Fleetchart/savedLayouts";
import { usePublicFleetchartLayout } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import {
  FleetchartLayouts,
  useFleetchartStore,
} from "@/shared/stores/fleetchart";

const NAMESPACE = "sharedFleetchartLayout";

const route = useRoute();

const router = useRouter();

const { t } = useI18n();

const fleetchartStore = useFleetchartStore();

const token = computed(() => String(route.params.token));

const { data: layout, isLoading, isError } = usePublicFleetchartLayout(token);

const open = () => {
  fleetchartStore.show(NAMESPACE);
};

// Opens by itself once, as a background refetch must not bring back a chart the
// viewer closed.
const openedFor = ref<string>();

watch(
  layout,
  (shared) => {
    if (!shared) {
      return;
    }

    // The token decides what opens, so an address naming someone else is corrected
    // rather than presenting this layout as theirs.
    if (String(route.params.username) !== shared.username) {
      void router.replace({
        name: "hangar-fleetchart-layout-shared",
        params: { username: shared.username, token: token.value },
      });
    }

    fleetchartStore.updateLayout({
      namespace: NAMESPACE,
      layout: FleetchartLayouts.FREE,
    });
    fleetchartStore.updatePlacements({
      namespace: NAMESPACE,
      placements: placementsFromLayout(shared.placements),
    });

    if (shared.colored !== fleetchartStore.coloredByDefault(NAMESPACE)) {
      fleetchartStore.togglePlain(NAMESPACE);
    }

    if (shared.vehicles.length && openedFor.value !== token.value) {
      openedFor.value = token.value;
      open();
    }
  },
  { immediate: true },
);

// There is nothing to go back to behind a shared chart, so closing it moves on.
const leave = () => {
  if (isError.value || !layout.value) {
    return;
  }

  void router.push(
    layout.value.publicHangar
      ? { name: "hangar-public", params: { username: layout.value.username } }
      : { name: "home" },
  );
};

// Stopping to share reaches someone already looking at it on the next refetch.
watch(isError, (failed) => {
  if (failed) {
    fleetchartStore.hide(NAMESPACE);
  }
});

onBeforeUnmount(() => {
  fleetchartStore.hide(NAMESPACE);
});
</script>

<template>
  <Loader :loading="isLoading" />

  <Alert v-if="isError" variant="neutral" data-test="fleetchart-shared-missing">
    {{ t("labels.fleetchartApp.sharedLayoutMissing") }}
  </Alert>

  <template v-if="layout && !isError">
    <Heading size="hero" hero>{{ layout.name }}</Heading>

    <div class="fleetchart-shared__intro">
      <p class="fleetchart-shared__byline">
        {{
          t("labels.fleetchartApp.sharedLayoutBy", {
            username: layout.username,
          })
        }}
        <template v-if="layout.vehicles.length">
          ·
          {{
            t("labels.fleetchartApp.sharedLayoutShips", {
              count: layout.vehicles.length,
            })
          }}
        </template>
      </p>

      <div class="fleetchart-shared__actions">
        <Btn
          v-if="layout.vehicles.length"
          data-test="fleetchart-shared-open"
          @click="open"
        >
          <i class="fa-duotone fa-grid-2" />
          <span>{{ t("labels.fleetchart") }}</span>
        </Btn>
        <Btn
          v-if="layout.publicHangar"
          :to="{
            name: 'hangar-public',
            params: { username: layout.username },
          }"
          data-test="fleetchart-shared-hangar"
        >
          <i class="fa-duotone fa-warehouse" />
          <span>{{ t("labels.fleetchartApp.sharedLayoutHangar") }}</span>
        </Btn>
      </div>
    </div>

    <Alert
      v-if="!layout.vehicles.length"
      variant="neutral"
      data-test="fleetchart-shared-empty"
    >
      {{ t("labels.fleetchartApp.sharedLayoutEmpty") }}
    </Alert>

    <template v-else>
      <Grid :records="layout.vehicles" :filter-visible="false" primary-key="id">
        <template #default="{ record }">
          <VehiclePanel :vehicle="record" :details="false" :editable="false" />
        </template>
      </Grid>

      <FleetchartApp
        :items="layout.vehicles"
        :namespace="NAMESPACE"
        :arrange-items="layout.vehicles"
        :arrange-loaded="true"
        :download-name="`layout-${layout.username}`"
        read-only
        @fleetchart-closed="leave"
      />
    </template>
  </template>
</template>

<style lang="scss" scoped>
.fleetchart-shared__intro {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 24px;
}

.fleetchart-shared__byline {
  margin: 0;
}

.fleetchart-shared__actions {
  display: flex;
  gap: 10px;
}
</style>
