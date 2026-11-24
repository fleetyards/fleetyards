import { describe, expect, it } from "vitest";
import { nameKeysFor, readBlueprintTranslations } from "./blueprintTranslation";

const ini = (...lines: string[]) => new Blob([lines.join("\r\n")]);

describe("readBlueprintTranslations", () => {
  it("reads how a blueprint is announced", async () => {
    const { markers } = await readBlueprintTranslations([
      ini(
        "\uFEFFfoo=bar",
        "crafting_hud_notification_received_blueprint,P=<EM4>[BP]</EM4> Plano recibido: %s",
      ),
    ]);

    expect(markers).toEqual(["[BP] Plano recibido:"]);
  });

  it("takes no marker from an announcement that does not lead into a name", async () => {
    const { markers } = await readBlueprintTranslations([
      ini("crafting_hud_notification_received_blueprint,P=%s"),
      ini("crafting_hud_notification_received_blueprint=Plano"),
    ]);

    expect(markers).toEqual([]);
  });
});

describe("nameKeysFor", () => {
  it("finds every key a name is written for, across files", async () => {
    const translation = await readBlueprintTranslations([
      ini("item_Name_a,P=Casco  Argus", "item_Desc_a=Un casco", "ui_x=Otro"),
      ini("item_Nameb=<EM4>Casco</EM4> 'Argus'"),
    ]);

    expect(nameKeysFor(["casco argus", "Nada", "Otro"], translation)).toEqual([
      { name: "casco argus", keys: ["item_name_a", "item_nameb"] },
    ]);
  });
});
