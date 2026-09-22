<script lang="ts">
export default {
  name: "FleetSquadronCard",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { Fleet, FleetSquadron } from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  squadron: FleetSquadron;
};

const props = defineProps<Props>();

const { t } = useI18n();

// The logo if there is one, the colour if there is not, and the quiet grey if
// neither -- so the card always carries something to tell it apart by.
const markStyle = computed(() => ({
  backgroundColor: props.squadron.color || "var(--color-muted)",
}));
</script>

<template>
  <Btn
    :to="{
      name: 'fleet-squadron',
      params: { slug: props.fleet.slug, squadron: props.squadron.slug },
    }"
    block
    class="justify-start"
    :data-test="`squadron-card-${props.squadron.slug}`"
  >
    <div class="squadron-card">
      <img
        v-if="props.squadron.logo?.smallUrl"
        :src="props.squadron.logo.smallUrl"
        :alt="props.squadron.name"
        class="squadron-card-logo"
      />
      <span v-else class="squadron-card-mark" :style="markStyle" />
      <div class="squadron-card-body">
        <h5>{{ props.squadron.name }}</h5>
        <p v-if="props.squadron.description" class="text-muted">
          {{ props.squadron.description }}
        </p>
        <span class="text-muted">
          {{
            t("labels.fleet.squadrons.memberCount", {
              count: props.squadron.memberCount,
            })
          }}
        </span>
      </div>
    </div>
  </Btn>
</template>

<style lang="scss" scoped>
.squadron-card {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  width: 100%;
  text-align: left;
}

.squadron-card-logo {
  width: 40px;
  height: 40px;
  object-fit: contain;
  flex-shrink: 0;
}

.squadron-card-mark {
  width: 12px;
  align-self: stretch;
  min-height: 40px;
  border-radius: 3px;
  flex-shrink: 0;
}

.squadron-card-body {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}
</style>
