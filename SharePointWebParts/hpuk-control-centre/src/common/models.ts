// Shared types for both web parts. Field names match the six SharePoint
// Lists provisioned by ../../SharePointModernPages/scripts/01-Provision-Lists.ps1.

export type Rag = 'Red' | 'Amber' | 'Green';

export interface IAttentionItem {
  category: 'Red RAID' | 'Overdue Action' | 'Blocked Site' | 'Decision Required';
  description: string;
  owner: string;
  rag: Rag;
}

export interface IControlCentreKpis {
  sitesComplete: number;
  remainingSites: number;
  pagesOutstanding: number;
  overdueActions: number;
}

export const PEOPLE_DELIVERY_STAGES: ReadonlyArray<string> = [
  'Define',
  'Design',
  'Content',
  'Build',
  'UAT',
  'Sign-off',
  'Go-live'
];

export interface IPageDeliveryStatus {
  pageId: string;
  pageName: string;
  deliveryStatus: string;
  found: boolean;
}
