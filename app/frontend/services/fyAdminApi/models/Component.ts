/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ComponentQuantumDrive } from './ComponentQuantumDrive';
import type { ItemPrice } from './ItemPrice';
import type { Manufacturer } from './Manufacturer';
import type { MediaImage } from './MediaImage';
export type Component = {
    id: string;
    name: string;
    slug: string;
    availability: {
        boughtAt: Array<ItemPrice>;
        soldAt: Array<ItemPrice>;
    };
    class?: string;
    grade?: string;
    itemClass?: string;
    itemClassLabel?: string;
    itemType?: string;
    itemTypeLabel?: string;
    manufacturer?: Manufacturer;
    media: {
        storeImage?: MediaImage;
    };
    typeData?: ComponentQuantumDrive;
    size?: string;
    trackingSignal?: string;
    trackingSignalLabel?: string;
    type?: string;
    typeLabel?: string;
    createdAt: string;
    updatedAt: string;
};

