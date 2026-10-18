<script lang="ts">
export default {
  name: "HangarSyncCountList",
};
</script>

<script lang="ts" setup>
import NumberFlow from "@number-flow/vue";
import { useI18n } from "@/shared/composables/useI18n";
import SyncProgressBar from "@/frontend/components/Hangar/SyncProgressBar/index.vue";
import SyncNumberText from "@/frontend/components/Hangar/SyncNumberText/index.vue";
import type { SyncCount } from "./types";

type Props = {
  counts: SyncCount[];
};

const props = defineProps<Props>();

const { t } = useI18n();

// The column after the count exists only where a row has something for it, so
// a plain list keeps its numbers flush right.
const hasAside = computed(() =>
  props.counts.some((count) => count.reference !== undefined),
);

const measured = (count: SyncCount) =>
  count.reference !== undefined && typeof count.value === "number";

// A run past the last sync's figure says by how much rather than "240 of 229",
// and a finished one says how far it ended from it.
const aside = (count: SyncCount) => {
  if (count.reference === undefined || typeof count.value !== "number") {
    return undefined;
  }

  if (count.final) {
    const delta = count.value - count.reference;
    if (delta === 0) return undefined;

    return {
      short: {
        template: delta > 0 ? "+%{count}" : "−%{count}",
        values: { count: Math.abs(delta) },
      },
      long: t(
        delta > 0
          ? "labels.syncExtension.lastSync.more"
          : "labels.syncExtension.lastSync.fewer",
        { count: Math.abs(delta) },
      ),
      tone: delta > 0 ? "more" : "fewer",
    };
  }

  if (count.value > count.reference) {
    const more = count.value - count.reference;

    return {
      short: { template: "+%{count}", values: { count: more } },
      long: t("labels.syncExtension.lastSync.more", { count: more }),
      tone: "more",
    };
  }

  return {
    short: {
      key: "labels.syncExtension.lastSync.of",
      values: { count: count.reference },
    },
    long: t("labels.syncExtension.lastSync.ofLong", {
      count: count.reference,
    }),
    tone: "reference",
  };
};
</script>

<template>
  <!--
    One list for a run in progress and its result. A number counts up in place,
    and a row that turns up fades in while the others slide aside, so nothing
    jumps while a run is reading.
  -->
  <TransitionGroup
    tag="dl"
    name="sync-count-list"
    class="sync-count-list"
    :class="{ 'sync-count-list--aside': hasAside }"
  >
    <div
      v-for="count in counts"
      :key="count.key"
      class="sync-count-list__row"
      :class="{ 'sync-count-list__row--skipped': count.skipped }"
      :data-test="`sync-count-${count.key}`"
    >
      <dt class="sync-count-list__label" :data-test="count.labelTest">
        {{ count.label }}
        <span v-if="count.note" class="sync-count-list__note">
          {{ count.note }}
        </span>
      </dt>
      <dd
        class="sync-count-list__value"
        :data-test="count.valueTest"
        :data-count="typeof count.value === 'number' ? count.value : undefined"
      >
        <NumberFlow
          v-if="typeof count.value === 'number'"
          :value="count.value"
        />
        <template v-else>{{ count.value }}</template>
      </dd>
      <dd
        v-if="hasAside"
        class="sync-count-list__aside"
        :class="aside(count) && `sync-count-list__aside--${aside(count)?.tone}`"
        :data-test="`sync-count-${count.key}-aside`"
      >
        <template v-if="aside(count)">
          <SyncNumberText
            v-if="aside(count)?.short"
            aria-hidden="true"
            :text="aside(count)!.short"
          />
          <span class="sr-only">{{ aside(count)?.long }}</span>
        </template>
      </dd>
      <dd v-if="measured(count)" class="sync-count-list__bar">
        <SyncProgressBar
          slim
          :progress="{
            value: Number(count.value),
            max: count.reference ?? 0,
            reference: count.reference,
            final: count.final,
          }"
          :label="count.label"
          :value-text="aside(count)?.long"
        />
      </dd>
    </div>
  </TransitionGroup>
</template>

<style lang="scss" scoped>
// One frame around the rows, divided rather than boxed, as the settings list.
.sync-count-list {
  display: flex;
  flex-direction: column;
  margin: 0;
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-surface-slim, 12px);
}

.sync-count-list__row {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: baseline;
  column-gap: 12px;
  padding: 8px 14px;

  & + & {
    border-top: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
  }
}

.sync-count-list--aside .sync-count-list__row {
  grid-template-columns: minmax(0, 1fr) auto 72px;
}

// Under the row's text, across all its columns.
.sync-count-list__bar {
  grid-column: 1 / -1;
  margin: 6px 0 2px;
}

.sync-count-list__label {
  min-width: 0;
  color: var(--color-text-dim, #959595);
  font-size: 14px;
  font-weight: normal;
}

.sync-count-list__row--skipped .sync-count-list__label {
  font-style: italic;
}

.sync-count-list__note {
  margin-left: 6px;
  color: var(--color-success, #5cb85c);
  font-size: 12px;
}

.sync-count-list__value {
  margin: 0;
  color: var(--color-lifted, #eee);
  font-size: 15px;
  text-align: right;
  font-variant-numeric: tabular-nums;
}

.sync-count-list__aside {
  margin: 0;
  color: var(--color-text-dim, #959595);
  font-size: 13px;
  text-align: right;
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}

.sync-count-list__aside--more {
  color: var(--color-success, #5cb85c);
}

.sync-count-list__aside--fewer {
  color: var(--color-warning, #fa6800);
}

.sync-count-list-enter-active,
.sync-count-list-move {
  transition:
    opacity 250ms ease,
    transform 250ms ease;
}

.sync-count-list-enter-from {
  opacity: 0;
  transform: translateY(-4px);
}

@media (prefers-reduced-motion: reduce) {
  .sync-count-list-enter-active,
  .sync-count-list-move {
    transition: none;
  }
}
</style>
