# ==============================================
# SOX CONTROLS DASHBOARD — DATA PREPARATION
# Run this script ONCE locally to generate data files
# Then deploy only app.R + the .rds files
# ==============================================

library(tidyverse)
library(lubridate)

set.seed(2026)

cat("=== SOX Dashboard Data Preparation ===\n\n")

# ==============================================
# 1. RISK CONTROL MATRIX (RCM)
# ==============================================

cat("Building Risk Control Matrix...\n")

rcm <- tribble(
  ~control_id, ~process, ~sub_process, ~control_description, ~control_owner, ~frequency, ~control_type, ~coso_component, ~risk_description, ~assertion, ~key_control,
  
  # Reconciliation Controls
  "RC-001", "Reconciliation", "Bank Reconciliation", "General ledger bank account balances are reconciled to bank statements monthly. Reconciling items >$5,000 are investigated and resolved within 5 business days. Reconciliation is reviewed and approved by a supervisor.", "Controller", "Monthly", "Manual", "Control Activities", "Unreconciled differences could result in misstatement of cash balances", "Existence, Completeness", TRUE,
  "RC-002", "Reconciliation", "Intercompany Recon", "Intercompany balances are reconciled quarterly between all entities. Differences >$10,000 require written explanation and VP-level approval for resolution.", "Sr. Accountant", "Quarterly", "Manual", "Control Activities", "Intercompany imbalances could distort consolidated financial statements", "Completeness, Accuracy", TRUE,
  "RC-003", "Reconciliation", "Suspense Account Recon", "Suspense accounts are reviewed weekly. Items aged >30 days are escalated to management. All items must be cleared within 60 days per policy.", "Accounting Manager", "Weekly", "Manual", "Monitoring Activities", "Uncleared suspense items may indicate unrecorded transactions or errors", "Completeness, Existence", TRUE,
  "RC-004", "Reconciliation", "GL Subledger Recon", "General ledger balances are reconciled to subledger detail monthly for all material accounts. Variances >$1,000 are investigated.", "Sr. Accountant", "Monthly", "Manual", "Control Activities", "Subledger-to-GL discrepancies could result in material misstatements", "Accuracy, Completeness", TRUE,
  
  # Payment Controls
  "PC-001", "Payments", "Wire Transfers", "All outgoing wire transfers >$10,000 require dual authorization from two separate authorized signers. System enforces segregation — initiator cannot approve.", "Treasury Manager", "Per Occurrence", "IT-Dependent Manual", "Control Activities", "Unauthorized wire transfers could result in financial loss or fraud", "Authorization, Existence", TRUE,
  "PC-002", "Payments", "ACH Processing", "ACH batch files are reviewed and approved by Treasury before submission to the Federal Reserve. Batch totals are verified against source documentation.", "Treasury Analyst", "Daily", "Manual", "Control Activities", "Unauthorized or erroneous ACH payments could cause financial loss", "Authorization, Accuracy", TRUE,
  "PC-003", "Payments", "Vendor Payments", "Accounts payable performs three-way match (PO, receipt, invoice) before processing vendor payments. Unmatched items are held and investigated.", "AP Manager", "Per Occurrence", "Automated", "Control Activities", "Duplicate or unauthorized vendor payments could result in overpayment", "Accuracy, Occurrence", TRUE,
  "PC-004", "Payments", "Check Disbursements", "Check stock is stored in a locked safe with dual-key access. Void checks are defaced and retained. Check register is reconciled weekly.", "AP Supervisor", "Weekly", "Manual", "Control Activities", "Physical check fraud or unauthorized disbursements", "Authorization, Existence", FALSE,
  
  # Fund Transfer Controls
  "FT-001", "Fund Transfers", "Internal Transfers", "Internal fund transfers between customer accounts require documented authorization. Transfers >$25,000 require manager approval plus callback verification.", "Operations Manager", "Per Occurrence", "IT-Dependent Manual", "Control Activities", "Unauthorized internal transfers could constitute fraud or embezzlement", "Authorization", TRUE,
  "FT-002", "Fund Transfers", "Fed Funds", "Federal funds transactions are executed only by authorized traders. All trades are confirmed by independent back-office staff within T+0.", "Trading Desk Manager", "Daily", "Manual", "Control Activities", "Settlement failures or unauthorized trading could create financial exposure", "Existence, Authorization", TRUE,
  
  # Journal Entry / Financial Close Controls
  "JE-001", "Financial Close", "Journal Entries", "All manual journal entries require documented business purpose and supporting evidence. Entries >$50,000 require controller-level approval. Entries >$500,000 require CFO approval.", "Controller", "Per Occurrence", "Manual", "Control Activities", "Fraudulent or erroneous journal entries could misstate financial results", "Accuracy, Occurrence", TRUE,
  "JE-002", "Financial Close", "Month-End Close", "Month-end close checklist with 45 tasks is completed and signed off by preparer and reviewer. All tasks must be completed within 5 business days of month-end.", "Accounting Manager", "Monthly", "Manual", "Monitoring Activities", "Incomplete close procedures could lead to unreliable financial statements", "Completeness, Accuracy", TRUE,
  "JE-003", "Financial Close", "Account Certifications", "All material balance sheet accounts are certified by account owners quarterly, attesting to accuracy, completeness, and proper documentation.", "Various Owners", "Quarterly", "Manual", "Monitoring Activities", "Unreviewed accounts may contain undetected misstatements", "Existence, Accuracy", TRUE,
  
  # IT General Controls
  "IT-001", "IT General Controls", "User Access Reviews", "Quarterly user access reviews are performed for all financially significant applications (core banking, GL, Treasury). Terminated users must be removed within 24 hours.", "IT Security Manager", "Quarterly", "Manual", "Control Activities", "Inappropriate access could enable unauthorized transactions or data changes", "Authorization", TRUE,
  "IT-002", "IT General Controls", "Change Management", "All changes to financially significant applications require documented approval, testing evidence, and segregation between development and production environments.", "IT Change Manager", "Per Occurrence", "Manual", "Information & Communication", "Unauthorized system changes could impact financial data integrity", "Accuracy", TRUE,
  "IT-003", "IT General Controls", "Backup & Recovery", "Daily backups of all financial systems are verified for completion. Recovery testing is performed quarterly with results documented.", "IT Operations Lead", "Daily", "Automated", "Control Activities", "Data loss could prevent accurate financial reporting", "Completeness", FALSE,
  
  # Governance Controls
  "SD-001", "Governance", "Segregation of Duties", "Segregation of duties matrix is maintained for all financial processes. Conflicts are reviewed quarterly by Internal Audit. Compensating controls are documented for any approved exceptions.", "Internal Audit Director", "Quarterly", "Manual", "Control Environment", "SoD violations increase risk of fraud and undetected errors", "Authorization", TRUE,
  "RA-001", "Governance", "Risk Assessment", "Annual enterprise risk assessment is conducted with input from all business unit leaders. Results are presented to Audit Committee and drive SOX scoping decisions for the following year.", "Chief Risk Officer", "Annual", "Manual", "Risk Assessment", "Failure to identify emerging risks could leave material risks uncontrolled", "All", TRUE,
  "MO-001", "Governance", "Deficiency Tracking", "All control deficiencies identified during testing are logged in the deficiency tracker, assigned to remediation owners, and tracked to closure. Status is reported to Audit Committee quarterly.", "SOX Program Manager", "Quarterly", "Manual", "Monitoring Activities", "Unresolved deficiencies could escalate to material weaknesses", "All", FALSE
)

