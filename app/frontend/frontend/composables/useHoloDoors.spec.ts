import { describe, expect, it } from "vitest";
import { nextTick, ref } from "vue";
import { useHoloDoors } from "./useHoloDoors";

describe("useHoloDoors", () => {
  const doors = ref([{ id: "rear" }, { id: "side" }]);

  it("opens and closes every door with the switch", async () => {
    const allOpen = ref(false);
    const { openDoors } = useHoloDoors(doors, allOpen);

    expect(openDoors.value).toEqual([]);

    allOpen.value = true;
    await nextTick();

    expect(openDoors.value).toEqual(["rear", "side"]);
  });

  it("turns one door the other way until the switch moves", async () => {
    const allOpen = ref(false);
    const { openDoors, isOpen, toggleDoor } = useHoloDoors(doors, allOpen);

    toggleDoor("side");
    expect(isOpen("side")).toBe(true);
    expect(openDoors.value).toEqual(["side"]);

    toggleDoor("side");
    expect(isOpen("side")).toBe(false);

    toggleDoor("rear");
    allOpen.value = true;
    await nextTick();
    allOpen.value = false;
    await nextTick();

    expect(openDoors.value).toEqual([]);
  });
});
