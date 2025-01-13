/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CargoHold } from './CargoHold';
import type { ComponentItemClassEnum } from './ComponentItemClassEnum';
import type { ComponentQuantumDrive } from './ComponentQuantumDrive';
import type { ComponentThruster } from './ComponentThruster';
import type { FuelTank } from './FuelTank';
import type { Hardpoint } from './Hardpoint';
import type { ItemPrice } from './ItemPrice';
import type { Manufacturer } from './Manufacturer';
import type { MediaImage } from './MediaImage';
export type Component = {
    id: string;
    name: string;
    slug: string;
    scKey?: string;
    scRef?: string;
    hidden: boolean;
    category?: string;
    type?: string;
    subType?: string;
    inventoryConsumption?: string;
    grade?: string;
    gradeLabel?: string;
    size?: string;
    itemClass?: ComponentItemClassEnum;
    itemClassLabel?: string;
    availability: {
        boughtAt: Array<ItemPrice>;
        soldAt: Array<ItemPrice>;
    };
    manufacturer?: Manufacturer;
    media: {
        storeImage?: MediaImage;
    };
    typeData?: (ComponentQuantumDrive | CargoHold | FuelTank | ComponentThruster);
    hardpoints?: Array<Hardpoint>;
    createdAt: string;
    updatedAt: string;
};

