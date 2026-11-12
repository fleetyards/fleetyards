<script lang="ts">
export default {
  name: "HomeDashboardPatchTile",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { liveQuery } from "@/shared/components/Dashboard/liveQuery";
import { usePatchLoadingScreens } from "@/frontend/composables/usePatchLoadingScreens";
import { useMyPatchChanges } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useQueryClient } from "@tanstack/vue-query";
import { useScDataSourceStore } from "@/shared/stores/scDataSource";
import patchArt from "@/images/bg-3.webp";

type Props = {
  environment: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { build, pick } = usePatchLoadingScreens(() => props.environment);

const label = computed(() =>
  props.environment.toLowerCase() === "live"
    ? t("home.dashboard.tiles.patch")
    : t("home.dashboard.tiles.patchPreview"),
);

const background = computed(() => pick(0, patchArt));

// Not retried: a build the server stopped offering answers
// not found, and this card then has nothing true left to say.
const { data: changes, isError } = useMyPatchChanges(
  () => ({ environment: props.environment }),
  { query: { ...liveQuery, retry: false } },
);

const sourceStore = useScDataSourceStore();

const queryClient = useQueryClient();

// The stats page reads the source the reader is on, so the card of the other
// build switches to it first, the way the navigation's switch does.
const openSource = () => {
  const current = sourceStore.selected?.environment.toLowerCase() || "live";
  if (current === props.environment.toLowerCase()) return;

  sourceStore.select(
    sourceStore.defaultSource?.environment.toLowerCase() ===
      props.environment.toLowerCase()
      ? undefined
      : props.environment,
  );

  void queryClient.invalidateQueries();
};

// Owned ships only: a wishlist ship the patch changed is not "yours", and
// `items` stops at the most changed few.
const changedCount = computed(() => changes.value?.ownedCount || 0);

// The build the count is for, which is the build served: a newer one whose load
// is still running has rows but no changes yet. `4.3.2-live.12913470` names
// its environment already; the tile shows the release.
const version = computed(() => changes.value?.version || build.value?.version);

const release = computed(() => version.value?.split("-")[0]);
</script>

<template>
  <router-link
    v-if="!isError"
    :to="{ name: 'stats' }"
    class="home-patch-tile"
    @click="openSource"
    :data-test="`home-tile-patch-${environment}`"
  >
    <Panel
      :variant="PanelVariantsEnum.SLIM"
      :outer-spacing="false"
      class="home-patch-tile__panel"
    >
      <div
        class="home-patch-tile__body"
        :style="{ '--patch-art': `url(${background})` }"
      >
        <span class="home-patch-tile__label">
          {{ label }}
        </span>
        <span v-tooltip="version" class="home-patch-tile__value">
          {{ release || "–" }}
        </span>
        <span class="home-patch-tile__hint">
          {{
            changedCount
              ? t("home.dashboard.tiles.patchChanged", { count: changedCount })
              : t("home.dashboard.tiles.patchWhatChanged")
          }}
        </span>
      </div>
    </Panel>
  </router-link>
</template>

<style lang="scss" scoped>
.home-patch-tile {
  display: block;
  min-width: 0;
  color: inherit;
  text-decoration: none;
}

.home-patch-tile__panel {
  height: 100%;
}

// The loading screen sits inside the frame, cut to the frame's inner radius,
// under a scrim from the left that keeps the text readable on whichever screen
// the patch drew.
.home-patch-tile__body {
  position: relative;
  z-index: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 2px;
  height: 100%;
  min-height: 96px;
  padding: 14px 18px;
  box-sizing: border-box;
  border-radius: calc(var(--radius-surface-slim, 12px) - 1px);
  background:
    linear-gradient(
      90deg,
      rgb(0 0 0 / 0.75) 0%,
      rgb(0 0 0 / 0.35) 70%,
      rgb(0 0 0 / 0.15) 100%
    ),
    var(--patch-art) center / cover no-repeat;
}

.home-patch-tile__label {
  color: var(--color-text, #c8c8c8);
  font-size: 0.6875rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.home-patch-tile__value {
  color: var(--color-lifted, #eee);
  font-family: "Orbitron", sans-serif;
  font-size: 1.5rem;
  line-height: 1.2;
}

.home-patch-tile__hint {
  color: var(--color-text, #c8c8c8);
  font-size: 0.75rem;
}
</style>
