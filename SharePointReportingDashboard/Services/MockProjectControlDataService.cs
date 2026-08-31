using System;
using System.Collections.Generic;
using System.Linq;
using SharePointReportingDashboard.Models;

namespace SharePointReportingDashboard.Services
{
    /// <summary>
    /// Deterministic, in-memory stand-in for the six authoritative SharePoint
    /// Lists described in the Implementation Specification, so the Control
    /// Centre pages run and look complete with no SharePoint tenant.
    ///
    /// This is entirely synthetic illustrative data - it is NOT the real
    /// HPUK migration workbook. The one figure carried over from the real
    /// programme baseline is SitesComplete = 209 (Implementation
    /// Specification, "Current programme position" and Acceptance
    /// Criteria); everything else (site names, owners, dates, RAID,
    /// actions, decisions) is invented for demonstration only. Swap this
    /// out (see DataServiceFactory) once a SharePoint-backed implementation
    /// exists.
    /// </summary>
    public class MockProjectControlDataService : IProjectControlDataService
    {
        private const int ValidatedSitesCompleteBaseline = 209;

        private readonly List<MigrationSite> _migrationSites;
        private readonly List<PageDeliveryItem> _pageDeliveryItems;
        private readonly List<ActionItem> _actions;
        private readonly List<RaidItem> _raidItems;
        private readonly List<Decision> _decisions;
        private readonly List<ProgrammeHealthArea> _programmeHealth;
        private readonly List<ProjectUpdateSnapshot> _snapshotHistory;

        public MockProjectControlDataService()
        {
            var now = DateTime.UtcNow;

            _migrationSites = BuildMigrationSites(now);
            _pageDeliveryItems = BuildPageDeliveryItems(now);
            _actions = BuildActions(now);
            _raidItems = BuildRaidItems(now);
            _decisions = BuildDecisions(now);
            _programmeHealth = BuildProgrammeHealth();
            _snapshotHistory = BuildSnapshotHistory(now);
        }

        public ProgrammeKpis GetProgrammeKpis()
        {
            var overallRag = WorstRag(_programmeHealth.Select(h => h.Rag));
            return new ProgrammeKpis
            {
                SitesComplete = ValidatedSitesCompleteBaseline,
                RemainingSites = _migrationSites.Count(s => s.Status != "Complete"),
                OverallRag = overallRag,
                PagesOutstanding = _pageDeliveryItems.Count(p => p.DeliveryStatus != "Complete"),
                OverdueActions = _actions.Count(a => a.IsOverdue),
                LmsBlocked = false
            };
        }

        public List<ProgrammeHealthArea> GetProgrammeHealth() => _programmeHealth;

        public List<MigrationSite> GetMigrationSites() =>
            _migrationSites.OrderBy(s => s.Department).ThenBy(s => s.SiteTitle).ToList();

        public List<PageDeliveryItem> GetPageDeliveryItems() =>
            _pageDeliveryItems.OrderBy(p => p.PageId).ToList();

        public List<ActionItem> GetActions() =>
            _actions.OrderByDescending(a => a.IsOverdue).ThenBy(a => a.DueDate).ToList();

        public List<RaidItem> GetRaidItems() =>
            _raidItems.OrderBy(r => r.Rag == "Red" ? 0 : r.Rag == "Amber" ? 1 : 2).ThenBy(r => r.RaidId).ToList();

        public List<Decision> GetDecisions() =>
            _decisions.OrderByDescending(d => d.Date).ToList();

        public ProjectUpdateSnapshot GetLatestSnapshot() =>
            _snapshotHistory.OrderByDescending(s => s.SnapshotDate).First();

        public List<ProjectUpdateSnapshot> GetSnapshotHistory() =>
            _snapshotHistory.OrderByDescending(s => s.SnapshotDate).ToList();

