/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ComponentQuantumDrive } from './ComponentQuantumDrive';
import type { Manufacturer } from './Manufacturer';
import type { MediaImage } from './MediaImage';
import type { ShopCommodity } from './ShopCommodity';
export type Component = {
    id: string;
    name: string;
    slug: string;
    availability: {
        listedAt: Array<ShopCommodity>;
        boughtAt: Array<ShopCommodity>;
        soldAt: Array<ShopCommodity>;
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
    /**
     * @deprecated
     */
    storeImage?: string;
    /**
     * @deprecated
     */
    storeImageIsFallback?: boolean;
    /**
     * @deprecated
     */
    storeImageLarge?: string;
    /**
     * @deprecated
     */
    storeImageMedium?: string;
    /**
     * @deprecated
     */
    storeImageSmall?: string;
};

