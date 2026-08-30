using System;
using System.Collections.Generic;
using System.Linq;
using SharePointReportingDashboard.Models;

namespace SharePointReportingDashboard.Services
{
    /// <summary>
    /// Deterministic, in-memory stand-in for a real SharePoint tenant so the
    /// dashboard runs and looks complete with no tenant, app registration,
    /// or network access required. Swap this out (see DataServiceFactory)
    /// once a CSOM/PnP-backed implementation exists.
    /// </summary>
    public class MockSharePointDataService : ISharePointDataService
    {
        private readonly List<SiteSummary> _sites;
        private readonly List<ListSummary> _lists;
        private readonly List<ActivityRecord> _activity;
        private readonly List<PermissionEntry> _permissions;

        public MockSharePointDataService()
        {
            var now = DateTime.UtcNow;

            _lists = BuildLists(now);
            _sites = BuildSites(now, _lists);
            _activity = BuildActivity(now);
            _permissions = BuildPermissions();
        }

        public DashboardStats GetDashboardStats()
        {
            var cutoff = DateTime.UtcNow.AddDays(-30);
            return new DashboardStats
            {
                TotalSites = _sites.Count,
                TotalLists = _sites.Sum(s => s.ListCount),
                TotalItems = _sites.Sum(s => s.ItemCount),
                TotalStorageMb = Math.Round(_sites.Sum(s => s.StorageUsedMb), 1),
                ActiveUsers30Days = _activity
                    .Where(a => a.TimestampUtc >= cutoff)
                    .Select(a => a.UserName)
                    .Distinct()
                    .Count(),
                GeneratedAtUtc = DateTime.UtcNow
            };
        }

        public List<SiteSummary> GetSites()
        {
            return _sites.OrderByDescending(s => s.StorageUsedMb).ToList();
        }

        public List<ListSummary> GetLists(string siteTitle)
        {
            var query = _lists.AsEnumerable();
            if (!string.IsNullOrEmpty(siteTitle))
            {
                query = query.Where(l => string.Equals(l.SiteTitle, siteTitle, StringComparison.OrdinalIgnoreCase));
            }
            return query.OrderBy(l => l.SiteTitle).ThenByDescending(l => l.ItemCount).ToList();
        }

        public List<ActivityRecord> GetRecentActivity(int count)
        {
            return _activity
                .OrderByDescending(a => a.TimestampUtc)
                .Take(count <= 0 ? _activity.Count : count)
                .ToList();
        }

        public List<PermissionEntry> GetPermissions()
        {
            return _permissions
                .OrderBy(p => p.SiteTitle)
                .ThenBy(p => p.ObjectName)
                .ToList();
        }

        private static List<ListSummary> BuildLists(DateTime now)
        {
            var l = new List<ListSummary>();

            void Add(string site, string name, string type, int items, double sizeMb, int daysAgo)
            {
                l.Add(new ListSummary
                {
                    SiteTitle = site,
                    ListName = name,
                    ListType = type,
                    ItemCount = items,
                    SizeMb = sizeMb,
                    LastModifiedUtc = now.AddDays(-daysAgo)
                });
            }

            Add("Intranet Home", "Site Pages", "Page Library", 42, 118.4, 1);
            Add("Intranet Home", "Company Announcements", "List", 63, 4.2, 2);
            Add("Intranet Home", "Site Assets", "Document Library", 210, 340.7, 5);

            Add("Human Resources", "Employee Handbook", "Document Library", 18, 96.3, 12);
            Add("Human Resources", "Onboarding Documents", "Document Library", 154, 512.9, 3);
            Add("Human Resources", "PTO Requests", "List", 892, 12.8, 1);
            Add("Human Resources", "Policy Library", "Document Library", 47, 203.5, 20);

            Add("Finance", "Invoices", "Document Library", 3120, 4830.2, 1);
            Add("Finance", "Budget Reports", "Document Library", 88, 675.1, 7);
            Add("Finance", "Purchase Orders", "List", 1440, 26.6, 2);
            Add("Finance", "Expense Approvals", "List", 976, 18.3, 1);

            Add("IT Service Desk", "Tickets", "List", 5310, 61.4, 0);
            Add("IT Service Desk", "Knowledge Base", "Document Library", 132, 289.0, 4);
            Add("IT Service Desk", "Asset Inventory", "List", 640, 9.7, 9);

            Add("Marketing", "Campaign Assets", "Document Library", 980, 6210.5, 2);
            Add("Marketing", "Brand Guidelines", "Document Library", 26, 415.8, 30);
            Add("Marketing", "Content Calendar", "List", 214, 3.9, 1);

            Add("Project Falcon", "Project Documents", "Document Library", 356, 1120.6, 1);
            Add("Project Falcon", "Task Tracker", "List", 512, 8.1, 0);
            Add("Project Falcon", "Meeting Notes", "Document Library", 74, 64.2, 6);
            Add("Project Falcon", "Risk Register", "List", 39, 1.6, 14);

            return l;
        }

