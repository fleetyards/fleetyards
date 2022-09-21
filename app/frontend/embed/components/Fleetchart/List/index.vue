<template>
  <div>
    <div v-if="slider" class="row justify-content-lg-center">
      <div class="col-12 col-lg-4">
        <FleetchartSlider
          :initial-scale="fleetchartScale"
          @change="updateFleetchartScale"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 fleetchart-wrapper">
        <transition-group
          id="fleetchart"
          name="fade-list"
          class="row fleetchart"
          tag="div"
          :appear="true"
        >
          <FleetchartItem
            v-for="(model, index) in internalModels"
            :key="`fleetchart-item-${index}-${model.slug}`"
            :model="model"
            :scale="fleetchartScale"
          />
        </transition-group>
      </div>
    </div>
  </div>
</template>

<script>
import FleetchartSlider from "@/embed/components/Fleetchart/Slider/index.vue";
import FleetchartItem from "@/embed/components/Fleetchart/Item/index.vue";
import { mapGetters } from "vuex";

export default {
  name: "FleetchartList",

  components: {
    FleetchartSlider,
    FleetchartItem,
  },

  props: {
    models: {
      type: Array,
      required: true,
    },

    slider: {
      type: Boolean,
      default: true,
    },
  },

  data() {
    return {
      internalModels: [],
    };
  },

  computed: {
    ...mapGetters(["grouping", "fleetchartScale", "fleetchartGrouping"]),
  },

  watch: {
    models() {
      this.internalModels = [...this.models];
      this.internalModels.sort(this.sortByFleetchartLength);
    },
  },

  mounted() {
    this.internalModels = [...this.models];
    this.internalModels.sort(this.sortByFleetchartLength);
  },

  methods: {
    updateFleetchartScale(value) {
      this.$store.commit("setFleetchartScale", value);
    },

    sortByFleetchartLength(a, b) {
      if (a.fleetchartLength > b.fleetchartLength) {
        return -1;
      }

      if (a.fleetchartLength < b.fleetchartLength) {
        return 1;
      }

      return 0;
    },
  },
};
</script>
