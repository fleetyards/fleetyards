<script lang="ts">
export default {
  name: "FrontendRafflesNav",
};
</script>

<script lang="ts" setup>
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { FeatureFlagName } from "@/services/fyApi";

const { t } = useI18n();

const route = useRoute();

const { isFeatureEnabled } = useFeatures();

const active = computed(() => String(route.name ?? "").startsWith("raffle"));
</script>

<template>
  <NavItem
    v-if="isFeatureEnabled(FeatureFlagName.RAFFLES)"
    :to="{ name: 'raffles' }"
    :label="t('nav.raffles')"
    :active="active"
    icon="fa-duotone fa-ticket"
    data-test="raffles-nav"
  />
</template>
