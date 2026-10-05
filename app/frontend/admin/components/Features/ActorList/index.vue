<script lang="ts">
export default {
  name: "FeatureActorList",
};
</script>

<script lang="ts" setup>
import { type FeatureActor } from "@/services/fyAdminApi";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  actors: FeatureActor[];
  name: string;
  filterLabel: string;
  emptyText: string;
};

const props = defineProps<Props>();

const emit = defineEmits<{
  remove: [actor: FeatureActor];
}>();

const { t } = useI18n();

// A rollout flag carries a few hundred actors, so the list shows a page at a
// time and filters in place rather than rendering every one.
const PAGE_SIZE = 50;

const filter = ref<string>();
const shown = ref(PAGE_SIZE);

watch(filter, () => {
  shown.value = PAGE_SIZE;
});

const filtered = computed(() => {
  const needle = filter.value?.trim().toLowerCase();
  const sorted = [...props.actors].sort((a, b) => a.name.localeCompare(b.name));

  if (!needle) return sorted;

  return sorted.filter(
    (actor) =>
      actor.name.toLowerCase().includes(needle) ||
      !!actor.fid?.toLowerCase().includes(needle),
  );
});

const visible = computed(() => filtered.value.slice(0, shown.value));
</script>

<template>
  <div class="feature-actor-list" :data-test="`feature-actors-${name}`">
    <p v-if="!actors.length" class="text-muted">{{ emptyText }}</p>

    <template v-else>
      <FormInput
        v-model="filter"
        :name="`feature-actors-filter-${name}`"
        :label="filterLabel"
        :placeholder="filterLabel"
        no-label
        clearable
      />

      <p v-if="!filtered.length" class="text-muted">
        {{ t("labels.features.noMatches") }}
      </p>

      <ul v-else class="feature-actor-rows">
        <li
          v-for="actor in visible"
          :key="actor.id"
          class="feature-actor-row"
          data-test="feature-actor-row"
        >
          <span class="feature-actor-name">{{ actor.name }}</span>
          <span v-if="actor.fid" class="feature-actor-fid text-muted">
            {{ actor.fid }}
          </span>
          <Btn
            class="feature-actor-remove"
            :aria-label="`${t('actions.remove')} ${actor.name}`"
            :title="t('actions.remove')"
            data-test="feature-actor-remove"
            @click="emit('remove', actor)"
          >
            <i class="fa-duotone fa-times" />
          </Btn>
        </li>
      </ul>

      <Btn
        v-if="filtered.length > visible.length"
        data-test="feature-actors-more"
        @click="shown += PAGE_SIZE"
      >
        {{ t("actions.loadMore") }}
        ({{ filtered.length - visible.length }})
      </Btn>
    </template>
  </div>
</template>

<style lang="scss" scoped>
.feature-actor-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;

  p {
    margin: 0;
  }
}

.feature-actor-rows {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(18rem, 1fr));
  gap: 0.25rem 1rem;
  list-style: none;
  margin: 0;
  padding: 0;
}

.feature-actor-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  min-width: 0;
}

.feature-actor-name {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.feature-actor-fid {
  font-family: monospace;
  white-space: nowrap;
}

.feature-actor-remove {
  margin-left: auto;
}
</style>
