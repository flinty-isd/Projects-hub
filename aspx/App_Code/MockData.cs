using System;
using System.Collections.Generic;

namespace SharePointPmDashboard.App_Code
{
    /// <summary>Sample project data used in demo mode, matching mock_data.py in the Streamlit version.</summary>
    public static class MockData
    {
        public static List<TaskItem> GetSampleTasks()
        {
            return new List<TaskItem>
            {
                new TaskItem { Title = "Define project charter", Status = "Done", AssignedTo = "Alex Rivera",
                    StartDate = new DateTime(2026, 7, 1), DueDate = new DateTime(2026, 7, 10), PercentComplete = 1.0, Priority = "High" },
                new TaskItem { Title = "Stakeholder kickoff", Status = "Done", AssignedTo = "Alex Rivera",
                    StartDate = new DateTime(2026, 7, 10), DueDate = new DateTime(2026, 7, 14), PercentComplete = 1.0, Priority = "High" },
                new TaskItem { Title = "Requirements gathering", Status = "In Progress", AssignedTo = "Priya Shah",
                    StartDate = new DateTime(2026, 7, 14), DueDate = new DateTime(2026, 8, 1), PercentComplete = 0.8, Priority = "High" },
                new TaskItem { Title = "Site migration plan", Status = "In Progress", AssignedTo = "Priya Shah",
                    StartDate = new DateTime(2026, 7, 20), DueDate = new DateTime(2026, 8, 15), PercentComplete = 0.5, Priority = "Medium" },
                new TaskItem { Title = "Content inventory", Status = "In Progress", AssignedTo = "Jordan Lee",
                    StartDate = new DateTime(2026, 7, 25), DueDate = new DateTime(2026, 8, 10), PercentComplete = 0.6, Priority = "Medium" },
                new TaskItem { Title = "Permissions mapping", Status = "Not Started", AssignedTo = "Jordan Lee",
                    StartDate = new DateTime(2026, 8, 5), DueDate = new DateTime(2026, 8, 20), PercentComplete = 0.0, Priority = "Medium" },
                new TaskItem { Title = "Pilot migration batch", Status = "Not Started", AssignedTo = "Sam Okafor",
                    StartDate = new DateTime(2026, 8, 15), DueDate = new DateTime(2026, 8, 25), PercentComplete = 0.0, Priority = "High" },
                new TaskItem { Title = "User training sessions", Status = "Not Started", AssignedTo = "Sam Okafor",
                    StartDate = new DateTime(2026, 8, 20), DueDate = new DateTime(2026, 9, 5), PercentComplete = 0.0, Priority = "Low" },
                new TaskItem { Title = "Cutover checklist", Status = "Not Started", AssignedTo = "Alex Rivera",
                    StartDate = new DateTime(2026, 8, 1), DueDate = new DateTime(2026, 8, 5), PercentComplete = 0.0, Priority = "High" },
                new TaskItem { Title = "Post-migration validation", Status = "Not Started", AssignedTo = "Priya Shah",
                    StartDate = new DateTime(2026, 9, 1), DueDate = new DateTime(2026, 9, 10), PercentComplete = 0.0, Priority = "Medium" },
            };
        }

        public static List<RiskItem> GetSampleRisks()
        {
            return new List<RiskItem>
            {
                new RiskItem { Title = "Legacy list templates not supported", Severity = "High", Owner = "Priya Shah",
                    Status = "Open", Description = "Custom InfoPath forms have no direct SharePoint Online equivalent." },
                new RiskItem { Title = "Tenant storage quota", Severity = "Medium", Owner = "Sam Okafor",
                    Status = "Open", Description = "Combined library size may exceed default site quota." },
                new RiskItem { Title = "Third-party workflow add-in", Severity = "High", Owner = "Jordan Lee",
                    Status = "Open", Description = "Nintex workflows need to be rebuilt in Power Automate." },
                new RiskItem { Title = "User adoption resistance", Severity = "Low", Owner = "Alex Rivera",
                    Status = "Mitigated", Description = "Early training sessions well received in pilot group." },
                new RiskItem { Title = "Downtime during cutover", Severity = "Medium", Owner = "Alex Rivera",
                    Status = "Open", Description = "Cutover window needs off-hours scheduling." },
            };
        }
    }
}
