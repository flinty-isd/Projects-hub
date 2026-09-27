import * as React from 'react';
import * as ReactDom from 'react-dom';
import { Version } from '@microsoft/sp-core-library';
import {
  type IPropertyPaneConfiguration,
  PropertyPaneTextField
} from '@microsoft/sp-property-pane';
import { BaseClientSideWebPart } from '@microsoft/sp-webpart-base';
import { IReadonlyTheme } from '@microsoft/sp-component-base';

import * as strings from 'PeopleDeliveryTimelineWebPartStrings';
import PeopleDeliveryTimeline from './components/PeopleDeliveryTimeline';
import { IPeopleDeliveryTimelineProps } from './components/IPeopleDeliveryTimelineProps';
import { createDataService } from '../../common/createDataService';
import { IControlCentreDataService } from '../../common/SharePointDataService';

export interface IPeopleDeliveryTimelineWebPartProps {
  title: string;
  pageId: string;
}

export default class PeopleDeliveryTimelineWebPart extends BaseClientSideWebPart<IPeopleDeliveryTimelineWebPartProps> {

  private _isDarkTheme: boolean = false;
  private _dataService: IControlCentreDataService;

  protected onInit(): Promise<void> {
    this._dataService = createDataService(this.context);
    return Promise.resolve();
  }

  public render(): void {
    const element: React.ReactElement<IPeopleDeliveryTimelineProps> = React.createElement(
      PeopleDeliveryTimeline,
      {
        title: this.properties.title || 'Page Delivery Timeline',
        pageId: this.properties.pageId || 'PAGE-001',
        isDarkTheme: this._isDarkTheme,
        dataService: this._dataService
      }
    );

    ReactDom.render(element, this.domElement);
  }

  protected onThemeChanged(currentTheme: IReadonlyTheme | undefined): void {
    if (!currentTheme) {
      return;
    }
    this._isDarkTheme = !!currentTheme.isInverted;
  }

  protected onDispose(): void {
    ReactDom.unmountComponentAtNode(this.domElement);
  }

  protected get dataVersion(): Version {
    return Version.parse('1.0');
  }

  protected getPropertyPaneConfiguration(): IPropertyPaneConfiguration {
    return {
      pages: [
        {
          header: {
            description: strings.PropertyPaneDescription
          },
          groups: [
            {
              groupName: strings.BasicGroupName,
              groupFields: [
                PropertyPaneTextField('title', {
                  label: strings.TitleFieldLabel
                }),
                PropertyPaneTextField('pageId', {
                  label: strings.PageIdFieldLabel
                })
              ]
            }
          ]
        }
      ]
    };
  }
}
