import { DirectUpload, type Blob } from "@rails/activestorage";

const DIRECT_UPLOAD_URL = "/files/direct_uploads";

// eslint-disable-next-line
export function useDirectUpload() {
  async function uploadFile(
    file: File,
    {
      errorHandler,
      successHandler,
      progressHandler,
    }: {
      errorHandler: (error: unknown) => void;
      successHandler: (blob: Blob) => void;
      progressHandler: (progress: number) => void;
    },
  ): Promise<void> {
    const callbacks = {
      directUploadWillStoreFileWithXHR(xhr: XMLHttpRequest) {
        xhr.setRequestHeader("x-amz-acl", "public-read");
        xhr.upload.addEventListener("progress", (event) =>
          progressHandler((event.loaded / event.total) * 100),
        );
      },
    };

    try {
      const upload = new DirectUpload(file, DIRECT_UPLOAD_URL, callbacks);

      upload.create((error: Error, blob: Blob) => {
        if (error) {
          errorHandler(error);
        } else {
          successHandler(blob);
        }
      });
    } catch (error: unknown) {
      console.error(error);
      errorHandler(error);
    }
  }

  return {
    uploadFile,
  };
}
