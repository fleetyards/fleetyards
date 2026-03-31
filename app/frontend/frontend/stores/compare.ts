import { defineStore } from "pinia";

type CompareState = {
  hiddenCategories: string[];
  modelsLengths: Record<string, number>;
};

export const useCompareStore = defineStore("compare", {
  state: (): CompareState => ({
    hiddenCategories: [],
    modelsLengths: {},
  }),
  getters: {
    modelsMaxLength: (state) => {
      return Math.max(...Object.values(state.modelsLengths), 0);
    },
  },
  actions: {
    toggleCategory(category: string) {
      if (this.hiddenCategories.includes(category)) {
        this.hiddenCategories = this.hiddenCategories.filter(
          (c) => c !== category,
        );
      } else {
        this.hiddenCategories.push(category);
      }
    },
    addModelsLength(slug: string, length: number) {
      this.modelsLengths[slug] = length;
    },
    removeModelsLength(slug: string) {
      delete this.modelsLengths[slug];
    },
  },
});
