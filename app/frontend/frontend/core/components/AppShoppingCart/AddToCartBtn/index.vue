<template>
  <Btn
    v-tooltip="$t('actions.shoppingCart.add')"
    class="add-to-cart"
    variant="link"
    @click.native="addToCart({ item, type })"
  >
    <i class="fal fa-cart-plus" />
  </Btn>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Prop } from "vue-property-decorator";
import { Getter, Action } from "vuex-class";
import Btn from "@/frontend/core/components/Btn/index.vue";

@Component<AddToCartBtn>({
  components: {
    Btn,
  },
})
export default class AddToCartBtn extends Vue {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  @Prop({ required: true }) item!: any;

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  @Prop({ required: true }) type!: any;

  @Getter("mobile") mobile: boolean;

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  @Action("add", { namespace: "shoppingCart" }) addToCart: any;
}
</script>

<style lang="scss" scoped>
@import "index";
</style>
