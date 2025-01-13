/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CargoHold } from './CargoHold';
import type { Hardpoint } from './Hardpoint';
import type { ItemPrice } from './ItemPrice';
import type { Manufacturer } from './Manufacturer';
import type { MediaImage } from './MediaImage';
export type ModelModule = {
    id: string;
    name: string;
    slug?: string;
    description?: string;
    scKey?: string;
    metrics?: {
        cargo?: number;
    };
    cargoHolds?: Array<CargoHold>;
    availability: {
        boughtAt: Array<ItemPrice>;
        soldAt: Array<ItemPrice>;
    };
    media: {
        storeImage?: MediaImage;
    };
    pledgePrice?: number;
    productionStatus?: string;
    manufacturer?: Manufacturer;
    hardpoints?: Array<Hardpoint>;
    createdAt: string;
    updatedAt: string;
};

