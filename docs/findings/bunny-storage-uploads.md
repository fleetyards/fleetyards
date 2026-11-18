# Uploads on Bunny Storage

**Date:** 2026-11-17 / 18 (research and the move from Hetzner Object Storage, #6378)

ActiveStorage's `cloud` service moves from the Hetzner FSN1 bucket to a Bunny Storage zone with S3 compatibility (`fltyrd-<env>-uploads`), reached through an ActiveStorage mirror. This note records what Bunny's S3 API does and does not do, how the mirror behaves, and the measurements behind the choice. Read it before changing `config/storage.yml`, the storage pull zone, or `Overlay::Publisher`.

## Bunny's S3 API

- S3 compatibility can only be enabled when a zone is created (`StorageZoneType: 1` in the API, `type = "S3"` in the bunnynet Terraform provider). An existing zone cannot be converted.
- Credentials are the zone name (access key) and the zone password (secret). Endpoint `https://de-s3.storage.bunnycdn.com`, region `de`.
- Works with the stock `ActiveStorage::Service::S3Service`: upload with the `public-read` ACL (the header is accepted), checksum rejection, presigned direct uploads, ranged and streamed downloads, stored Content-Type and Content-Disposition, multipart, compose (UploadPartCopy), CopyObject, `delete_prefixed`, ListObjectsV2 pagination, delete.
- `GetBucketVersioning` answers 501. Only `rclone purge` trips over it.
- Virtual-hosted URLs (`<zone>.de-s3.storage.bunnycdn.com/<key>`) work, but a newly created zone's hostname takes up to a minute to resolve to it (`NoSuchBucket` until then). They are required: `ActiveStorage::Representations::RedirectController` only swaps the host for the storage CDN, so a path-style URL would put the zone name into the CDN path.
- Anonymous GETs on the S3 endpoint are refused (403), unlike a `public-read` Hetzner bucket. Every URL the app hands out goes through the redirect controllers to the storage CDN, so this only matters for `Overlay::Publisher.public_url` without a storage CDN configured.
- CORS is fixed: the preflight returns 204 with `Access-Control-Allow-Headers: *` and all methods, which covers browser direct uploads.
- 500 requests/s per zone. The storage pull zone sends about 0.4 req/s to its origin on average and 3.3 req/s in its busiest hour, so only bulk jobs (rclone) need a limit (`--tpslimit 200`).

## Pull zone in front of the zone

- Serves the stored Content-Type and does not sniff, so extensionless ActiveStorage keys are fine.
- Ignores the stored `Cache-Control` and caches for 30 days by default. Everything in the bucket is immutable except `overlay/<channel>/manifest.json`, so the infrastructure repo has an edge rule caching it for 300 s, plus one that never caches error responses.
- The live storage pull zone is on the Volume tier; the others are Standard.

## Measured

Over 30 days with comparable origin pull counts (~930k vs ~900k), the Bunny Storage origin behind `cdn.fltyrd.net` answered in 87 / 182 / 276 ms (p50 / p95 / p99 hourly), the Hetzner origin behind `storage.fltyrd.net` in 326 / 2,134 / 5,650 ms. Hetzner FSN1 was the source of most background-job errors (`SlowDown`, 503, gateway timeouts, truncated bodies).

Live upload bucket on 2026-11-17: 362,659 objects / 96 GB.

## The mirror

With `BUNNY_S3__*` set, `cloud` is a `Mirror` of the `hetzner` and `bunny` services; `STORAGE_PRIMARY` picks the primary. Without them, `cloud` is plain Hetzner.

- Uploads and variants go to the primary; `ActiveStorage::MirrorJob` copies them to the other store on the `storage` queue. Deletes go to both. URLs and downloads come from the primary only.
- Blobs keep `service_name = "cloud"`, so switching the primary changes nothing in the database, and switching back is a rollback without a copy.
- What predates the mirror is not mirrored; it is copied once with rclone (`uploads-copy` accessory) and checked with `rclone check --one-way --size-only`.
- `Overlay::Publisher` is not ActiveStorage, so it writes each export to every store itself and reads the published manifest from the primary.
- Checked against the stage stores with either primary: the upload lands on the primary, the mirror copy is byte-identical, delete removes both. An unknown `STORAGE_PRIMARY`, or `bunny` without `BUNNY_S3__*`, fails at boot.

## Rejected

- **Cloudflare R2.** Rejects `x-amz-acl`, so `storage.yml` and the publisher would need the ACL removed, and Bunny would have to pull with AWS signing. Slightly more expensive. The separate-vendor argument is weak: the frontend bundle already comes from Bunny Storage.
- **Another Hetzner location.** Same product.
- **A one-shot cutover.** Objects written between the deploy and the pull zone flip would 404, and a rollback would need a copy back.
