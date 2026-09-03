<script lang="ts">
export default {
  name: "CargoGridsModelsPickerModal",
};
</script>

<script lang="ts" setup>
import PickerModal from "@/frontend/components/Models/PickerModal/index.vue";
import { type ModelPickerSelection } from "@/frontend/components/Models/PickerModal/types";
import {
  ModelProductionStatusEnum,
  type ContainerFitQuery,
} from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  // The grid already holds these; the picker shows them, marked, unpickable.
  taken: string[];
  max: number;
  // The load the picker's container filter starts on. The page keeps its own
  // counts either way - what happens here only decides which ships are offered.
  containerFit?: ContainerFitQuery;
};

const props = withDefaults(defineProps<Props>(), {
  containerFit: undefined,
});

const { t } = useI18n();

const comlink = useComlink();

// Only flight-ready ships, and only ones with a grid to draw: the tool has
// nothing to show for a concept, and nothing at all for a hold the game files do
// not describe.
const query = {
  withCargoGrids: true,
  productionStatusIn: [ModelProductionStatusEnum.FLIGHT_READY],
};

const submit = (selection: ModelPickerSelection[]) => {
  comlink.emit(
    "cargo-grids-models-picked",
    selection.map(({ option }) => option.slug),
  );

  comlink.emit("close-modal");
};
</script>

<template>
  <PickerModal
    :title="t('modelPicker.cargoGridsTitle')"
    :submit-label="t('actions.cargoGrids.addShips')"
    :max="props.max - props.taken.length"
    :max-hint="t('labels.cargoGridViewer.enoughShips')"
    :taken-slugs="props.taken"
    :taken-note="t('modelPicker.badges.onCargoGrid')"
    :query="query"
    :container-fit="props.containerFit"
    container-filter
    hangar-filter
    @submit="submit"
  />
</template>
