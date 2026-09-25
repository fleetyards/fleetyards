import { type RouteLocationRaw } from "vue-router";
import {
  BlueprintCraftableTypeEnum,
  type BlueprintCraftable,
} from "@/services/fyApi";

const DETAIL_ROUTES: Record<string, string> = {
  [BlueprintCraftableTypeEnum.COMPONENT]: "component",
  [BlueprintCraftableTypeEnum.EQUIPMENT]: "equipment-item",
  [BlueprintCraftableTypeEnum.COMMODITY]: "commodity",
};

// Where the thing a recipe makes has its page. A few recipes resolve to no
// catalogue row at all, so that is an absent link rather than a broken one.
export const craftableRoute = (
  craftable?: BlueprintCraftable | null,
): RouteLocationRaw | undefined => {
  const name = craftable?.slug ? DETAIL_ROUTES[craftable.type] : undefined;

  return name ? { name, params: { slug: craftable!.slug } } : undefined;
};
