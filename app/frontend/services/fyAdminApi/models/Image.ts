/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { Gallery } from './Gallery';

export type Image = {
    id: string;
    name: string;
    caption?: string | null;
    size?: number;
    width?: number | null;
    height?: number | null;
    type?: string;
    enabled?: boolean;
    global?: boolean;
    background?: boolean;
    url?: string;
    smallUrl?: string;
    bigUrl?: string;
    gallery?: Gallery | null;
    createdAt: string;
    updatedAt: string;
};

