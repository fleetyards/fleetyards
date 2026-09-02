export type CsvCell = string | number | boolean | null | undefined;

export type CsvRow = CsvCell[];

export type CsvSection = {
  headers: CsvRow;
  rows: CsvRow[];
};

// Semicolons and tabs are not delimiters here, but a spreadsheet opening the
// file may treat them as such depending on its locale, so they get quoted too.
const NEEDS_QUOTING = /["\n\r,;\t]/;

// A cell opening with one of these is read as a formula rather than as text by
// Excel and Sheets. Labels reach this file from fleet role names and ship names,
// so they are not ours to trust; prefixing an apostrophe keeps them inert.
const FORMULA_PREFIXES = ["=", "+", "-", "@"];

const escape = (value: CsvCell): string => {
  if (value === null || value === undefined) {
    return "";
  }

  // Numbers and booleans cannot carry a formula or a delimiter, and a negative
  // number must not pick up the apostrophe the guard below would add.
  if (typeof value !== "string") {
    return String(value);
  }

  const text = FORMULA_PREFIXES.some((prefix) => value.startsWith(prefix))
    ? `'${value}`
    : value;

  if (!NEEDS_QUOTING.test(text)) {
    return text;
  }

  return `"${text.replaceAll('"', '""')}"`;
};

export const csvRow = (row: CsvRow): string => row.map(escape).join(",");

// CRLF per RFC 4180 - the one line ending every spreadsheet agrees on.
export const toCsv = (rows: CsvRow[]): string => rows.map(csvRow).join("\r\n");

/*
 * Several two-column tables in one file, separated by a blank line. A section
 * names itself in its own header row rather than in a title line of its own, so
 * every row in the file has the same shape and a spreadsheet reads the whole
 * thing as one sheet instead of guessing at a ragged first column.
 *
 * Empty sections are dropped: a header with nothing under it reads as data that
 * failed to load rather than as a chart that has none.
 */
export const sectionsToCsv = (sections: CsvSection[]): string =>
  sections
    .filter((section) => section.rows.length)
    .map((section) => toCsv([section.headers, ...section.rows]))
    .join("\r\n\r\n");
