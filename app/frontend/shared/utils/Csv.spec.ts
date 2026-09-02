import { describe, expect, it } from "vitest";

import { csvRow, sectionsToCsv, toCsv } from "./Csv";

describe("csvRow", () => {
  it("joins plain cells with commas", () => {
    expect(csvRow(["Aurora", 12])).toBe("Aurora,12");
  });

  it("writes an empty cell for null and undefined", () => {
    expect(csvRow([null, undefined, 0])).toBe(",,0");
  });

  it("keeps booleans and negative numbers as they are", () => {
    expect(csvRow([true, false, -4, -0.5])).toBe("true,false,-4,-0.5");
  });

  it("quotes a cell carrying a delimiter", () => {
    expect(csvRow(["Drake, Interplanetary", 1])).toBe(
      '"Drake, Interplanetary",1',
    );
    expect(csvRow(["a;b"])).toBe('"a;b"');
    expect(csvRow(["a\tb"])).toBe('"a\tb"');
  });

  it("quotes a cell carrying a line break", () => {
    expect(csvRow(["two\nlines"])).toBe('"two\nlines"');
    expect(csvRow(["two\r\nlines"])).toBe('"two\r\nlines"');
  });

  it("doubles an embedded quote and quotes the cell", () => {
    expect(csvRow(['the "Best" ship'])).toBe('"the ""Best"" ship"');
  });

  it("neutralizes a cell a spreadsheet would read as a formula", () => {
    expect(csvRow(["=1+1"])).toBe("'=1+1");
    expect(csvRow(["+SUM(A1)"])).toBe("'+SUM(A1)");
    expect(csvRow(["-2+3"])).toBe("'-2+3");
    expect(csvRow(["@role"])).toBe("'@role");
  });

  it("quotes a neutralized cell that also carries a delimiter", () => {
    expect(csvRow(['=HYPERLINK("a","b")'])).toBe('"\'=HYPERLINK(""a"",""b"")"');
  });
});

describe("toCsv", () => {
  it("separates rows with CRLF", () => {
    expect(
      toCsv([
        ["a", "b"],
        [1, 2],
      ]),
    ).toBe("a,b\r\n1,2");
  });

  it("is empty for no rows", () => {
    expect(toCsv([])).toBe("");
  });
});

describe("sectionsToCsv", () => {
  it("puts a blank line between sections", () => {
    const csv = sectionsToCsv([
      { headers: ["Metric", "Value"], rows: [["Total Ships", 3]] },
      {
        headers: ["Ships by Size", "Count"],
        rows: [
          ["large", 2],
          ["small", 1],
        ],
      },
    ]);

    expect(csv).toBe(
      [
        "Metric,Value",
        "Total Ships,3",
        "",
        "Ships by Size,Count",
        "large,2",
        "small,1",
      ].join("\r\n"),
    );
  });

  it("drops a section with no rows rather than leaving a bare header", () => {
    const csv = sectionsToCsv([
      { headers: ["Metric", "Value"], rows: [["Total Ships", 3]] },
      { headers: ["Ships by Size", "Count"], rows: [] },
    ]);

    expect(csv).toBe("Metric,Value\r\nTotal Ships,3");
  });

  it("is empty when every section is empty", () => {
    expect(sectionsToCsv([{ headers: ["a", "b"], rows: [] }])).toBe("");
  });
});
