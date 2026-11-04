<script lang="ts">
export default {
  name: "HangarFleetchartSharedPage",
};
</script>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import Alert from "@/shared/components/base/Alert/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import { placementsFromLayout } from "@/frontend/components/Fleetchart/savedLayouts";
import { usePublicFleetchartLayout } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import {
  FleetchartLayouts,
  useFleetchartStore,
} from "@/shared/stores/fleetchart";

const NAMESPACE = "sharedFleetchartLayout";

const route = useRoute();

const { t } = useI18n();

const fleetchartStore = useFleetchartStore();

const token = computed(() => String(route.params.token));

const { data: layout, isLoading, isError } = usePublicFleetchartLayout(token);

const open = () => {
  fleetchartStore.show(NAMESPACE);
};

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
      placements: placementsFromLayout(shared.placements),
    });

    if (shared.colored !== fleetchartStore.coloredByDefault(NAMESPACE)) {
      fleetchartStore.togglePlain(NAMESPACE);
    }

    if (shared.vehicles.length) {
      open();
    }
  },
  { immediate: true },
);

onBeforeUnmount(() => {
  fleetchartStore.hide(NAMESPACE);
});
</script>

<template>
  <Loader :loading="isLoading" />

  <Alert v-if="isError" variant="neutral" data-test="fleetchart-shared-missing">
    {{ t("labels.fleetchartApp.sharedLayoutMissing") }}
  </Alert>

  <template v-if="layout">
    <Heading size="hero" hero>{{ layout.name }}</Heading>
    <p>
      {{
        t("labels.fleetchartApp.sharedLayoutBy", { username: layout.username })
      }}
    </p>

    <Alert
      v-if="!layout.vehicles.length"
      variant="neutral"
      data-test="fleetchart-shared-empty"
    >
      {{ t("labels.fleetchartApp.sharedLayoutEmpty") }}
    </Alert>

    <template v-else>
      <Btn data-test="fleetchart-shared-open" @click="open">
        {{ t("labels.fleetchart") }}
      </Btn>

      <FleetchartApp
        :items="layout.vehicles"
        :namespace="NAMESPACE"
        :arrange-items="layout.vehicles"
        :arrange-loaded="true"
        :download-name="`layout-${layout.username}`"
        read-only
      />
    </template>
  </template>
</template>
