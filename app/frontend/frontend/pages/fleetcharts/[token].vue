<script lang="ts">
export default {
  name: "FleetchartLayoutPage",
};
</script>

<script lang="ts" setup>
import { useRoute, useRouter } from "vue-router";
import Alert from "@/shared/components/base/Alert/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import { catalogueEntriesFrom } from "@/frontend/components/Fleetchart/catalogueShips";
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

const {
  data: layout,
  isLoading,
  error,
} = usePublicFleetchartLayout(token, { query: { retry: false } });

const ships = computed(() =>
  layout.value
    ? [
        ...layout.value.vehicles,
        ...catalogueEntriesFrom(
          layout.value.cataloguePlacements,
          layout.value.models,
        ),
      ]
    : [],
);

// A failed refresh keeps the layout on screen; only a 404 means the link has gone.
const isMissing = computed(
  () =>
    !!error.value &&
    (!layout.value ||
      (error.value as { response?: { status?: number } }).response?.status ===
        404),
);

let opened = false;

watch(
  layout,
  (shared) => {
    if (!shared) {
      return;
    }

    fleetchartStore.updateLayout({
      namespace: NAMESPACE,
      layout: FleetchartLayouts.FREE,
    });
    fleetchartStore.updatePlacements({
      namespace: NAMESPACE,
      placements: placementsFromLayout(
        shared.placements,
        shared.cataloguePlacements,
      ),
    });

    if (shared.colored !== fleetchartStore.coloredByDefault(NAMESPACE)) {
      fleetchartStore.togglePlain(NAMESPACE);
    }

    // Only the first time: a background refetch must not bring back a chart that
    // is already on its way out.
    if (ships.value.length && !opened) {
      opened = true;
      fleetchartStore.show(NAMESPACE);
    }
  },
  { immediate: true },
);

// The chart is the whole page, so closing it has to go somewhere.
const leave = () => {
  if (isMissing.value || !layout.value) {
    return;
  }

  void router.push(
    layout.value.publicHangar && layout.value.username
      ? { name: "hangar-public", params: { username: layout.value.username } }
      : { name: "home" },
  );
};

// Stopping to share reaches someone already looking at it on the next refetch.
watch(isMissing, (missing) => {
  if (missing) {
    fleetchartStore.hide(NAMESPACE);
  }
});

onBeforeUnmount(() => {
  fleetchartStore.hide(NAMESPACE);
});
</script>

<template>
  <div class="fleetchart-shared" data-test="fleetchart-shared">
    <Loader :loading="isLoading" />

    <div
      v-if="isMissing || (layout && !ships.length)"
      class="fleetchart-shared__notice"
    >
      <Alert variant="neutral" data-test="fleetchart-shared-notice">
        {{
          isMissing
            ? t("labels.fleetchartApp.sharedLayoutMissing")
            : t("labels.fleetchartApp.sharedLayoutEmpty")
        }}
      </Alert>
      <Btn :to="{ name: 'home' }" data-test="fleetchart-shared-home">
        {{ t("nav.home") }}
      </Btn>
    </div>

    <FleetchartApp
      v-else-if="layout"
      :items="ships"
      :namespace="NAMESPACE"
      :arrange-items="ships"
      :arrange-loaded="true"
      download-name="shared-layout"
      read-only
      @fleetchart-closed="leave"
    >
      <template #title>
        <div class="fleetchart-shared__title">
          <strong>{{ layout.name }}</strong>
          <small v-if="layout.username">
            {{
              t("labels.fleetchartApp.sharedLayoutBy", {
                username: layout.username,
              })
            }}
          </small>
        </div>
      </template>
    </FleetchartApp>
  </div>
</template>

<style lang="scss" scoped>
// On the chart's own layer and in its colour, so the app around it never shows.
.fleetchart-shared {
  position: fixed;
  inset: 0;
  z-index: 2100;
  background-color: #111;
}

.fleetchart-shared__notice {
  display: flex;
  flex-direction: column;
  gap: 16px;
  align-items: center;
  justify-content: center;
  height: 100%;
  padding: 16px;
}

.fleetchart-shared__title {
  display: flex;
  flex-direction: column;
  text-shadow: 0 0 2px black;

  strong {
    font-size: 150%;
    font-family: "Orbitron", sans-serif;
  }

  small {
    color: darken($text-color, 20%);
  }
}
</style>
