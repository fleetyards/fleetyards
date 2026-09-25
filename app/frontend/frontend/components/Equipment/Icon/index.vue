<script lang="ts">
export default {
  name: "EquipmentIcon",
};
</script>

<script lang="ts" setup>
import { type Equipment } from "@/services/fyApi";

type Props = {
  equipment: Equipment;
};

const props = defineProps<Props>();

// No equipment carries a picture -- the loadout icons the records name are art
// the export leaves out -- so the type is the leading mark.
const TYPE_ICONS: Record<string, string> = {
  armor: "fa-shield-halved",
  clothing: "fa-shirt",
  hacking_tool: "fa-microchip",
  medical: "fa-briefcase-medical",
  tool: "fa-screwdriver-wrench",
  undersuit: "fa-user-astronaut",
  weapon: "fa-crosshairs",
  weapon_attachment: "fa-puzzle-piece",
};

const glyph = computed(
  () => TYPE_ICONS[props.equipment.equipmentType ?? ""] ?? "fa-box",
);
</script>

<template>
  <span class="equipment-icon">
    <i :class="['fa-duotone', glyph]" />
  </span>
</template>

<style lang="scss" scoped>
.equipment-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  flex: none;
  font-size: 18px;
  line-height: 1;
  color: var(--color-primary, #428bca);
}
</style>