cat("  -> ", nrow(rcm), "controls created across", n_distinct(rcm$process), "process areas\n")

# ==============================================
# 2. CONTROLS TESTING DATA (FY2025)
# ==============================================

cat("Generating testing data for FY2025...\n")

generate_testing_data <- function(rcm) {
  
  testing_periods <- c("Q1 2025", "Q2 2025", "Q3 2025", "Q4 2025")
  testing_data <- data.frame()
  
  for (i in 1:nrow(rcm)) {
    control <- rcm[i, ]
    
    test_quarters <- switch(
      as.character(control$frequency),
      "Daily" = testing_periods,
      "Weekly" = testing_periods,
      "Monthly" = testing_periods,
      "Quarterly" = testing_periods,
      "Per Occurrence" = sample(testing_periods, sample(2:4, 1)),
      "Annual" = sample(testing_periods, 1)
    )
    
    sample_size <- switch(
      as.character(control$frequency),
      "Daily" = 25, "Weekly" = 5, "Monthly" = 2,
      "Quarterly" = 1, "Per Occurrence" = 25, "Annual" = 1
    )
    
    for (quarter in test_quarters) {
      exception_probability <- runif(1, 0.02, 0.18)
      exceptions_found <- rbinom(1, sample_size, exception_probability)
      
      status <- if (quarter %in% c("Q3 2025", "Q4 2025") & exceptions_found == 0) {
        "Tested - Effective"
      } else if (exceptions_found == 0) {
        sample(c("Tested - Effective", "Tested - Effective", "Pending Review"), 1)
      } else if (exceptions_found <= 2) {
        "Tested - Exception Noted"
      } else {
        "Tested - Deficiency"
      }
      
      remediation_status <- if (exceptions_found > 0) {
        if (quarter %in% c("Q1 2025", "Q2 2025")) {
          sample(c("Remediated", "Remediated", "In Progress"), 1, prob = c(0.5, 0.3, 0.2))
        } else {
          sample(c("Remediated", "In Progress", "Open"), 1, prob = c(0.2, 0.5, 0.3))
        }
      } else { NA_character_ }
      
      test_date <- switch(quarter,
                          "Q1 2025" = as.Date("2025-04-15") + sample(-10:10, 1),
                          "Q2 2025" = as.Date("2025-07-20") + sample(-10:10, 1),
                          "Q3 2025" = as.Date("2025-10-18") + sample(-10:10, 1),
                          "Q4 2025" = as.Date("2026-01-22") + sample(-10:10, 1)
      )
      
      tester <- sample(c("D. Kwaning", "J. Rodriguez", "A. Patel", "M. Chen"), 1)
      reviewer <- sample(c("K. Williams (Manager)", "S. Nakamura (Director)", "R. Thompson (VP)"), 1)
      
      row <- data.frame(
        control_id = control$control_id,
        process = control$process,
        sub_process = control$sub_process,
        control_description = control$control_description,
        control_owner = control$control_owner,
        frequency = control$frequency,
        coso_component = control$coso_component,
        test_period = quarter,
        test_date = test_date,
        tester = tester,
        reviewer = reviewer,
        sample_size = sample_size,
        exceptions_found = exceptions_found,
        test_status = status,
        remediation_status = remediation_status,
        remediation_target = if (exceptions_found > 0) test_date + sample(15:45, 1) else as.Date(NA),
        remediation_actual = if (!is.na(remediation_status) && remediation_status == "Remediated") test_date + sample(10:40, 1) else as.Date(NA),
        exception_description = if (exceptions_found > 0) {
          sample(c(
            "Missing supervisor sign-off on reconciliation",
            "Approval obtained 2 days after transaction processed",
            "Evidence of review not retained per policy",
            "Access not revoked within 24-hour SLA for terminated user",
            "Reconciling item aged >5 business days without investigation",
            "Supporting documentation incomplete for journal entry",
            "Batch total discrepancy not investigated same day",
            "SoD conflict identified — compensating control not documented",
            "Check register reconciliation completed 3 days late",
            "Backup verification log missing for 2 days in period"
          ), 1)
        } else { NA_character_ },
        stringsAsFactors = FALSE
      )
      
      testing_data <- rbind(testing_data, row)
    }
  }
  
  return(testing_data)
}