        private static string WorstRag(IEnumerable<string> ragValues)
        {
            var values = ragValues.ToList();
            if (values.Any(r => r == "Red")) return "Red";
            if (values.Any(r => r == "Amber")) return "Amber";
            return "Green";
        }

        private static List<MigrationSite> BuildMigrationSites(DateTime now)
        {
            var s = new List<MigrationSite>();

            void Add(string id, string title, string dept, string wave, string businessOwner, string migrationOwner,
                string status, string readiness, int? plannedDaysOffset, int? actualDaysOffset, string uat,
                string signOff, string blocker, double dataSizeGb, int lastReviewedDaysAgo)
            {
                s.Add(new MigrationSite
                {
                    SiteId = id,
                    SiteTitle = title,
                    SiteUrl = "https://hutchisonports.sharepoint.com/sites/" + id.ToLowerInvariant(),
                    Department = dept,
                    Wave = wave,
                    BusinessOwner = businessOwner,
                    MigrationOwner = migrationOwner,
                    Status = status,
                    Readiness = readiness,
                    ReadinessScore = readiness == "Green" ? 95 : readiness == "Amber" ? 70 : 35,
                    PlannedMigration = plannedDaysOffset.HasValue ? now.AddDays(plannedDaysOffset.Value) : (DateTime?)null,
                    ActualMigration = actualDaysOffset.HasValue ? now.AddDays(actualDaysOffset.Value) : (DateTime?)null,
                    UatStatus = uat,
                    BusinessSignOff = signOff,
                    BlockerDependency = blocker,
                    DataSizeGb = dataSizeGb,
                    LastReviewed = now.AddDays(-lastReviewedDaysAgo)
                });
            }

            Add("MIG-014", "Felixstowe - Terminal Operations", "Terminal Operations", "Wave 4", "James Whitfield", "Nora Chen", "Complete", "Green", null, -10, "Passed", "Approved", null, 42.6, 2);
            Add("MIG-015", "Felixstowe - Engineering & Maintenance", "Engineering & Maintenance", "Wave 4", "David Kim", "David Kim", "Complete", "Green", null, -8, "Passed", "Approved", null, 18.9, 2);
            Add("MIG-016", "Harwich - HSE", "HSE", "Wave 4", "Elena Ruiz", "Sam Okafor", "In Progress", "Amber", 5, null, "In Progress", "Pending", "Awaiting content owner sign-off on updated incident reporting forms", 6.4, 1);
            Add("MIG-017", "Harwich - Commercial", "Commercial", "Wave 4", "Chloe Bennett", "Tom Delaney", "Blocked", "Red", 12, null, "Not Started", "Pending", "Legacy contract archive missing metadata; indexing blocked", 24.1, 0);
            Add("MIG-018", "Corporate - Finance", "Finance", "Wave 5", "Elena Ruiz", "Nora Chen", "Planned", "Amber", 18, null, "Not Started", "Pending", "Readiness score not yet validated", 11.2, 3);
            Add("MIG-019", "Corporate - HR", "HR", "Wave 5", "Marcus Webb", "Priya Nair", "In Progress", "Green", 9, null, "In Progress", "Pending", null, 8.7, 1);
            Add("MIG-020", "Corporate - IT Service Management", "IT", "Wave 5", "Sam Okafor", "Aisha Patel", "Planned", "Green", 25, null, "Not Started", "Pending", null, 15.3, 4);
            Add("MIG-021", "Corporate - Corporate Affairs", "Corporate Affairs", "Wave 5", "Chloe Bennett", "Jamie Foster", "Planned", "Amber", 30, null, "Not Started", "Pending", "Content review outstanding", 4.8, 5);
            Add("MIG-022", "Felixstowe - Customer Service", "Customer Service", "Wave 4", "James Whitfield", "Nora Chen", "Complete", "Green", null, -3, "Passed", "Approved", null, 9.1, 1);
            Add("MIG-023", "Harwich - Terminal Operations", "Terminal Operations", "Wave 4", "James Whitfield", "Nora Chen", "Complete", "Green", null, -1, "Passed", "Approved", null, 31.4, 0);

            return s;
        }

