<template>
  <BtnDropdown
    v-if="mobile"
    :mobile-block="true"
    size="small"
    class="labels-dropdown"
  >
    <template #label>Classifications</template>
    <template #default>
      <Btn
        v-for="classification in countData"
        :key="`dropdown-${classification.name}`"
        variant="dropdown"
        class="labels-dropdown-item"
        :class="{
          active: isActive(classification.name),
        }"
        @click="filter(classification.name)"
      >
        {{ classification.label }}
        <span class="label-count">{{ classification.count }}</span>
      </Btn>
    </template>
  </BtnDropdown>
  <div v-else class="labels">
    <transition-group name="fade-list" appear>
      <a
        v-for="classification in countData"
        :key="classification.name"
        :class="{
          'label-link': filterKey,
          active: isActive(classification.name),
        }"
        class="label fade-list-item"
        @click="filter(classification.name)"
      >
        <span class="label-inner">
          {{ classification.label }}: {{ classification.count }}
        </span>
      </a>
    </transition-group>
  </div>
</template>

<script lang="ts" setup>
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { useRoute, useRouter } from "vue-router";

type Props = {
  countData: {
    name: string;
    label: string;
    count: number;
  }[];
  filterKey?: string;
  label?: string;
};

const props = withDefaults(defineProps<Props>(), {
  filterKey: undefined,
  label: undefined,
});

const mobile = useMobile();

const route = useRoute();

const router = useRouter();

const filter = (filter: string) => {
  if (!props.filterKey) {
    return;
  }
  const query = JSON.parse(JSON.stringify(route.query.q || {}));

  if ((query[props.filterKey] || []).includes(filter)) {
    const index = query[props.filterKey].findIndex(
      (item: string) => item === filter,
    );
    if (index > -1) {
      query[props.filterKey].splice(index, 1);
    }
  } else {
    if (!query[props.filterKey]) {
      query[props.filterKey] = [];
    }
    query[props.filterKey].push(filter);
  }

  router.replace({
    name: route.name || "home",
    query: {
      q: query,
    },
  });
};

const isActive = (classification: string) => {
  if (!route.query.q || !props.filterKey) {
    return false;
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const classFilter = (route.query.q as Record<string, any>)[props.filterKey];
  if (!classFilter) {
    return false;
  }

  if (classFilter.includes(classification)) {
    return true;
  }

  return false;
};
</script>

<script lang="ts">
export default {
  name: "ModelClassLabels",
};
</script>
