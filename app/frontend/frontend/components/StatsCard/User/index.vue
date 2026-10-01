<script lang="ts">
export default {
  name: "UserStatsCard",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import StatsCard from "@/frontend/components/StatsCard/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type UserPublic } from "@/services/fyApi";

type Props = {
  user?: UserPublic;
  name?: string;
  to?: RouteLocationRaw | false;
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  user: undefined,
  name: undefined,
  to: undefined,
  loading: false,
});

const emit = defineEmits<{ navigate: [] }>();

const { t } = useI18n();

const subtitle = computed(() =>
  props.user?.rsiHandle
    ? t("labels.statsCard.rsiHandle", { handle: props.user.rsiHandle })
    : undefined,
);
</script>

<template>
  <StatsCard
    compact
    :title="user?.username || name || ''"
    kind="User"
    :subtitle="subtitle"
    :to="to === false ? undefined : to"
    :loading="loading"
    :unavailable="!loading && !user"
    @navigate="emit('navigate')"
  />
</template>
