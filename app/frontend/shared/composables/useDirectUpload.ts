import { DirectUpload, type Blob } from "@rails/activestorage";

const DIRECT_UPLOAD_URL = "/files/direct_uploads";

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
        const upload = new DirectUpload(file, DIRECT_UPLOAD_URL, callbacks);

        upload.create((error: Error, blob: Blob) => {
          if (error) {
            reject(error);
          } else {
            resolve(blob);
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