        private static List<SiteSummary> BuildSites(DateTime now, List<ListSummary> lists)
        {
            SiteSummary Build(string title, string url, string owner, string template, int daysAgo)
            {
                var siteLists = lists.Where(x => x.SiteTitle == title).ToList();
                return new SiteSummary
                {
                    Title = title,
                    Url = url,
                    Owner = owner,
                    Template = template,
                    ListCount = siteLists.Count,
                    ItemCount = siteLists.Sum(x => x.ItemCount),
                    StorageUsedMb = Math.Round(siteLists.Sum(x => x.SizeMb), 1),
                    LastModifiedUtc = now.AddDays(-daysAgo)
                };
            }

            return new List<SiteSummary>
            {
                Build("Intranet Home", "https://contoso.sharepoint.com/sites/intranet", "Priya Nair", "Communication Site", 1),
                Build("Human Resources", "https://contoso.sharepoint.com/sites/hr", "Marcus Webb", "Team Site", 1),
                Build("Finance", "https://contoso.sharepoint.com/sites/finance", "Elena Ruiz", "Team Site", 1),
                Build("IT Service Desk", "https://contoso.sharepoint.com/sites/it-helpdesk", "Sam Okafor", "Team Site", 0),
                Build("Marketing", "https://contoso.sharepoint.com/sites/marketing", "Chloe Bennett", "Team Site", 1),
                Build("Project Falcon", "https://contoso.sharepoint.com/sites/project-falcon", "David Kim", "Team Site", 0)
            };
        }

        private static List<ActivityRecord> BuildActivity(DateTime now)
        {
            var a = new List<ActivityRecord>();

            void Add(double hoursAgo, string user, string action, string item, string list, string site)
            {
                a.Add(new ActivityRecord
                {
                    TimestampUtc = now.AddHours(-hoursAgo),
                    UserName = user,
                    Action = action,
                    ItemName = item,
                    ListName = list,
                    SiteTitle = site
                });
            }

            Add(0.5, "Sam Okafor", "Created", "INC-40871 - VPN access request", "Tickets", "IT Service Desk");
            Add(1.2, "Elena Ruiz", "Uploaded", "Q3-Board-Deck.pptx", "Budget Reports", "Finance");
            Add(2.0, "David Kim", "Modified", "Task Tracker (item #512)", "Task Tracker", "Project Falcon");
            Add(3.4, "Chloe Bennett", "Uploaded", "Autumn-Campaign-Hero.psd", "Campaign Assets", "Marketing");
            Add(4.1, "Aisha Patel", "Viewed", "Employee Handbook 2026.pdf", "Employee Handbook", "Human Resources");
            Add(6.0, "Marcus Webb", "Modified", "PTO Requests (item #892)", "PTO Requests", "Human Resources");
            Add(9.5, "Tom Delaney", "Shared", "Vendor-Contract-Northwind.docx", "Invoices", "Finance");
            Add(12.0, "Priya Nair", "Published", "Fall All-Hands Recap", "Company Announcements", "Intranet Home");
            Add(15.3, "Nora Chen", "Uploaded", "Risk-Register-Update.xlsx", "Risk Register", "Project Falcon");
            Add(20.0, "Sam Okafor", "Resolved", "INC-40855 - Printer offline", "Tickets", "IT Service Desk");
            Add(26.0, "Jamie Foster", "Deleted", "Draft-Old-Logo-v1.ai", "Brand Guidelines", "Marketing");
            Add(30.0, "Elena Ruiz", "Approved", "PO-2291", "Purchase Orders", "Finance");
            Add(36.0, "David Kim", "Uploaded", "Falcon-Kickoff-Notes.docx", "Meeting Notes", "Project Falcon");
            Add(40.0, "Chloe Bennett", "Modified", "Content Calendar (item #214)", "Content Calendar", "Marketing");
            Add(48.0, "Marcus Webb", "Uploaded", "New-Hire-Checklist-Q4.docx", "Onboarding Documents", "Human Resources");
            Add(55.0, "Aisha Patel", "Shared", "Knowledge Base article KB-1042", "Knowledge Base", "IT Service Desk");
            Add(62.0, "Priya Nair", "Modified", "Site Pages / Home.aspx", "Site Pages", "Intranet Home");
            Add(70.0, "Tom Delaney", "Uploaded", "Expense-Report-Sept.xlsx", "Expense Approvals", "Finance");
            Add(80.0, "Nora Chen", "Created", "Risk item: Vendor delay - hardware", "Risk Register", "Project Falcon");
            Add(96.0, "Jamie Foster", "Modified", "Campaign-Brief-Q4.docx", "Campaign Assets", "Marketing");
            Add(120.0, "Sam Okafor", "Uploaded", "Asset-Inventory-Nov.xlsx", "Asset Inventory", "IT Service Desk");
            Add(150.0, "Elena Ruiz", "Viewed", "FY26-Budget-Draft.xlsx", "Budget Reports", "Finance");
            Add(180.0, "David Kim", "Shared", "Project Falcon Charter.pdf", "Project Documents", "Project Falcon");
            Add(240.0, "Marcus Webb", "Modified", "Policy Library / Remote-Work-Policy.pdf", "Policy Library", "Human Resources");

            return a;
        }

