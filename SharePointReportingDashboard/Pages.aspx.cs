using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;
using SharePointReportingDashboard.Services;

namespace SharePointReportingDashboard
{
    public partial class PagesPage : Page
    {
        private static readonly string[] TimelineStages = { "Define", "Design", "Content", "Build", "UAT", "Sign-off", "Go-live" };

        protected Repeater statsRepeater;
        protected Repeater timelineRepeater;
        protected GridView priorityGrid;
        protected GridView ownershipGapsGrid;
        protected GridView backlogGrid;
        protected GridView relatedGrid;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack)
            {
                return;
            }

            var service = DataServiceFactory.GetService();
            var pages = service.GetPageDeliveryItems();
            var actions = service.GetActions();
            var raid = service.GetRaidItems();

            var peoplePage = pages.FirstOrDefault(p => p.PageId == "PAGE-001");
            var pagesOutstanding = pages.Count(p => p.DeliveryStatus != "Complete");
            var pagesInBuild = pages.Count(p => p.DeliveryStatus == "Build");
            var pagesAwaitingUatOrSignOff = pages.Count(p => p.DeliveryStatus == "UAT" || p.DeliveryStatus == "Sign-off");

            statsRepeater.DataSource = new[]
            {
                new StatTile { Value = peoplePage != null ? peoplePage.DeliveryStatus : "Unknown", Label = "People (PAGE-001) status" },
                new StatTile { Value = pagesOutstanding.ToString(), Label = "Pages Outstanding" },
                new StatTile { Value = pagesInBuild.ToString(), Label = "Pages in Build" },
                new StatTile { Value = pagesAwaitingUatOrSignOff.ToString(), Label = "Awaiting UAT / Sign-off" }
            };
            statsRepeater.DataBind();

            var currentStageIndex = peoplePage != null
                ? Array.FindIndex(TimelineStages, s => string.Equals(s, peoplePage.DeliveryStatus, StringComparison.OrdinalIgnoreCase))
                : -1;
            if (peoplePage != null && peoplePage.DeliveryStatus == "Complete")
            {
                currentStageIndex = TimelineStages.Length;
            }

            timelineRepeater.DataSource = TimelineStages.Select((stage, index) => new TimelineStep
            {
                Stage = stage,
                CssClass = index < currentStageIndex ? "done" : index == currentStageIndex ? "current" : ""
            }).ToList();
            timelineRepeater.DataBind();

            priorityGrid.DataSource = pages
                .Where(p => (p.Priority == "Critical" || p.Priority == "High") && p.DeliveryStatus != "Complete")
                .OrderBy(p => p.Priority == "Critical" ? 0 : 1)
                .ToList();
            priorityGrid.DataBind();

            ownershipGapsGrid.DataSource = pages
                .Where(p => string.IsNullOrEmpty(p.ContentOwner) || string.IsNullOrEmpty(p.DeliveryOwner))
                .ToList();
            ownershipGapsGrid.DataBind();

            backlogGrid.DataSource = pages
                .Where(p => p.ScopeClassification == "Out of Scope" || p.ScopeClassification == "Scope Change")
                .ToList();
            backlogGrid.DataBind();

            var related = new List<RelatedItem>();
            related.AddRange(raid
                .Where(r => r.RelatedSitePage != null && r.RelatedSitePage.StartsWith("PAGE-"))
                .Select(r => new RelatedItem { ItemType = "RAID", ItemId = r.RaidId, Description = r.Description, RelatedPage = r.RelatedSitePage, Owner = r.Owner, Rag = r.Rag }));
            related.AddRange(actions
                .Where(a => a.RelatedSitePage != null && a.RelatedSitePage.StartsWith("PAGE-"))
                .Select(a => new RelatedItem { ItemType = "Action", ItemId = a.ActionId, Description = a.Action, RelatedPage = a.RelatedSitePage, Owner = a.Owner, Rag = a.Rag }));

            relatedGrid.DataSource = related.OrderBy(r => r.RelatedPage).ToList();
            relatedGrid.DataBind();
        }

        protected string GetRagBadge(string rag)
        {
            var cssClass = rag == "Red" ? "rag-red" : rag == "Amber" ? "rag-amber" : rag == "Green" ? "rag-green" : "rag-grey";
            return "<span class=\"rag-badge " + cssClass + "\">" + (rag ?? "Unknown") + "</span>";
        }

        private class StatTile
        {
            public string Value { get; set; }
            public string Label { get; set; }
        }

        private class TimelineStep
        {
            public string Stage { get; set; }
            public string CssClass { get; set; }
        }

        private class RelatedItem
        {
            public string ItemType { get; set; }
            public string ItemId { get; set; }
            public string Description { get; set; }
            public string RelatedPage { get; set; }
            public string Owner { get; set; }
            public string Rag { get; set; }
        }
    }
}
