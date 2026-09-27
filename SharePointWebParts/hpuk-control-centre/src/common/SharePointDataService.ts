import { SPHttpClient, SPHttpClientResponse } from '@microsoft/sp-http';
import { WebPartContext } from '@microsoft/sp-webpart-base';
import { IAttentionItem, IControlCentreKpis, IPageDeliveryStatus } from './models';

export interface IControlCentreDataService {
  getAttentionItems(): Promise<IAttentionItem[]>;
  getKpis(): Promise<IControlCentreKpis>;
  getPageDeliveryStatus(pageId: string): Promise<IPageDeliveryStatus>;
}

interface ISPListItemResponse<T> {
  value: T[];
}

const SITES_COMPLETE_BASELINE = 209; // validated baseline per the Implementation Specification - do not compute this one, it's an authorised figure

/**
 * Real implementation: reads the six SharePoint Lists provisioned by
 * SharePointModernPages/scripts/01-Provision-Lists.ps1, over the SharePoint
 * REST API via SPHttpClient (no extra PnPjs dependency).
 */
export class SharePointControlCentreDataService implements IControlCentreDataService {
  constructor(private context: WebPartContext) {}

  private get webUrl(): string {
    return this.context.pageContext.web.absoluteUrl;
  }

  private async getItems<T>(listTitle: string, select: string, filter?: string, expand?: string): Promise<T[]> {
    let url = `${this.webUrl}/_api/web/lists/getbytitle('${listTitle}')/items?$select=${select}&$top=200`;
    if (filter) {
      url += `&$filter=${encodeURIComponent(filter)}`;
    }
    if (expand) {
      url += `&$expand=${expand}`;
    }

    const response: SPHttpClientResponse = await this.context.spHttpClient.get(url, SPHttpClient.configurations.v1);
    if (!response.ok) {
      throw new Error(`Request to ${listTitle} failed: ${response.status} ${response.statusText}`);
    }
    const body: ISPListItemResponse<T> = await response.json();
    return body.value;
  }

  public async getAttentionItems(): Promise<IAttentionItem[]> {
    const items: IAttentionItem[] = [];

    interface IRaidRow { Title: string; RAG: string; Status: string; Owner: { Title: string } }
    const raid = await this.getItems<IRaidRow>('SP_RAID', 'Title,RAG,Status,Owner/Title', "Status eq 'Open' and (RAG eq 'Red')", 'Owner');
    raid.forEach(r => items.push({ category: 'Red RAID', description: r.Title, owner: r.Owner ? r.Owner.Title : '', rag: 'Red' }));

    interface IActionRow { Title: string; Status: string; DueDate: string; Owner: { Title: string } }
    const nowIso = new Date().toISOString();
    const actions = await this.getItems<IActionRow>('SP_Actions', 'Title,Status,DueDate,Owner/Title', `Status ne 'Closed' and DueDate lt datetime'${nowIso}'`, 'Owner');
    actions.forEach(a => items.push({ category: 'Overdue Action', description: a.Title, owner: a.Owner ? a.Owner.Title : '', rag: 'Red' }));

    interface ISiteRow { Title: string; BlockerDependency: string; MigrationOwner: { Title: string } }
    const sites = await this.getItems<ISiteRow>('SP_MigrationRegister', 'Title,BlockerDependency,MigrationOwner/Title', "MigrationStatus eq 'Blocked'", 'MigrationOwner');
    sites.forEach(s => items.push({ category: 'Blocked Site', description: `${s.Title} - ${s.BlockerDependency || 'no blocker recorded'}`, owner: s.MigrationOwner ? s.MigrationOwner.Title : '', rag: 'Red' }));

    interface IDecisionRow { Title: string; Owner: { Title: string } }
    const decisions = await this.getItems<IDecisionRow>('SP_Decisions', 'Title,Owner/Title', "Status eq 'Pending'", 'Owner');
    decisions.forEach(d => items.push({ category: 'Decision Required', description: d.Title, owner: d.Owner ? d.Owner.Title : '', rag: 'Amber' }));

    return items;
  }

  public async getKpis(): Promise<IControlCentreKpis> {
    interface ICountRow { Id: number }

    const remaining = await this.getItems<ICountRow>('SP_MigrationRegister', 'Id', "MigrationStatus ne 'Complete'");
    const pagesOutstanding = await this.getItems<ICountRow>('SP_PageDelivery', 'Id', "DeliveryStatus ne 'Complete'");
    const nowIso = new Date().toISOString();
    const overdueActions = await this.getItems<ICountRow>('SP_Actions', 'Id', `Status ne 'Closed' and DueDate lt datetime'${nowIso}'`);

    return {
      sitesComplete: SITES_COMPLETE_BASELINE,
      remainingSites: remaining.length,
      pagesOutstanding: pagesOutstanding.length,
      overdueActions: overdueActions.length
    };
  }

  public async getPageDeliveryStatus(pageId: string): Promise<IPageDeliveryStatus> {
    interface IPageRow { PageID: string; Title: string; DeliveryStatus: string }
    const pages = await this.getItems<IPageRow>('SP_PageDelivery', 'PageID,Title,DeliveryStatus', `PageID eq '${pageId}'`);
    if (pages.length === 0) {
      return { pageId, pageName: pageId, deliveryStatus: '', found: false };
    }
    const page = pages[0];
    return { pageId: page.PageID, pageName: page.Title, deliveryStatus: page.DeliveryStatus, found: true };
  }
}

/**
 * Mock implementation used automatically in the local SPFx workbench (no
 * real site to read from), and available for manual testing anywhere else.
 * Data is illustrative, matching the same synthetic scenario used in the
 * ASPX app and Harbour Control preview - see ../../../../SharePointReportingDashboard/README.md.
 */
export class MockControlCentreDataService implements IControlCentreDataService {
  public async getAttentionItems(): Promise<IAttentionItem[]> {
    return Promise.resolve([
      { category: 'Red RAID', description: 'Harwich Commercial legacy contract archive missing metadata blocks indexing', owner: 'Tom Delaney', rag: 'Red' },
      { category: 'Red RAID', description: 'Health & Safety Hub has no confirmed Delivery Owner', owner: 'Elena Ruiz', rag: 'Red' },
      { category: 'Overdue Action', description: 'Confirm data owner for Harwich Commercial legacy contract archive', owner: 'Tom Delaney', rag: 'Red' },
      { category: 'Overdue Action', description: 'Assign Delivery Owner for Supplier & Contracts Portal', owner: 'Chloe Bennett', rag: 'Red' },
      { category: 'Blocked Site', description: 'Harwich - Commercial - Legacy contract archive missing metadata; indexing blocked', owner: 'Tom Delaney', rag: 'Red' },
      { category: 'Decision Required', description: 'Proposal to merge Supplier & Contracts Portal into the Commercial site pending Procurement system decision', owner: 'Chloe Bennett', rag: 'Amber' }
    ]);
  }

  public async getKpis(): Promise<IControlCentreKpis> {
    return Promise.resolve({
      sitesComplete: SITES_COMPLETE_BASELINE,
      remainingSites: 6,
      pagesOutstanding: 6,
      overdueActions: 3
    });
  }

  public async getPageDeliveryStatus(pageId: string): Promise<IPageDeliveryStatus> {
    if (pageId === 'PAGE-001') {
      return Promise.resolve({ pageId: 'PAGE-001', pageName: 'People', deliveryStatus: 'Build', found: true });
    }
    return Promise.resolve({ pageId, pageName: pageId, deliveryStatus: '', found: false });
  }
}
