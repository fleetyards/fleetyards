import { DirectUpload, type Blob } from "@rails/activestorage";
import { fileTypeOf } from "@/shared/components/DirectUpload/types";

const DIRECT_UPLOAD_URL = "/files/direct_uploads";

// The blob is stored under the type the browser reports, and the public bucket
// serves the file under it. A model file goes up under the type its extension
// stands for instead -- AR Quick Look opens a USDZ only under its own.
const withType = (file: File) => {
  const type = fileTypeOf(file);

  return type === file.type
    ? file
    : new File([file], file.name, { type, lastModified: file.lastModified });
};

export const useDirectUpload = () => {
  const uploadFile = (
    file: File,
    {
      progressHandler,
    }: {
      progressHandler: (progress: number) => void;
    },
  ) => {
    const callbacks = {
      directUploadWillStoreFileWithXHR(xhr: XMLHttpRequest) {
        xhr.setRequestHeader("x-amz-acl", "public-read");
        xhr.upload.addEventListener("progress", (event) =>
          progressHandler((event.loaded / event.total) * 100),
        );
      },
    };

    const promise = new Promise<Blob>((resolve, reject) => {
      try {
        const upload = new DirectUpload(
          withType(file),
          DIRECT_UPLOAD_URL,
          callbacks,
        );

        upload.create((error: string | null, blob?: Blob) => {
          if (error) {
            reject(new Error(error));
          } else if (blob) {
            resolve(blob);
          } else {
            reject(new Error("DirectUpload failed: no blob returned"));
          }
        });
      } catch (error: unknown) {
        console.error(error);
        reject(error);
      }
    });

    return promise;
  };

  return {
    uploadFile,
  };
};
