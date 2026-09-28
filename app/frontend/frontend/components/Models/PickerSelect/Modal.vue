<script lang="ts">
export default {
  name: "ModelPickerSelectModal",
};
</script>

<script lang="ts" setup>
import PickerModal from "@/frontend/components/Models/PickerModal/index.vue";
import { type ModelPickerSelection } from "@/frontend/components/Models/PickerModal/types";
import { type ModelQuery } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  // Which select opened it: several can sit on one page.
  pickerId: string;
  title: string;
  query?: ModelQuery;
};

const props = withDefaults(defineProps<Props>(), {
  query: undefined,
});

const comlink = useComlink();

const submit = (selection: ModelPickerSelection[]) => {
  const [picked] = selection;
  if (picked) {
    comlink.emit("model-picker-select-picked", {
      pickerId: props.pickerId,
      slug: picked.option.slug,
    });
  }

  comlink.emit("close-modal");
};
</script>

<template>
  <PickerModal
    :title="title"
    :submit-label="title"
    :query="query"
    hangar-filter
    single
    @submit="submit"
  />
</template>