testing_data <- generate_testing_data(rcm)
cat("  -> ", nrow(testing_data), "test records generated\n")

# ==============================================
# 3. RECONCILIATION SLA DATA
# ==============================================

cat("Generating reconciliation SLA data...\n")

recon_controls <- rcm %>% filter(process == "Reconciliation")
recon_sla <- data.frame()

for (month_num in 1:12) {
  for (i in 1:nrow(recon_controls)) {
    ctrl <- recon_controls[i, ]
    if (ctrl$frequency == "Quarterly" & !(month_num %in% c(3, 6, 9, 12))) next
    
    due_date <- as.Date(paste0("2025-", sprintf("%02d", month_num), "-05")) + sample(0:3, 1)
    sla_days <- 5
    days_to_complete <- sample(1:8, 1, prob = c(0.05, 0.15, 0.25, 0.25, 0.15, 0.08, 0.05, 0.02))
    completed_date <- due_date + days_to_complete - 3
    within_sla <- days_to_complete <= sla_days
    
    recon_row <- data.frame(
      control_id = ctrl$control_id,
      recon_type = ctrl$sub_process,
      period = format(as.Date(paste0("2025-", sprintf("%02d", month_num), "-01")), "%b %Y"),
      month_num = month_num,
      sla_due_date = due_date,
      completed_date = completed_date,
      days_to_complete = days_to_complete,
      sla_days = sla_days,
      within_sla = within_sla,
      preparer = sample(c("D. Kwaning", "J. Rodriguez", "A. Patel"), 1),
      reviewer = sample(c("K. Williams", "S. Nakamura"), 1),
      reviewer_approved = within_sla | runif(1) > 0.3,
      open_items = sample(0:8, 1, prob = c(0.3, 0.2, 0.15, 0.1, 0.08, 0.07, 0.05, 0.03, 0.02)),
      stringsAsFactors = FALSE
    )
    
    recon_sla <- rbind(recon_sla, recon_row)
  }
}

cat("  -> ", nrow(recon_sla), "reconciliation records generated\n")

# ==============================================
# 4. SAVE ALL DATA AS .rds FILES
# ==============================================

cat("\nSaving data files...\n")

saveRDS(rcm, "rcm.rds")
cat("  -> rcm.rds saved (", nrow(rcm), "rows)\n")

saveRDS(testing_data, "testing_data.rds")
cat("  -> testing_data.rds saved (", nrow(testing_data), "rows)\n")

saveRDS(recon_sla, "recon_sla.rds")
cat("  -> recon_sla.rds saved (", nrow(recon_sla), "rows)\n")

cat("\n=== DATA PREPARATION COMPLETE ===\n")
cat("Files created: rcm.rds, testing_data.rds, recon_sla.rds\n")
cat("Next step: Run app.R (which loads these files)\n")