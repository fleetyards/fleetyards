<template>
  <Btn
    :key="`add-to-hangar-${model.slug}`"
    v-tooltip.bottom="$t('actions.addToHangar')"
    :variant="btnVariant"
    :size="btnSize"
    :inline="variant === 'menu'"
    data-test="add-to-hangar"
    @click.native="add"
  >
    <span v-show="inHangar || onWishlist">
      <i class="fa fa-bookmark" />
    </span>
    <span v-show="!inHangar && !onWishlist">
      <i class="fal fa-bookmark" />
    </span>
  </Btn>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Prop } from "vue-property-decorator";
import { Getter } from "vuex-class";
import Btn from "@/frontend/core/components/Btn/index.vue";
import { displayWarning } from "@/frontend/lib/Noty";

@Component<AddToHangar>({
  components: {
    Btn,
  },
})
export default class AddToHangar extends Vue {
  @Prop({ required: true }) model: Model;

  @Prop({
    default: "default",
    validator(value) {
      return ["default", "panel", "menu"].includes(value);
    },
  })
  variant: string;

  @Getter("isAuthenticated", { namespace: "session" }) isAuthenticated;

  @Getter("ships", { namespace: "hangar" }) ships;

  @Getter("ships", { namespace: "wishlist" }) wishlistShips;

  get inHangar() {
    return !!(this.ships || []).find((item) => item === this.model.slug);
  }

  get onWishlist() {
    return !!(this.wishlistShips || []).find(
      (item) => item === this.model.slug,
    );
  }

  get btnVariant() {
    if (["panel", "menu"].includes(this.variant)) {
      return "link";
    }

    return "default";
  }

  get btnSize() {
    if (["panel", "menu"].includes(this.variant)) {
      return "small";
    }

    return "default";
  }

  async add() {
    if (!this.isAuthenticated) {
      displayWarning({
        text: this.$t("messages.error.hangar.accountRequired"),
      });
      return;
    }

    this.$comlink.$emit("open-modal", {
      component: () =>
        import("@/frontend/components/Models/AddToHangarModal/index.vue"),
      props: {
        model: this.model,
      },
    });
  }
}
</script>
