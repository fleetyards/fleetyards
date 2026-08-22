// A dropped folder arrives as a directory entry rather than as files, so it has
// to be walked. `dataTransfer.items` is only readable while the drop event is
// being handled, which is why every entry is taken up front and traversed after.
const readFile = (entry: FileSystemFileEntry): Promise<File> =>
  new Promise((resolve, reject) => entry.file(resolve, reject));

const readEntries = (
  reader: FileSystemDirectoryReader,
): Promise<FileSystemEntry[]> =>
  new Promise((resolve, reject) => reader.readEntries(resolve, reject));

// readEntries hands back a batch at a time and signals the end with an empty
// one, so a folder has to be read until it runs dry.
const readDirectory = async (
  entry: FileSystemDirectoryEntry,
): Promise<FileSystemEntry[]> => {
  const reader = entry.createReader();
  const entries: FileSystemEntry[] = [];

  let batch = await readEntries(reader);

  while (batch.length) {
    entries.push(...batch);
    batch = await readEntries(reader);
  }

  return entries;
};

export const filesFromEntry = async (
  entry: FileSystemEntry,
): Promise<File[]> => {
  if (entry.isFile) {
    return [await readFile(entry as FileSystemFileEntry)];
  }

  if (!entry.isDirectory) {
    return [];
  }

  const entries = await readDirectory(entry as FileSystemDirectoryEntry);
  const files = await Promise.all(entries.map(filesFromEntry));

  return files.flat();
};

export const filesFromDataTransfer = async (
  dataTransfer: DataTransfer,
): Promise<File[]> => {
  const entries = Array.from(dataTransfer.items)
    .map((item) => item.webkitGetAsEntry())
    .filter((entry): entry is FileSystemEntry => !!entry);

  if (!entries.length) {
    return Array.from(dataTransfer.files);
  }

  const files = await Promise.all(entries.map(filesFromEntry));

  return files.flat();
};
