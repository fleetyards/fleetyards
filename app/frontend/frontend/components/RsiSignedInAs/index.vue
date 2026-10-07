<script lang="ts">
export default {
  name: "RsiSignedInAs",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { RSI_ACCOUNT_DASHBOARD_URL } from "@/frontend/lib/rsiLinks";

type Props = {
  handle: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

// The handle links to the RSI account, where someone signed in with the wrong
// one can sign out. Translated around a marker so every locale keeps its own
// word order, and the handle stays text rather than HTML.
const HANDLE_MARKER = "\u0000";

const parts = computed(() =>
  t("labels.syncExtension.signedInAs", { handle: HANDLE_MARKER }).split(
    HANDLE_MARKER,
  ),
);
</script>

<template>
  <span data-test="rsi-signed-in-as">
    {{ parts[0]
    }}<a
      :href="RSI_ACCOUNT_DASHBOARD_URL"
      target="_blank"
      rel="noopener"
      data-test="rsi-signed-in-as-handle"
      >{{ props.handle }}</a
    >{{ parts[1] }}
  </span>
</template>