        private static List<PermissionEntry> BuildPermissions()
        {
            var p = new List<PermissionEntry>();

            void Add(string site, string obj, string objType, string principal, string principalType,
                string level, bool inherits, bool external = false)
            {
                p.Add(new PermissionEntry
                {
                    SiteTitle = site,
                    ObjectName = obj,
                    ObjectType = objType,
                    PrincipalName = principal,
                    PrincipalType = principalType,
                    PermissionLevel = level,
                    InheritsPermissions = inherits,
                    IsExternalUser = external
                });
            }

            Add("Intranet Home", "Intranet Home", "Site", "Intranet Home Owners", "SharePoint Group", "Full Control", true);
            Add("Intranet Home", "Intranet Home", "Site", "Intranet Home Members", "SharePoint Group", "Edit", true);
            Add("Intranet Home", "Intranet Home", "Site", "Everyone except external users", "SharePoint Group", "Read", true);

            Add("Human Resources", "Human Resources", "Site", "HR Owners", "SharePoint Group", "Full Control", true);
            Add("Human Resources", "Human Resources", "Site", "HR Members", "SharePoint Group", "Edit", true);
            Add("Human Resources", "PTO Requests", "List", "HR Members", "SharePoint Group", "Edit", true);
            Add("Human Resources", "Employee Handbook", "Document Library", "Marcus Webb", "User", "Full Control", false);
            Add("Human Resources", "Onboarding Documents", "Document Library", "Aisha Patel", "User", "Contribute", false);

            Add("Finance", "Finance", "Site", "Finance Owners", "SharePoint Group", "Full Control", true);
            Add("Finance", "Finance", "Site", "Finance Members", "SharePoint Group", "Edit", true);
            Add("Finance", "Invoices", "Document Library", "Finance Members", "SharePoint Group", "Edit", true);
            Add("Finance", "Invoices", "Document Library", "Tom Delaney", "User", "Contribute", false);
            Add("Finance", "Budget Reports", "Document Library", "Elena Ruiz", "User", "Full Control", false);
            Add("Finance", "Budget Reports", "Document Library", "Executive Leadership", "SharePoint Group", "Read", false);
            Add("Finance", "Purchase Orders", "List", "partner@northwind-vendor.com", "Guest", "Contribute", false, true);

            Add("IT Service Desk", "IT Service Desk", "Site", "IT Owners", "SharePoint Group", "Full Control", true);
            Add("IT Service Desk", "IT Service Desk", "Site", "IT Members", "SharePoint Group", "Edit", true);
            Add("IT Service Desk", "Tickets", "List", "Everyone except external users", "SharePoint Group", "Contribute", true);
            Add("IT Service Desk", "Asset Inventory", "List", "Sam Okafor", "User", "Full Control", false);

            Add("Marketing", "Marketing", "Site", "Marketing Owners", "SharePoint Group", "Full Control", true);
            Add("Marketing", "Marketing", "Site", "Marketing Members", "SharePoint Group", "Edit", true);
            Add("Marketing", "Campaign Assets", "Document Library", "Marketing Members", "SharePoint Group", "Edit", true);
            Add("Marketing", "Brand Guidelines", "Document Library", "guest_media@brightwave-agency.com", "Guest", "Read", false, true);

            Add("Project Falcon", "Project Falcon", "Site", "Falcon Owners", "SharePoint Group", "Full Control", true);
            Add("Project Falcon", "Project Falcon", "Site", "Falcon Members", "SharePoint Group", "Edit", true);
            Add("Project Falcon", "Risk Register", "List", "David Kim", "User", "Full Control", false);
            Add("Project Falcon", "Task Tracker", "List", "Nora Chen", "User", "Contribute", false);

            return p;
        }
    }
}
