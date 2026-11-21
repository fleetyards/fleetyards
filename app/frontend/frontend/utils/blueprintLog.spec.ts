import { describe, expect, it } from "vitest";
import {
  isImportableChannel,
  logChannel,
  parseReceiptLine,
  parseReceipts,
  readBlueprintLog,
  uniqueNames,
} from "./blueprintLog";

const receiptLine = (name: string, at = "2026-11-02T18:04:11.512Z") =>
  `<${at}> [Notice] <SHUDEvent_OnNotification> Added notification "Received Blueprint: ${name}: " [12] to queue. New queue size: 1, MissionId: [00000000-0000-0000-0000-000000000000], ObjectiveId: [] [Team_CoreGameplayFeatures][Missions][Comms]`;

const header = (environment: string) =>
  [
    "Log started on Sun Nov  2 18:00:00 2026",
    "Build(10234567) 02 Nov 26 (10:12:41)",
    `Executable: C:\\Program Files\\Roberts Space Industries\\StarCitizen\\${environment}\\Bin64\\StarCitizen.exe`,
  ].join("\r\n");

describe("parseReceiptLine", () => {
  it("reads the name and timestamp of a received blueprint", () => {
    expect(parseReceiptLine(receiptLine("Arbor MH1 Mining Laser"))).toEqual({
      name: "Arbor MH1 Mining Laser",
      receivedAt: "2026-11-02T18:04:11.512Z",
    });
  });

  it("keeps quotes and colons inside the name", () => {
    expect(
      parseReceiptLine(receiptLine('Custodian "Desert Shadow" SMG'))?.name,
    ).toBe('Custodian "Desert Shadow" SMG');
    expect(parseReceiptLine(receiptLine("5CA 'Akura'"))?.name).toBe(
      "5CA 'Akura'",
    );
  });

  it("ignores other notifications", () => {
    expect(
      parseReceiptLine(
        '<2026-11-02T18:04:11.512Z> [Notice] <SHUDEvent_OnNotification> Added notification "Contract Accepted: Salvage" [3] to queue.',
      ),
    ).toBeNull();
  });

  it("ignores the name outside a notification", () => {
    expect(
      parseReceiptLine("<x> [Notice] chat: Received Blueprint: Fake: "),
    ).toBeNull();
  });
});

describe("parseReceipts", () => {
  it("finds every receipt across CRLF lines", () => {
    const text = [
      header("LIVE"),
      receiptLine("Aspis"),
      "<x> [Notice] <Something else>",
      receiptLine("IceDive"),
    ].join("\r\n");

    expect(parseReceipts(text).map(({ name }) => name)).toEqual([
      "Aspis",
      "IceDive",
    ]);
  });
});

describe("logChannel", () => {
  it("reads the environment folder above Bin64", () => {
    expect(logChannel(header("LIVE"))).toBe("LIVE");
    expect(logChannel(header("ptu"))).toBe("PTU");
  });

  it("knows nothing without an executable line", () => {
    expect(logChannel("Log started")).toBeUndefined();
  });
});

describe("isImportableChannel", () => {
  it("imports LIVE, HOTFIX and logs it cannot place, but not PTU", () => {
    expect(isImportableChannel("LIVE")).toBe(true);
    expect(isImportableChannel("HOTFIX")).toBe(true);
    expect(isImportableChannel(undefined)).toBe(true);
    expect(isImportableChannel("PTU")).toBe(false);
    expect(isImportableChannel("EPTU")).toBe(false);
  });
});

describe("readBlueprintLog", () => {
  it("reads the receipts of a LIVE log", async () => {
    const file = new File(
      [
        [header("LIVE"), receiptLine("Aspis"), receiptLine("Aither")].join(
          "\n",
        ),
      ],
      "Game.log",
    );

    const result = await readBlueprintLog(file);

    expect(result.channel).toBe("LIVE");
    expect(result.receipts.map(({ name }) => name)).toEqual([
      "Aspis",
      "Aither",
    ]);
  });

  it("skips a PTU log", async () => {
    const file = new File(
      [[header("PTU"), receiptLine("Aspis")].join("\n")],
      "Game.log",
    );

    expect(await readBlueprintLog(file)).toEqual({
      channel: "PTU",
      receipts: [],
    });
  });
});

describe("uniqueNames", () => {
  it("lists each name once, as first received", () => {
    expect(
      uniqueNames([{ name: "Aspis" }, { name: "IceDive" }, { name: "aspis" }]),
    ).toEqual(["Aspis", "IceDive"]);
  });
});
