<script lang="ts">
export default {
  name: "GameEventActions",
};
</script>

<script lang="ts" setup>
import Items from "@/admin/components/GameEvents/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type GameEvent } from "@/services/fyAdminApi";

type Props = {
  gameEvent: GameEvent;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile">
    <Items :game-event="props.gameEvent" with-labels />
  </BtnDropdown>
  <BtnGroup v-else>
    <Items :game-event="props.gameEvent" />
  </BtnGroup>
</template>
