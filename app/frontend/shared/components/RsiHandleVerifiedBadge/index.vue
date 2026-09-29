<script lang="ts">
export default {
  name: "RsiHandleVerifiedBadge",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  verifiedVia?: "citizenid" | "rsi_profile" | null;
  citizenidProfileUrl?: string | null;
};

const props = withDefaults(defineProps<Props>(), {
  verifiedVia: null,
  citizenidProfileUrl: null,
});

const { t } = useI18n();

const viaProfile = computed(() => props.verifiedVia === "rsi_profile");

const label = computed(() =>
  viaProfile.value
    ? t("labels.user.rsiHandleVerifiedViaProfile")
    : t("labels.user.rsiHandleVerified"),
);
</script>

<template>
  <a
    v-if="!viaProfile && citizenidProfileUrl"
    :href="citizenidProfileUrl"
    :aria-label="label"
    target="_blank"
    rel="noopener"
    data-test="rsi-handle-verified-badge"
  >
    <i v-tooltip="label" class="fa-duotone fa-badge-check text-success" />
  </a>
  <span
    v-else
    role="img"
    :aria-label="label"
    data-test="rsi-handle-verified-badge"
  >
    <i v-tooltip="label" class="fa-duotone fa-badge-check text-success" />
  </span>
</template>
