# 🛡️ SOX Controls Testing & Monitoring Dashboard

**Estimated ROI: $150K–$300K annually in audit efficiency gains for a mid-size bank**

An end-to-end SOX Section 404 compliance monitoring platform built in R Shiny, tracking 20 internal controls across six banking process areas with full COSO framework mapping, automated workpaper generation, and reconciliation SLA monitoring.

![Dashboard Preview](screenshots/executive-summary.png)

---

## 💰 Business Impact & ROI

| Metric | Manual Process | With This Dashboard | Savings |
|--------|---------------|-------------------|---------|
| Controls testing documentation | 40+ hrs/quarter | 8 hrs/quarter | **80% reduction** |
| Reconciliation SLA tracking | Spreadsheet-based, error-prone | Real-time automated monitoring | **Eliminates missed SLAs** |
| Workpaper preparation | 2-3 hrs per control per period | Auto-generated in seconds | **$50K–$100K in audit labor** |
| Deficiency remediation tracking | Email chains, manual follow-up | Centralized dashboard with alerts | **30% faster remediation** |
| Audit Committee reporting | Days of manual compilation | One-click executive summary | **Executive time savings** |

> **Context:** U.S. public companies spend an average of $1.5M–$3M annually on SOX compliance (Protiviti 2024 SOX Survey). This dashboard addresses the testing execution and monitoring layer — typically 25–40% of that cost. For a mid-size bank with 50–100 controls, automating documentation and tracking alone can save $150K–$300K per year.

---

## 🏗️ What This Project Demonstrates

### SOX Testing Methodology
- **Risk Control Matrix (RCM):** 20 controls mapped to processes, risks, COSO components, financial statement assertions, and control owners
- **Test of Operating Effectiveness (TOE):** Realistic sample sizing (25 daily, 5 weekly, 2 monthly, 1 quarterly), exception documentation, deficiency classification
- **Remediation Lifecycle:** Open → In Progress → Remediated tracking with target dates and Audit Committee reporting readiness

### Banking Operations Knowledge
- Reconciliation controls (bank recon, intercompany, suspense accounts, GL-subledger)
- Payment controls (wire transfers with dual authorization, ACH batch processing, three-way match vendor payments)
- Fund transfer controls (internal transfers with callback verification, Fed funds T+0 confirmation)
- Financial close (journal entry approval thresholds, month-end checklist, quarterly account certifications)
- IT General Controls (user access reviews, change management, backup & recovery)
- Segregation of duties and governance

### COSO Framework Coverage
All five components represented:
1. **Control Environment** — Segregation of duties matrix
2. **Risk Assessment** — Annual enterprise risk assessment
3. **Control Activities** — Payment, reconciliation, and access controls
4. **Information & Communication** — Change management documentation
5. **Monitoring Activities** — Deficiency tracking, month-end close, account certifications

---

## 📊 Dashboard Tabs

### 1. Executive Summary
KPIs at a glance: effectiveness rate, exception count, deficiencies, open remediations, reconciliation SLA compliance. Stacked bar charts by quarter, exception rate by process, testing progress vs. target.

### 2. Risk Control Matrix (RCM)
Full searchable/filterable inventory of all 20 controls with process area, COSO component, control type (Manual / Automated / IT-Dependent Manual), frequency, and key control designation.

### 3. Controls Testing Tracker
Detailed test results with tester, reviewer, sample size, exceptions found, status, and remediation tracking. Exception trend analysis and sample-size-to-exception scatter plot.

### 4. Reconciliation SLA Monitoring
Monthly SLA compliance tracking across four reconciliation types. Color-coded performance against 95% target. Detailed log with preparer, reviewer, and open items.

### 5. COSO Coverage Analysis
Control distribution across COSO components, effectiveness rates by component, and a heatmap revealing exception rate hotspots at the COSO × Process intersection.

### 6. Workpaper Generator
Select any control + test period to generate a formatted SOX lead sheet with:
- Control identification (ID, owner, frequency, COSO component, assertions)
- Control and risk description
- Test parameters (method, population, sample size, sampling approach)
- Step-by-step test procedures with IPE validation
- Test results and conclusion

---

## 🛠️ Tech Stack

| Technology | Purpose |
|-----------|---------|
| **R Shiny** | Interactive dashboard framework |
| **tidyverse** | Data manipulation and transformation |
| **Plotly** | Interactive charts and visualizations |
| **DT** | Searchable, filterable data tables |
| **lubridate** | Date handling for test periods and SLAs |

---

## 🚀 Getting Started

### Prerequisites
```r
install.packages(c("shiny", "shinydashboard", "tidyverse", "plotly", "DT", "lubridate", "scales"))
```

### Setup
```bash
git clone https://github.com/YOUR_USERNAME/sox-controls-dashboard.git
cd sox-controls-dashboard
```

### Step 1: Generate Data
```r
source("data_prep.R")
```
This creates `rcm.rds`, `testing_data.rds`, and `recon_sla.rds`.

### Step 2: Run Dashboard
```r
shiny::runApp()
```

---

## 📁 Project Structure
```
sox-controls-dashboard/
├── app.R              # Shiny dashboard application
├── data_prep.R        # Data generation script (run once)
├── rcm.rds            # Risk Control Matrix data
├── testing_data.rds   # Controls testing results
├── recon_sla.rds      # Reconciliation SLA data
├── screenshots/       # Dashboard screenshots
│   ├── executive-summary.png
│   ├── rcm-viewer.png
│   ├── testing-tracker.png
│   ├── recon-sla.png
│   ├── coso-heatmap.png
│   └── workpaper-generator.png
└── README.md
```

---

## ⚠️ Disclaimer

This dashboard uses **simulated banking controls data** to realistically represent a mid-size bank's SOX compliance program. No real company data is used. Control descriptions, RCM structure, testing methodology, and COSO mapping reflect standard industry practices for ICFR testing.

---

## 👤 Author

**Daniel Kwaning**
- Master of Professional Studies in Analytics | Northeastern University — Roux Institute
- 📧 kwaning.d@northeastern.edu
- 🔗 [LinkedIn](https://linkedin.com/in/daniel-kwaning)
- 📍 Columbus, OH Metro

---

## 📄 License

This project is open source under the [MIT License](LICENSE).
