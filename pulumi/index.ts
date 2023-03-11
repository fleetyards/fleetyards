import * as pulumi from "@pulumi/pulumi";
import * as hcloud from "@pulumi/hcloud";
import * as dnsimple from "@pulumi/dnsimple";
import * as digitalocean from "@pulumi/digitalocean";
import type { SpacesBucket } from "@pulumi/digitalocean";

const config = new pulumi.Config();

// Server Setup
const nameInput = config.require<string>("name");
const serverTypeInput = config.get<string>("serverType") || "cx11";
const imageInput = config.get<string>("image") || "ubuntu-20.04";
const locationInput = config.get<string>("location") || "nbg1";

const server = new hcloud.Server("server", {
  name: nameInput,
  serverType: serverTypeInput,
  image: imageInput,
  location: locationInput,
});

export const serverId = server.id;
export const { ipv4Address } = server;
export const { ipv6Address } = server;
export const { status } = server;
export const { name } = server;

// Record Setup
const subDomainInput = config.require<string>("subdomain");

const record = new dnsimple.Record("record", {
  name: subDomainInput,
  domain: "pansenhelden.de",
  type: dnsimple.RecordTypes.A,
  value: ipv4Address.apply((value) => value),
});

export const domainId = record.id;

// Bucket Setup
const bucketNameInput = config.require<string>("bucket");
const bucketRegionInput = config.get<string>("bucketRegion") || "fra1";
const bucketAclInput = config.get<string>("bucketAcl") || "private";

const bucket = new digitalocean.SpacesBucket("bucket", {
  name: bucketNameInput,
  region: bucketRegionInput,
  acl: bucketAclInput,
  forceDestroy: true,
});

export const bucketId = bucket.id;

// Backup Bucket
let backupBucket: SpacesBucket | null = null;

const backupBucketNameInput = config.get<string>("backupBucket");

if (backupBucketNameInput) {
  const backupBucketRegionInput =
    config.get<string>("backupBucketRegion") || "fra1";
  const backupBucketAclInput =
    config.get<string>("backupBucketAcl") || "private";

  backupBucket = new digitalocean.SpacesBucket("backup-bucket", {
    name: backupBucketNameInput,
    region: backupBucketRegionInput,
    acl: backupBucketAclInput,
  });
}

export const backupBucketId = backupBucket ? backupBucket.id : null;
