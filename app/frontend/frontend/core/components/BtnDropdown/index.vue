<template>
  <div ref="wrapper" class="panel-btn-dropdown" :class="cssClasses">
    <Btn
      :size="size"
      :variant="variant"
      :active="visible"
      :inline="true"
      :text-inline="textInline"
      :mobile-block="mobileBlock"
      @click.native="toggle"
    >
      <slot name="label">
        <i class="fas fa-ellipsis-v" />
      </slot>
    </Btn>
    <div
      ref="btnList"
      class="panel-btn-dropdown-list"
      :class="{
        visible,
        'expand-left': innerExpandLeft,
        'expand-top': innerExpandTop,
      }"
    >
      <slot />
    </div>
  </div>
</template>

<script lang="ts">
import Btn from "@/frontend/core/components/Btn/index.vue";

@Component<BtnDropdown>({
  components: {
    Btn,
  },
})
export default class BtnDropdown extends Vue {
  visible = false;

  innerExpandLeft = false;

  innerExpandTop = false;

  @Prop({
    default: "default",
    validator(value) {
      return ["default", "xsmall", "small", "large"].indexOf(value) !== -1;
    },
  })
  size!: string;

  @Prop({
    default: "default",
    validator(value) {
      return (
        ["default", "transparent", "link", "danger", "dropdown"].indexOf(
          value
        ) !== -1
      );
    },
  })
  variant!: string;

  @Prop({ default: false }) expandLeft!: boolean;

  @Prop({ default: false }) expandTop!: boolean;

  @Prop({ default: false }) mobileBlock!: boolean;

  @Prop({ default: false }) inline!: boolean;

  @Prop({ default: false }) textInline!: boolean;

  get cssClasses() {
    return {
      "panel-btn-dropdown-inline": this.inline,
    };
  }

  created() {
    document.addEventListener("click", this.documentClick);
  }

  mounted() {
    this.innerExpandLeft = this.expandLeft;
    this.innerExpandTop = this.expandTop;
  }

  destroyed() {
    document.removeEventListener("click", this.documentClick);
  }

  toggle(event: MouseEvent) {
    const { target } = event;
    const bounding = target.getBoundingClientRect();

    this.innerExpandLeft =
      this.expandLeft || window.innerWidth - bounding.left < 200;
    this.innerExpandTop =
      this.expandTop || window.innerHeight - bounding.top < 200;

    this.visible = !this.visible;
  }

  documentClick(event: MouseEvent) {
    if (!this.visible) return;

    const { wrapper, btnList } = this.$refs;
    const { target } = event;

    if (
      target !== wrapper &&
      (!wrapper.contains(target) || btnList.contains(target))
    ) {
      this.visible = false;
    }
  }
}
</script>