        private static List<PageDeliveryItem> BuildPageDeliveryItems(DateTime now)
        {
            var p = new List<PageDeliveryItem>();

            void Add(string id, string name, string area, string scope, string disposition, string contentOwner,
                string deliveryOwner, string priority, string status, bool? designApproved, bool? contentReady,
                string uat, bool? signOff, int? targetGoLiveDaysOffset, string relatedActionRisk)
            {
                p.Add(new PageDeliveryItem
                {
                    PageId = id,
                    PageName = name,
                    BusinessArea = area,
                    ScopeClassification = scope,
                    ExistingUrl = null,
                    TargetUrl = "https://hutchisonports.sharepoint.com/sites/intranet/" + id.ToLowerInvariant(),
                    Disposition = disposition,
                    ContentOwner = contentOwner,
                    DeliveryOwner = deliveryOwner,
                    Priority = priority,
                    DeliveryStatus = status,
                    DesignApproved = designApproved,
                    ContentReady = contentReady,
                    UatStatus = uat,
                    BusinessSignOff = signOff,
                    TargetGoLive = targetGoLiveDaysOffset.HasValue ? now.AddDays(targetGoLiveDaysOffset.Value) : (DateTime?)null,
                    RelatedActionRisk = relatedActionRisk
                });
            }

            Add("PAGE-001", "People", "HR / People", "Out of Scope", "Create-Rebuild", "Priya Nair", "Marcus Webb",
                "Critical", "Build", true, false, "Not Started", false, 21, "ACT-101, RAID-014");
            Add("PAGE-002", "Health & Safety Hub", "HSE", "Out of Scope", "Create-Rebuild", "Elena Ruiz", null,
                "High", "Design", false, false, null, false, 35, "ACT-078, RAID-033");
            Add("PAGE-003", "Fleet & Assets Register", "Engineering & Maintenance", "Scope Change", "Migrate", "Sam Okafor", "Sam Okafor",
                "Medium", "Content", true, true, "Not Started", false, 40, null);
            Add("PAGE-004", "Supplier & Contracts Portal", "Commercial", "Out of Scope", "Assess", null, null,
                "Medium", "Assess", false, false, null, false, null, "ACT-102, RAID-021");
            Add("PAGE-005", "Corporate Policies Library", "Corporate Affairs", "Scope Change", "Merge", "Chloe Bennett", "Chloe Bennett",
                "Low", "UAT", true, true, "In Progress", false, 7, null);
            Add("PAGE-006", "Induction & Onboarding Hub", "HR / People", "Original Scope", "Migrate", "Marcus Webb", "Marcus Webb",
                "High", "Complete", true, true, "Passed", true, -14, null);
            Add("PAGE-007", "Engineering Standards Library", "Engineering & Maintenance", "Out of Scope", "Retire", "David Kim", "David Kim",
                "Low", "Sign-off", true, true, "Passed", false, 3, null);

            return p;
        }

