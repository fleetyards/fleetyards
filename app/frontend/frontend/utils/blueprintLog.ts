// Star Citizen writes a HUD notification to Game.log for every blueprint a
// player receives:
//
//   <2026-11-02T18:04:11.512Z> [Notice] <SHUDEvent_OnNotification> Added
//   notification "Received Blueprint: Arbor MH1 Mining Laser: " [12] to queue.
//
// The text is the game's own localisation, so a translated game logs it in that
// language. Only the name and the timestamp are read; everything else in a log -- account
// ids, other players' handles, locations -- stays on the player's machine.

export interface BlueprintReceipt {
  name: string;
  receivedAt?: string;
  // Announced in another language than the game's own English.
  translated?: boolean;
}

export interface BlueprintLogFile {
  channel?: string;
  receipts: BlueprintReceipt[];
}

const NOTIFICATION = "<SHUDEvent_OnNotification>";
const NOTIFICATION_TEXT = /Added notification "(.*)$/;
const ENGLISH_MARKER = "Received Blueprint:";

// What the community translations write in its place, for logs read without
// the translation's own global.ini.
const TRANSLATED_MARKERS = [
  "Plano Recibido:",
  "Planimetría Recibida:",
  "Plan Reçu :",
  "Progetto Ricevuto:",
  "Blueprint Recebido:",
  "획득한 설계도:",
];

const DEFAULT_MARKERS = [ENGLISH_MARKER, ...TRANSLATED_MARKERS];

// Text styling such as `<EM4>[BP]</EM4>`, which translations add to names too.
const MARKUP = /<\/?EM\d*>/gi;
const TIMESTAMP = /^<([^>]+)>/;
const QUEUE_SUFFIX = /"\s*\[\d+\]\s*to queue/;

// PTU and tech-preview blueprints are wiped with their environment, so only
// the persistent universe's own logs are imported.
export const IMPORTABLE_CHANNELS = ["LIVE", "HOTFIX"];

// The executable line follows a preamble of system details whose length
// varies by machine, so the header is read generously.
const HEADER_BYTES = 65536;

// What the API accepts; a truncated line from a crashed session would
// otherwise run to the end of the line and fail the whole request.
export const MAX_NAME_LENGTH = 255;
export const MAX_NAMES = 5000;

export const plainText = (text: string) =>
  text.replace(MARKUP, "").normalize("NFC").replace(/\s+/g, " ").trim();

// Lowercasing can change a string's length, so a marker is found by a pattern
// on the original text rather than by an offset into a lowercased copy.
const escapePattern = (text: string) =>
  text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

const markerPattern = (markers: string[]) =>
  new RegExp(markers.map(escapePattern).join("|"), "iu");

const ENGLISH_PATTERN = markerPattern([ENGLISH_MARKER]);
const DEFAULT_PATTERN = markerPattern(DEFAULT_MARKERS);

export const receiptPattern = (markers: string[]) =>
  markers.length
    ? markerPattern([...markers, ...DEFAULT_MARKERS])
    : DEFAULT_PATTERN;

export const parseReceiptLine = (
  line: string,
  pattern = DEFAULT_PATTERN,
): BlueprintReceipt | null => {
  if (!line.includes(NOTIFICATION)) return null;

  const raw = NOTIFICATION_TEXT.exec(line)?.[1];

  if (!raw) return null;

  const text = plainText(raw);
  const marker = pattern.exec(text);

  if (!marker) return null;

  const rest = text.slice(marker.index + marker[0].length);
  let end = rest.search(QUEUE_SUFFIX);

  if (end === -1) end = rest.lastIndexOf('"');

  const name = (end === -1 ? rest : rest.slice(0, end))
    .replace(/:\s*$/, "")
    .trim();

  if (!name || name.length > MAX_NAME_LENGTH) return null;

  const receivedAt = TIMESTAMP.exec(line)?.[1];

  return {
    name,
    ...(receivedAt && { receivedAt }),
    ...(!ENGLISH_PATTERN.test(marker[0]) && { translated: true }),
  };
};

export const parseReceipts = (
  text: string,
  pattern?: RegExp,
): BlueprintReceipt[] =>
  text.split(/\r?\n/).flatMap((line) => {
    const receipt = parseReceiptLine(line, pattern);

    return receipt ? [receipt] : [];
  });

// The header names the executable the log was written by, and the folder above
// Bin64 is the environment: `...\StarCitizen\LIVE\Bin64\StarCitizen.exe`.
export const logChannel = (header: string): string | undefined => {
  const line = header
    .split(/\r?\n/)
    .find((candidate) => candidate.includes("Executable: "));

  if (!line) return undefined;

  const path = line.slice(line.indexOf("Executable: ") + 12).trim();
  const segments = path.split(/[\\/]+/).filter(Boolean);
  const bin = segments.findIndex(
    (segment) => segment.toUpperCase() === "BIN64",
  );

  return bin < 1 ? undefined : segments[bin - 1].toUpperCase();
};

// A log without a readable header is still read: it cannot be told apart from
// a LIVE one, and a log that is not the game's carries no notifications.
export const isImportableChannel = (channel?: string) =>
  !channel || IMPORTABLE_CHANNELS.includes(channel);

export const isLogFile = (file: File) =>
  file.name.toLowerCase().endsWith(".log");

export const isTranslationFile = (file: File) =>
  file.name.toLowerCase() === "global.ini";

export const readText = async (file: Blob, onLine: (line: string) => void) => {
  if (
    typeof file.stream !== "function" ||
    typeof TextDecoderStream === "undefined"
  ) {
    (await file.text()).split(/\r?\n/).forEach(onLine);
    return;
  }

  // Streamed: a session's log runs to tens of megabytes and logbackups holds
  // every one the game kept.
  const reader = file.stream().pipeThrough(new TextDecoderStream()).getReader();
  let buffer = "";

  for (;;) {
    const { done, value } = await reader.read();

    if (done) break;

    buffer += value;

    const lines = buffer.split(/\r?\n/);

    buffer = lines.pop() ?? "";
    lines.forEach(onLine);
  }

  if (buffer) onLine(buffer);
};

export const readLogChannel = async (file: Blob) =>
  logChannel(await file.slice(0, HEADER_BYTES).text());

export const readBlueprintLog = async (
  file: File,
  pattern?: RegExp,
): Promise<BlueprintLogFile> => {
  const channel = await readLogChannel(file);

  if (!isImportableChannel(channel)) return { channel, receipts: [] };

  const receipts: BlueprintReceipt[] = [];

  await readText(file, (line) => {
    const receipt = parseReceiptLine(line, pattern);

    if (receipt) receipts.push(receipt);
  });

  return { channel, receipts };
};

// Every name once, case-insensitively, as first received.
export const uniqueNames = (receipts: BlueprintReceipt[]): string[] => {
  const seen = new Map<string, string>();

  receipts.forEach(({ name }) => {
    const key = name.toLowerCase();

    if (!seen.has(key)) seen.set(key, name);
  });

  return [...seen.values()].slice(0, MAX_NAMES);
};
