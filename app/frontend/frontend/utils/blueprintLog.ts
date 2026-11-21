// Star Citizen writes a HUD notification to Game.log for every blueprint a
// player receives:
//
//   <2026-11-02T18:04:11.512Z> [Notice] <SHUDEvent_OnNotification> Added
//   notification "Received Blueprint: Arbor MH1 Mining Laser: " [12] to queue.
//
// Only the name and the timestamp are read; everything else in a log -- account
// ids, other players' handles, locations -- stays on the player's machine.

export interface BlueprintReceipt {
  name: string;
  receivedAt?: string;
}

export interface BlueprintLogFile {
  channel?: string;
  receipts: BlueprintReceipt[];
}

const NOTIFICATION = "<SHUDEvent_OnNotification>";
const MARKER = "Received Blueprint: ";
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

export const parseReceiptLine = (line: string): BlueprintReceipt | null => {
  if (!line.includes(NOTIFICATION)) return null;

  const start = line.indexOf(MARKER);

  if (start === -1) return null;

  const rest = line.slice(start + MARKER.length);
  let end = rest.search(QUEUE_SUFFIX);

  if (end === -1) end = rest.lastIndexOf('"');

  const name = (end === -1 ? rest : rest.slice(0, end))
    .replace(/:\s*$/, "")
    .trim();

  if (!name || name.length > MAX_NAME_LENGTH) return null;

  const receivedAt = TIMESTAMP.exec(line)?.[1];

  return receivedAt ? { name, receivedAt } : { name };
};

export const parseReceipts = (text: string): BlueprintReceipt[] =>
  text.split(/\r?\n/).flatMap((line) => {
    const receipt = parseReceiptLine(line);

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

const readText = async (file: Blob, onLine: (line: string) => void) => {
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

export const readBlueprintLog = async (
  file: File,
): Promise<BlueprintLogFile> => {
  const channel = logChannel(await file.slice(0, HEADER_BYTES).text());

  if (!isImportableChannel(channel)) return { channel, receipts: [] };

  const receipts: BlueprintReceipt[] = [];

  await readText(file, (line) => {
    const receipt = parseReceiptLine(line);

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