        private static List<ActionItem> BuildActions(DateTime now)
        {
            var a = new List<ActionItem>();

            void Add(string id, string action, string owner, int dueDaysOffset, string status, string rag, string source, string relatedSitePage)
            {
                a.Add(new ActionItem
                {
                    ActionId = id,
                    Action = action,
                    Owner = owner,
                    DueDate = now.AddDays(dueDaysOffset),
                    Status = status,
                    Rag = rag,
                    Source = source,
                    RelatedSitePage = relatedSitePage
                });
            }

            Add("ACT-045", "Confirm data owner for Harwich Commercial legacy contract archive", "Tom Delaney", -3, "Open", "Red", "Migration Register", "MIG-017");
            Add("ACT-078", "Complete UAT script for Health & Safety Hub design review", "Elena Ruiz", 4, "Open", "Amber", "Page Delivery Register", "PAGE-002");
            Add("ACT-101", "Confirm People page content freeze date", "Priya Nair", 2, "Open", "Amber", "Page Delivery Register", "PAGE-001");
            Add("ACT-102", "Assign Delivery Owner for Supplier & Contracts Portal", "Chloe Bennett", -1, "Open", "Red", "Page Delivery Register", "PAGE-004");
            Add("ACT-110", "Close out HSE incident reporting form sign-off", "Sam Okafor", 10, "Open", "Green", "Migration Register", "MIG-016");
            Add("ACT-115", "Archive superseded Engineering Standards content", "David Kim", 6, "Open", "Green", "Page Delivery Register", "PAGE-007");
            Add("ACT-120", "Validate readiness score for Wave 5 Finance sites", "Nora Chen", -7, "Open", "Red", "Migration Register", "MIG-018");
            Add("ACT-128", "Publish Corporate Policies merge plan", "Chloe Bennett", 15, "Closed", "Green", "Page Delivery Register", "PAGE-005");

            return a;
        }

        private static List<RaidItem> BuildRaidItems(DateTime now)
        {
            var r = new List<RaidItem>();

            void Add(string id, string type, string area, string description, string likelihood, string impact,
                string rag, string owner, int? targetDaysOffset, string status, string relatedSitePage)
            {
                r.Add(new RaidItem
                {
                    RaidId = id,
                    Type = type,
                    Area = area,
                    Description = description,
                    Likelihood = likelihood,
                    Impact = impact,
                    Rag = rag,
                    Owner = owner,
                    TargetDate = targetDaysOffset.HasValue ? now.AddDays(targetDaysOffset.Value) : (DateTime?)null,
                    Status = status,
                    RelatedSitePage = relatedSitePage
                });
            }

            Add("RAID-014", "Risk", "Page Delivery", "People page delivery owner capacity constrained by concurrent HR system rollout", "Medium", "High", "Amber", "Marcus Webb", 21, "Open", "PAGE-001");
            Add("RAID-017", "Issue", "Migration", "Harwich Commercial legacy contract archive missing metadata blocks indexing", null, "High", "Red", "Tom Delaney", 5, "Open", "MIG-017");
            Add("RAID-021", "Dependency", "Page Delivery", "Supplier & Contracts Portal disposition depends on Procurement system decision", "High", "Medium", "Amber", "Chloe Bennett", 30, "Open", "PAGE-004");
            Add("RAID-025", "Assumption", "Migration", "Wave 5 sites assume no further site consolidations before migration", "Low", "Medium", "Green", "Nora Chen", null, "Open", null);
            Add("RAID-030", "Risk", "Migration", "Readiness scoring not yet validated for two Wave 5 Finance sites", "Medium", "Medium", "Red", "Elena Ruiz", -2, "Open", "MIG-018");
            Add("RAID-033", "Issue", "Page Delivery", "Health & Safety Hub has no confirmed Delivery Owner", null, "High", "Red", "Elena Ruiz", 10, "Open", "PAGE-002");
            Add("RAID-040", "Risk", "Governance", "Excel-based reporting may continue in parallel past cutover if Control Centre adoption lags", "Medium", "Medium", "Amber", "PMO", 60, "Open", null);
            Add("RAID-044", "Issue", "Migration", "Historic duplicate site records identified during data cleanse", null, "Low", "Green", "Nora Chen", -10, "Closed", null);

            return r;
        }

