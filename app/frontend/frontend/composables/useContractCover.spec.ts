import { describe, expect, it } from "vitest";
import { useContractCover } from "./useContractCover";
import { FleetContractKindEnum } from "@/services/fyApi";

const { resolve } = useContractCover();

const contract = (kind: FleetContractKindEnum) => ({ kind }) as never;

describe("useContractCover", () => {
  // Dropping a file into images/contracts/ is meant to take precedence over the
  // mission stand-in without a code change - see that folder's README. The
  // assertion is on the filename, because the whole mechanism is the glob
  // keying `crafting.webp` to the `crafting` kind.
  it("uses the art in images/contracts for a kind that has some", () => {
    expect(resolve(contract(FleetContractKindEnum.CRAFTING), null)).toContain(
      "crafting",
    );
  });

  // The two kinds with no art of their own still resolve to the mission cover
  // that comes closest rather than to the generic placeholder.
  it("falls back to the closest mission art for a kind that has none", () => {
    const transport = resolve(contract(FleetContractKindEnum.TRANSPORT), null);
    const procurement = resolve(
      contract(FleetContractKindEnum.PROCUREMENT),
      null,
    );

    expect(transport).toContain("cargo_hauling");
    expect(procurement).toContain("other");
  });

  /*
   * The two halves of the same value. Nothing writes a default into the column
   * any more, so an unset preset is the absence of a choice and the fleet's own
   * cover answers -- while a stored one is a picture somebody picked, even when
   * it names this contract's own kind, which is a tile the picker offers.
   */
  it("lets the fleet's cover answer when nothing was chosen", () => {
    const fleet = {
      contractCovers: { crafting: { mediumUrl: "/uploads/own-cover.webp" } },
    } as never;
    const unchosen = {
      kind: FleetContractKindEnum.CRAFTING,
      coverImagePreset: null,
    } as never;

    expect(resolve(unchosen, fleet)).toBe("/uploads/own-cover.webp");
  });

  it("keeps a preset naming the contract's own kind", () => {
    const fleet = {
      contractCovers: { crafting: { mediumUrl: "/uploads/own-cover.webp" } },
    } as never;
    const chosen = {
      kind: FleetContractKindEnum.CRAFTING,
      coverImagePreset: "crafting",
    } as never;

    expect(resolve(chosen, fleet)).toContain("crafting");
    expect(resolve(chosen, fleet)).not.toBe("/uploads/own-cover.webp");
  });

  it("keeps a preset naming another kind", () => {
    const fleet = {
      contractCovers: { transport: { mediumUrl: "/uploads/own-cover.webp" } },
    } as never;
    const crossKind = {
      kind: FleetContractKindEnum.TRANSPORT,
      coverImagePreset: "crafting",
    } as never;

    expect(resolve(crossKind, fleet)).toContain("crafting");
  });

  // A fleet that uploaded its own cover sees that, not the built-in one.
  it("prefers the fleet's own upload over everything", () => {
    const fleet = {
      contractCovers: { crafting: { mediumUrl: "/uploads/own-cover.webp" } },
    } as never;

    expect(resolve(contract(FleetContractKindEnum.CRAFTING), fleet)).toBe(
      "/uploads/own-cover.webp",
    );
  });

  it("falls back to the placeholder without a contract", () => {
    expect(resolve(null, null)).toContain("store_image");
  });
});
