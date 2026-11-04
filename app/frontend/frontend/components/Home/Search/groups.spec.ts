import { describe, expect, it } from "vitest";
import { createMemoryHistory, createRouter } from "vue-router";
import { routes } from "@/frontend/pages/routes";
import { SEARCH_GROUPS } from "./groups";

describe("SEARCH_GROUPS", () => {
  const router = createRouter({ history: createMemoryHistory(), routes });

  it.each(Object.entries(SEARCH_GROUPS))(
    "%s names routes that exist",
    (_, group) => {
      [group.list.name, ...group.listPages].forEach((name) => {
        expect(router.hasRoute(name)).toBe(true);
      });
    },
  );
});
