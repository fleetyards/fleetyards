import { defineStore } from "pinia";
import type { OutfitHoloModel } from "@/frontend/utils/dressingRoom";

// The default outfit's avatars being drawn. Held above the page so a drawing
// started in the dressing room still finishes after the user moves on.
export const useCharacterAvatarsStore = defineStore("characterAvatars", () => {
  const models = shallowRef<OutfitHoloModel[]>();
  const run = ref(0);

  const drawing = computed(() => !!models.value);

  const draw = (next: OutfitHoloModel[]) => {
    if (models.value) return;

    run.value += 1;
    models.value = next;
  };

  const finish = () => {
    models.value = undefined;
  };

  return { models, run, drawing, draw, finish };
});
