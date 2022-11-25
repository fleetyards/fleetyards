<template>
  <BCollapse :visible="visible" class="panel-details">
    <slot />
  </BCollapse>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Prop } from "vue-property-decorator";
import { BCollapse } from "bootstrap-vue";

@Component<PanelDetails>({
  components: {
    BCollapse,
  },
})
export default class PanelDetails extends Vue {
  @Prop({ default: false }) visible!: boolean;
}
</script>