        private static List<Decision> BuildDecisions(DateTime now)
        {
            var d = new List<Decision>();

            void Add(string id, string text, int dateDaysOffset, string owner, string rationale, string status, string relatedSitePage)
            {
                d.Add(new Decision
                {
                    DecisionId = id,
                    DecisionText = text,
                    Date = now.AddDays(dateDaysOffset),
                    Owner = owner,
                    Rationale = rationale,
                    Status = status,
                    RelatedSitePage = relatedSitePage
                });
            }

            Add("DEC-008", "People page approved as Page Delivery Register item PAGE-001, not treated as an LMS blocker", -14, "Control Board", "People page was outside original migration scope; LMS itself is complete", "Approved", "PAGE-001");
            Add("DEC-012", "Additional out-of-scope pages to be assessed individually for Migrate / Create-Rebuild / Merge / Retire disposition", -14, "Control Board", "Prevents ad hoc rebuilding without accountable ownership", "Approved", null);
            Add("DEC-015", "Engineering Standards Library to be retired and superseded by the engineering QMS document control system", -5, "David Kim", "Content duplicated in existing engineering QMS", "Approved", "PAGE-007");
            Add("DEC-018", "Proposal to merge Supplier & Contracts Portal into the Commercial site pending Procurement system decision", 0, "Chloe Bennett", "Avoid rebuilding a page dependent on unresolved Procurement scope", "Pending", "PAGE-004");
            Add("DEC-021", "Excel workbook to remain the fallback export tool until SharePoint Lists are validated against the 209-site baseline", -20, "PMO", "Risk mitigation during cutover", "Approved", null);

            return d;
        }

        private static List<ProgrammeHealthArea> BuildProgrammeHealth()
        {
            return new List<ProgrammeHealthArea>
            {
                new ProgrammeHealthArea { Area = "Schedule", Rag = "Amber", Commentary = "People page and two Wave 5 sites running behind trajectory; Wave 4 otherwise on track." },
                new ProgrammeHealthArea { Area = "Scope", Rag = "Amber", Commentary = "Additional out-of-scope pages require individual disposition before build can proceed." },
                new ProgrammeHealthArea { Area = "Technical", Rag = "Green", Commentary = "No unresolved technical blockers on active migrations." },
                new ProgrammeHealthArea { Area = "Resources", Rag = "Amber", Commentary = "Health & Safety Hub and Supplier & Contracts Portal have no confirmed Delivery Owner." },
                new ProgrammeHealthArea { Area = "Business Readiness", Rag = "Green", Commentary = "UAT and sign-off processes operating as defined for completed sites." }
            };
        }

        private static List<ProjectUpdateSnapshot> BuildSnapshotHistory(DateTime now)
        {
            var h = new List<ProjectUpdateSnapshot>();

            void Add(int daysAgo, int sitesComplete, int remainingSites, string overallRag, int openRisks, int overdueActions, int pagesOutstanding, string commentary)
            {
                h.Add(new ProjectUpdateSnapshot
                {
                    SnapshotDate = now.AddDays(-daysAgo),
                    SitesComplete = sitesComplete,
                    RemainingSites = remainingSites,
                    OverallRag = overallRag,
                    OpenRisks = openRisks,
                    OverdueActions = overdueActions,
                    PagesOutstanding = pagesOutstanding,
                    Commentary = commentary
                });
            }

            Add(35, 203, 12, "Amber", 5, 2, 7, "Wave 4 migrations progressing; People page scope confirmed as an out-of-scope Page Delivery item.");
            Add(28, 205, 10, "Amber", 5, 2, 7, "Harwich HSE migration started; Health & Safety Hub moved to Design.");
            Add(21, 206, 9, "Amber", 6, 3, 7, "Harwich Commercial migration blocked on legacy contract archive metadata.");
            Add(14, 207, 8, "Amber", 6, 2, 6, "People page moved to Build; Engineering Standards Library retirement approved.");
            Add(7, 208, 7, "Amber", 7, 3, 6, "Supplier & Contracts Portal disposition still pending Procurement system decision.");
            Add(0, ValidatedSitesCompleteBaseline, 6, "Amber", 7, 3, 6, "People page (PAGE-001) in Build; Harwich Commercial site blocked pending legacy contract archive resolution; Health & Safety Hub delivery-owner gap open.");

            return h;
        }
    }
}
