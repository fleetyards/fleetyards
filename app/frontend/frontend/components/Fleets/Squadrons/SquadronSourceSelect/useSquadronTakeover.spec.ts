import { describe, expect, it } from "vitest";
import type { FleetSquadron } from "@/services/fyApi";
import { useSquadronTakeover } from "./useSquadronTakeover";

const alpha = {
  id: "a",
  name: "Alpha",
  shortDescription: "Interceptors",
} as FleetSquadron;

const bravo = {
  id: "b",
  name: "Bravo",
  shortDescription: "Bombers",
} as FleetSquadron;

const setup = (initialTitle = "", initialDescription = "") => {
  const title = ref(initialTitle);
  const description = ref(initialDescription);

  return { title, description, pick: useSquadronTakeover(title, description) };
};

describe("useSquadronTakeover", () => {
  it("fills an empty title and description", () => {
    const { title, description, pick } = setup();

    pick(alpha);

    expect(title.value).toBe("Alpha");
    expect(description.value).toBe("Interceptors");
  });

  it("replaces what the previous squadron filled in", () => {
    const { title, description, pick } = setup("Alpha", "Interceptors");

    pick(bravo, alpha);

    expect(title.value).toBe("Bravo");
    expect(description.value).toBe("Bombers");
  });

  it("keeps what somebody typed", () => {
    const { title, description, pick } = setup("Escort", "Stay close");

    pick(bravo, alpha);

    expect(title.value).toBe("Escort");
    expect(description.value).toBe("Stay close");
  });
});
