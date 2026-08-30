# SharePoint Reporting Dashboard

An ASP.NET Web Forms (`.aspx`) dashboard that reports on a SharePoint
tenant: site & list inventory, recent user activity, and a permissions
overview. It ships with a **mock data service**, so it runs and looks
complete with no SharePoint tenant, app registration, or network access
required — good for demos, UI iteration, or as a starting point for a
real integration.

## Pages

| Page                | What it shows |
|----------------------|---------------|
| `Default.aspx`       | Tenant-wide stat tiles, storage-by-site chart, quick links |
| `Sites.aspx`         | Every site collection, plus a filterable list/library inventory |
| `Activity.aspx`      | Recent document/list activity and top contributors |
| `Permissions.aspx`   | Every permission assignment, with broken-inheritance and external-user flags |

## Running it

This is a classic ASP.NET Web Forms **Web Application Project** targeting
.NET Framework 4.8, so it needs Windows + IIS or IIS Express (via Visual
Studio) — it does not run on .NET Core/5+ or on Linux, since `System.Web`
is Windows-only.

1. Open `SharePointReportingDashboard.sln` in Visual Studio 2019+.
2. Press F5 (IIS Express). It opens to `Default.aspx`.

No NuGet restore or SharePoint credentials are needed for the mock mode.

## Architecture

All pages read through `Services.ISharePointDataService`, obtained from
`Services.DataServiceFactory.GetService()`. The only implementation today
is `MockSharePointDataService`, which builds a deterministic, realistic
in-memory dataset (6 sites, ~20 lists/libraries, activity history,
permission assignments) each time it's constructed.

```
Pages (Default/Sites/Activity/Permissions .aspx)
        -> DataServiceFactory.GetService()
              -> ISharePointDataService
                    -> MockSharePointDataService   (today)
                    -> your CSOM/PnP implementation (future)
```

## Connecting a real SharePoint tenant

1. Add the SharePoint CSOM or `PnP.Framework` / `PnP.Core` NuGet package
   to this project.
2. Implement `ISharePointDataService` (see `Services/ISharePointDataService.cs`)
   against the real tenant — e.g. `CsomSharePointDataService`.
3. Fill in the `SharePoint.*` keys in `Web.config` (`TenantUrl`, `ClientId`,
   `ClientSecret`, `AuthMode`) with an app-only registration that has
   read access to the sites you want to report on.
4. Set `UseMockData` to `false` in `Web.config`.
5. Return your new implementation from `DataServiceFactory.GetService()`
   when `UseMockData` is `false`.

No page or markup changes are required — every page only depends on the
`ISharePointDataService` interface.
