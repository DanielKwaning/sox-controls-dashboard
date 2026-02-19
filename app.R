# ==============================================
# SOX CONTROLS TESTING & MONITORING DASHBOARD
# app.R — Shiny Application (loads pre-built data)
# Built by Daniel Kwaning | February 2026
# 
# SETUP: Run data_prep.R first to generate .rds files
# ==============================================

library(shiny)
library(shinydashboard)
library(tidyverse)
library(plotly)
library(DT)
library(lubridate)
library(scales)

# ==============================================
# LOAD PRE-BUILT DATA
# ==============================================

rcm          <- readRDS("rcm.rds")
testing_data <- readRDS("testing_data.rds")
recon_sla    <- readRDS("recon_sla.rds")

# ==============================================
# CALCULATE SUMMARY METRICS
# ==============================================

total_controls    <- nrow(rcm)
key_controls      <- sum(rcm$key_control)
total_tests       <- nrow(testing_data)
effective_tests   <- sum(testing_data$test_status == "Tested - Effective")
exception_tests   <- sum(testing_data$test_status == "Tested - Exception Noted")
deficiency_tests  <- sum(testing_data$test_status == "Tested - Deficiency")
pending_tests     <- sum(testing_data$test_status == "Pending Review")
effectiveness_rate <- round(effective_tests / (total_tests - pending_tests) * 100, 1)
open_remediations <- sum(testing_data$remediation_status == "Open", na.rm = TRUE)
recon_sla_rate    <- round(sum(recon_sla$within_sla) / nrow(recon_sla) * 100, 1)
data_refresh      <- format(Sys.time(), "%B %d, %Y at %I:%M %p")

# ==============================================
# UI
# ==============================================

ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(
    title = span(icon("shield-alt"), " SOX Controls Monitor"),
    titleWidth = 320,
    tags$li(
      class = "dropdown",
      style = "padding: 15px; color: white; font-size: 12px;",
      icon("database"),
      paste(total_controls, "Controls |", total_tests, "Tests | FY2025")
    )
  ),
  
  dashboardSidebar(
    width = 280,
    
    div(
      style = "text-align: center; padding: 15px; background: linear-gradient(135deg, #1a237e 0%, #0d47a1 100%); color: white;",
      icon("balance-scale", style = "font-size: 36px; margin-bottom: 8px;"),
      h4(style = "margin: 5px 0; font-weight: bold;", "SOX Controls Testing"),
      h5(style = "margin: 0; font-weight: normal;", "& Monitoring Dashboard"),
      hr(style = "border-color: rgba(255,255,255,0.3); margin: 10px 0;"),
      p(style = "margin: 0; font-size: 10px;", "Built by Daniel Kwaning"),
      p(style = "margin: 0; font-size: 10px; color: #B0BEC5;", "COSO/ICFR Framework Aligned"),
      p(style = "margin: 0; font-size: 10px; color: #B0BEC5;", "Portfolio Project — Simulated Data")
    ),
    
    sidebarMenu(
      id = "tabs",
      menuItem("Executive Summary", tabName = "executive", icon = icon("tachometer-alt")),
      menuItem("Risk Control Matrix", tabName = "rcm_tab", icon = icon("th")),
      menuItem("Controls Testing Tracker", tabName = "testing", icon = icon("clipboard-check")),
      menuItem("Reconciliation SLA", tabName = "recon", icon = icon("clock")),
      menuItem("COSO Coverage", tabName = "coso", icon = icon("sitemap")),
      menuItem("Workpaper Generator", tabName = "workpaper", icon = icon("file-alt")),
      menuItem("About This Project", tabName = "about", icon = icon("info-circle"))
    ),
    
    div(
      style = "padding: 15px;",
      h5(style = "color: white; margin-top: 15px;", icon("filter"), " FILTERS"),
      selectInput("filter_process", "Process Area:",
                  choices = c("All", sort(unique(rcm$process))), selected = "All"),
      selectInput("filter_period", "Test Period:",
                  choices = c("All", "Q1 2025", "Q2 2025", "Q3 2025", "Q4 2025"), selected = "All"),
      selectInput("filter_status", "Test Status:",
                  choices = c("All", sort(unique(testing_data$test_status))), selected = "All"),
      selectInput("filter_coso", "COSO Component:",
                  choices = c("All", sort(unique(rcm$coso_component))), selected = "All")
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper { background-color: #ECEFF1; }
        .box { border-top: 3px solid #1a237e; border-radius: 4px; }
        .small-box { border-radius: 4px; }
        h2 { color: #1a237e; font-weight: 600; }
        .info-box { border-radius: 4px; }
        .workpaper-box {
          background: white; border: 1px solid #CFD8DC;
          padding: 20px; margin: 10px 0; border-radius: 4px;
          font-family: 'Courier New', monospace; font-size: 12px;
        }
        .wp-header { background: #1a237e; color: white; padding: 10px 15px;
                      margin: -20px -20px 15px -20px; border-radius: 4px 4px 0 0; }
        .wp-field { margin: 4px 0; }
        .wp-label { font-weight: bold; display: inline-block; width: 200px; }
      "))
    ),
    
    tabItems(
      
      # ===== TAB 1: EXECUTIVE SUMMARY =====
      tabItem(tabName = "executive",
              fluidRow(column(12,
                              h2(icon("tachometer-alt"), " SOX Controls Testing — Executive Summary"),
                              p(style = "color: #546E7A;",
                                "FY2025 Internal Controls Over Financial Reporting (ICFR) | COSO Framework | Simulated Banking Environment")
              )),
              fluidRow(
                infoBoxOutput("kpi_total_controls", width = 3),
                infoBoxOutput("kpi_effectiveness", width = 3),
                infoBoxOutput("kpi_exceptions", width = 3),
                infoBoxOutput("kpi_deficiencies", width = 3)
              ),
              fluidRow(
                infoBoxOutput("kpi_tests_completed", width = 3),
                infoBoxOutput("kpi_pending_review", width = 3),
                infoBoxOutput("kpi_open_remediation", width = 3),
                infoBoxOutput("kpi_recon_sla", width = 3)
              ),
              fluidRow(
                box(title = "Testing Results by Quarter", status = "primary", solidHeader = TRUE, width = 6,
                    plotlyOutput("quarterly_results", height = "320px")),
                box(title = "Exception Rate by Process Area", status = "warning", solidHeader = TRUE, width = 6,
                    plotlyOutput("exception_by_process", height = "320px"))
              ),
              fluidRow(
                box(title = "Controls Testing Progress (FY2025)", status = "info", solidHeader = TRUE, width = 6,
                    plotlyOutput("testing_progress", height = "300px")),
                box(title = "Remediation Status Overview", status = "danger", solidHeader = TRUE, width = 6,
                    plotlyOutput("remediation_overview", height = "300px"))
              ),
              fluidRow(
                box(title = "Open Exceptions Requiring Attention", status = "danger", solidHeader = TRUE, width = 12,
                    DTOutput("open_exceptions_table"),
                    footer = "Sorted by remediation urgency. Items past target date highlighted.")
              )
      ),
      
      # ===== TAB 2: RISK CONTROL MATRIX =====
      tabItem(tabName = "rcm_tab",
              fluidRow(column(12,
                              h2(icon("th"), " Risk Control Matrix (RCM)"),
                              p(style = "color: #546E7A;",
                                "Complete inventory of SOX-relevant controls mapped to processes, risks, COSO components, and financial statement assertions")
              )),
              fluidRow(
                infoBoxOutput("rcm_total", width = 3), infoBoxOutput("rcm_key_controls", width = 3),
                infoBoxOutput("rcm_automated", width = 3), infoBoxOutput("rcm_processes", width = 3)
              ),
              fluidRow(
                box(title = "Control Type Distribution", status = "primary", solidHeader = TRUE, width = 4,
                    plotlyOutput("control_type_pie", height = "280px")),
                box(title = "Controls by Process Area", status = "info", solidHeader = TRUE, width = 4,
                    plotlyOutput("controls_by_process", height = "280px")),
                box(title = "Control Frequency Distribution", status = "success", solidHeader = TRUE, width = 4,
                    plotlyOutput("control_frequency", height = "280px"))
              ),
              fluidRow(
                box(title = "Full Risk Control Matrix", status = "primary", solidHeader = TRUE, width = 12,
                    DTOutput("rcm_table"))
              )
      ),
      
      # ===== TAB 3: CONTROLS TESTING TRACKER =====
      tabItem(tabName = "testing",
              fluidRow(column(12,
                              h2(icon("clipboard-check"), " Controls Testing Tracker"),
                              p(style = "color: #546E7A;",
                                "Detailed testing results — Design effectiveness (TOD) and Operating effectiveness (TOE)")
              )),
              fluidRow(
                box(title = "Testing Results by Control", status = "primary", solidHeader = TRUE, width = 12,
                    DTOutput("testing_tracker_table"))
              ),
              fluidRow(
                box(title = "Exception Trend Across Quarters", status = "warning", solidHeader = TRUE, width = 6,
                    plotlyOutput("exception_trend", height = "300px"),
                    footer = "Declining exceptions indicate remediation effectiveness"),
                box(title = "Sample Size vs Exceptions", status = "info", solidHeader = TRUE, width = 6,
                    plotlyOutput("sample_exception_scatter", height = "300px"))
              )
      ),
      
      # ===== TAB 4: RECONCILIATION SLA =====
      tabItem(tabName = "recon",
              fluidRow(column(12,
                              h2(icon("clock"), " Reconciliation SLA Monitoring"),
                              p(style = "color: #546E7A;", "Are recons done on time per SLA?")
              )),
              fluidRow(
                infoBoxOutput("recon_total", width = 3), infoBoxOutput("recon_sla_pct", width = 3),
                infoBoxOutput("recon_avg_days", width = 3), infoBoxOutput("recon_open_items", width = 3)
              ),
              fluidRow(
                box(title = "SLA Compliance by Month", status = "primary", solidHeader = TRUE, width = 6,
                    plotlyOutput("sla_by_month", height = "320px"), footer = "Target: 95% SLA compliance rate"),
                box(title = "SLA Performance by Reconciliation Type", status = "info", solidHeader = TRUE, width = 6,
                    plotlyOutput("sla_by_type", height = "320px"))
              ),
              fluidRow(
                box(title = "Reconciliation Detail Log", status = "primary", solidHeader = TRUE, width = 12,
                    DTOutput("recon_detail_table"), footer = "Red = SLA missed | Green = Within SLA")
              )
      ),
      
      # ===== TAB 5: COSO COVERAGE =====
      tabItem(tabName = "coso",
              fluidRow(column(12,
                              h2(icon("sitemap"), " COSO Framework Coverage Analysis"),
                              p(style = "color: #546E7A;", "Control coverage across all five COSO components")
              )),
              fluidRow(
                box(title = "Controls by COSO Component", status = "primary", solidHeader = TRUE, width = 6,
                    plotlyOutput("coso_coverage", height = "350px")),
                box(title = "Effectiveness by COSO Component", status = "success", solidHeader = TRUE, width = 6,
                    plotlyOutput("coso_effectiveness", height = "350px"))
              ),
              fluidRow(
                box(title = "COSO Heatmap — Exception Rate by Process", status = "warning", solidHeader = TRUE, width = 12,
                    plotlyOutput("coso_heatmap", height = "350px"),
                    footer = "Darker red = higher exception rate")
              ),
              fluidRow(
                box(title = "COSO Component Detail", status = "info", solidHeader = TRUE, width = 12,
                    DTOutput("coso_detail_table"))
              )
      ),
      
      # ===== TAB 6: WORKPAPER GENERATOR =====
      tabItem(tabName = "workpaper",
              fluidRow(column(12,
                              h2(icon("file-alt"), " SOX Test Script / Workpaper Generator"),
                              p(style = "color: #546E7A;", "Select a control to generate a formatted lead sheet")
              )),
              fluidRow(
                box(title = "Select Control", status = "primary", solidHeader = TRUE, width = 12,
                    selectInput("wp_control", "Choose Control:",
                                choices = setNames(rcm$control_id,
                                                   paste(rcm$control_id, "—", rcm$sub_process,
                                                         "(", rcm$control_owner, ")")), width = "100%"),
                    selectInput("wp_period", "Test Period:",
                                choices = c("Q1 2025", "Q2 2025", "Q3 2025", "Q4 2025"), selected = "Q4 2025"),
                    actionButton("generate_wp", "Generate Workpaper", icon = icon("file-alt"),
                                 style = "background-color: #1a237e; color: white; font-weight: bold; padding: 10px 30px;")
                )
              ),
              fluidRow(
                box(title = "Generated Test Workpaper (Lead Sheet)", status = "info", solidHeader = TRUE, width = 12,
                    uiOutput("workpaper_output"))
              )
      ),
      
      # ===== TAB 7: ABOUT =====
      tabItem(tabName = "about",
              fluidRow(column(12, h2(icon("info-circle"), " About This Project"))),
              fluidRow(
                box(title = "Project Overview", status = "primary", solidHeader = TRUE, width = 12,
                    div(style = "background-color: #E3F2FD; padding: 15px; border-left: 4px solid #1a237e; margin-bottom: 15px;",
                        h4(icon("info-circle"), " Portfolio Project Disclaimer", style = "color: #1a237e; margin-top: 0;"),
                        p("This dashboard uses ", strong("simulated banking controls data"),
                          " to represent a mid-size bank's SOX compliance program. No real company data is used.")
                    ),
                    h4("SOX Concepts Demonstrated"),
                    tags$ul(
                      tags$li(strong("Risk Control Matrix (RCM):"), " 20 controls mapped to processes, risks, COSO components, assertions"),
                      tags$li(strong("Test of Operating Effectiveness (TOE):"), " Realistic sample sizes, exception rates, deficiency classifications"),
                      tags$li(strong("Reconciliation SLA Monitoring:"), " Bank recon, suspense, GL-subledger SLA tracking"),
                      tags$li(strong("COSO Framework Coverage:"), " Gap analysis across all five components"),
                      tags$li(strong("Workpaper Generation:"), " Formatted lead sheets with test procedures and conclusions"),
                      tags$li(strong("Deficiency Tracking:"), " Exception documentation, remediation status, Audit Committee readiness")
                    ),
                    h4("Banking Operations Knowledge"),
                    tags$ul(
                      tags$li("Reconciliation controls (bank recon, intercompany, suspense, GL-subledger)"),
                      tags$li("Payment controls (wire transfers, ACH, vendor payments, check disbursements)"),
                      tags$li("Fund transfer controls (internal transfers, Fed funds, T+0 confirmation)"),
                      tags$li("Financial close (journal entries, month-end checklist, account certifications)"),
                      tags$li("IT General Controls (user access reviews, change management, backup/recovery)"),
                      tags$li("Segregation of duties and governance")
                    )
                )
              ),
              fluidRow(
                box(title = "Contact", status = "primary", width = 12,
                    div(style = "text-align: center; padding: 20px; background: linear-gradient(135deg, #1a237e 0%, #0d47a1 100%); color: white; border-radius: 5px;",
                        h3(style = "margin-top: 0;", "Daniel Kwaning"),
                        p("Master of Professional Studies in Analytics | Northeastern University — Roux Institute"),
                        p(icon("envelope"), " kwaning.d@northeastern.edu | ", icon("phone"), " (207) 332-5145"),
                        p(icon("map-marker"), " Canal Winchester, OH 43110 (Columbus Metro)"),
                        p(icon("certificate"), " CIPP/US In Progress | COSO/ICFR Framework Knowledge")
                    )
                )
              )
      )
    )
  )
)

# ==============================================
# SERVER
# ==============================================

server <- function(input, output, session) {
  
  # --- Reactive filtered data ---
  filtered_testing <- reactive({
    d <- testing_data
    if (input$filter_process != "All") d <- d %>% filter(process == input$filter_process)
    if (input$filter_period != "All")  d <- d %>% filter(test_period == input$filter_period)
    if (input$filter_status != "All")  d <- d %>% filter(test_status == input$filter_status)
    if (input$filter_coso != "All")    d <- d %>% filter(coso_component == input$filter_coso)
    d
  })
  
  filtered_rcm <- reactive({
    d <- rcm
    if (input$filter_process != "All") d <- d %>% filter(process == input$filter_process)
    if (input$filter_coso != "All")    d <- d %>% filter(coso_component == input$filter_coso)
    d
  })
  
  # ===== EXECUTIVE SUMMARY =====
  output$kpi_total_controls <- renderInfoBox({
    infoBox("Total Controls", nrow(filtered_rcm()), icon = icon("shield-alt"), color = "blue") })
  output$kpi_effectiveness <- renderInfoBox({
    ft <- filtered_testing() %>% filter(test_status != "Pending Review")
    eff <- if(nrow(ft) > 0) round(sum(ft$test_status == "Tested - Effective") / nrow(ft) * 100, 1) else 0
    infoBox("Effectiveness Rate", paste0(eff, "%"), icon = icon("check-circle"),
            color = if(eff >= 90) "green" else if(eff >= 80) "yellow" else "red") })
  output$kpi_exceptions <- renderInfoBox({
    infoBox("Exceptions", sum(filtered_testing()$test_status == "Tested - Exception Noted"),
            icon = icon("exclamation-triangle"), color = "orange") })
  output$kpi_deficiencies <- renderInfoBox({
    d <- sum(filtered_testing()$test_status == "Tested - Deficiency")
    infoBox("Deficiencies", d, icon = icon("times-circle"), color = if(d > 0) "red" else "green") })
  output$kpi_tests_completed <- renderInfoBox({
    infoBox("Tests Completed", sum(filtered_testing()$test_status != "Pending Review"),
            icon = icon("clipboard-check"), color = "blue") })
  output$kpi_pending_review <- renderInfoBox({
    p <- sum(filtered_testing()$test_status == "Pending Review")
    infoBox("Pending Review", p, icon = icon("hourglass-half"), color = if(p > 5) "yellow" else "green") })
  output$kpi_open_remediation <- renderInfoBox({
    o <- sum(filtered_testing()$remediation_status %in% c("Open", "In Progress"), na.rm = TRUE)
    infoBox("Open Remediations", o, icon = icon("wrench"), color = if(o > 5) "red" else "yellow") })
  output$kpi_recon_sla <- renderInfoBox({
    infoBox("Recon SLA Rate", paste0(recon_sla_rate, "%"), icon = icon("clock"),
            color = if(recon_sla_rate >= 95) "green" else if(recon_sla_rate >= 85) "yellow" else "red") })
  
  output$quarterly_results <- renderPlotly({
    d <- filtered_testing() %>% count(test_period, test_status) %>%
      mutate(test_status = factor(test_status,
                                  levels = c("Tested - Effective", "Pending Review", "Tested - Exception Noted", "Tested - Deficiency")))
    cols <- c("Tested - Effective"="#2E7D32", "Pending Review"="#1565C0",
              "Tested - Exception Noted"="#F57F17", "Tested - Deficiency"="#C62828")
    plot_ly(d, x=~test_period, y=~n, color=~test_status, type="bar", colors=cols) %>%
      layout(barmode="stack", xaxis=list(title="Quarter"), yaxis=list(title="Tests"),
             legend=list(orientation="h", y=-0.2)) })
  
  output$exception_by_process <- renderPlotly({
    d <- filtered_testing() %>% group_by(process) %>%
      summarise(total=n(), exceptions=sum(exceptions_found > 0),
                rate=round(exceptions/total*100, 1), .groups="drop") %>% arrange(desc(rate))
    plot_ly(d, x=~reorder(process, rate), y=~rate, type="bar",
            marker=list(color=~ifelse(rate>20,"#C62828",ifelse(rate>10,"#F57F17","#2E7D32")))) %>%
      layout(xaxis=list(title=""), yaxis=list(title="Exception Rate (%)")) })
  
  output$testing_progress <- renderPlotly({
    d <- filtered_testing() %>% group_by(test_period) %>%
      summarise(n=n(), .groups="drop") %>% mutate(cum=cumsum(n), target=seq(nrow(rcm), by=nrow(rcm), length.out=n()))
    plot_ly(d) %>%
      add_trace(x=~test_period, y=~cum, type="scatter", mode="lines+markers", name="Actual",
                line=list(color="#1a237e", width=3)) %>%
      add_trace(x=~test_period, y=~target, type="scatter", mode="lines", name="Target",
                line=list(color="#90A4AE", dash="dash")) %>%
      layout(xaxis=list(title="Quarter"), yaxis=list(title="Cumulative Tests"),
             legend=list(orientation="h", y=-0.2)) })
  
  output$remediation_overview <- renderPlotly({
    d <- filtered_testing() %>% filter(!is.na(remediation_status)) %>% count(remediation_status) %>%
      mutate(color=case_when(remediation_status=="Remediated"~"#2E7D32",
                             remediation_status=="In Progress"~"#F57F17", TRUE~"#C62828"))
    plot_ly(d, labels=~remediation_status, values=~n, type="pie",
            marker=list(colors=d$color), textinfo="label+value+percent") %>% layout(showlegend=FALSE) })
  
  output$open_exceptions_table <- renderDT({
    d <- filtered_testing() %>% filter(remediation_status %in% c("Open", "In Progress")) %>%
      select(control_id, process, sub_process, test_period, exceptions_found,
             exception_description, remediation_status, remediation_target) %>% arrange(remediation_target)
    datatable(d, options=list(pageLength=10, dom="tip"), rownames=FALSE,
              colnames=c("ID","Process","Sub-Process","Period","Exceptions","Description","Status","Target")) %>%
      formatStyle("remediation_status", backgroundColor=styleEqual(
        c("Open","In Progress"), c("#FFCDD2","#FFF9C4")), fontWeight="bold") })
  
  # ===== RCM TAB =====
  output$rcm_total <- renderInfoBox({ infoBox("Total Controls", nrow(filtered_rcm()), icon=icon("list"), color="blue") })
  output$rcm_key_controls <- renderInfoBox({ infoBox("Key Controls", sum(filtered_rcm()$key_control), icon=icon("key"), color="purple") })
  output$rcm_automated <- renderInfoBox({ infoBox("Automated", sum(filtered_rcm()$control_type=="Automated"), icon=icon("robot"), color="green") })
  output$rcm_processes <- renderInfoBox({ infoBox("Process Areas", n_distinct(filtered_rcm()$process), icon=icon("sitemap"), color="teal") })
  
  output$control_type_pie <- renderPlotly({
    d <- filtered_rcm() %>% count(control_type)
    plot_ly(d, labels=~control_type, values=~n, type="pie",
            marker=list(colors=c("#1a237e","#1565C0","#42A5F5"))) })
  output$controls_by_process <- renderPlotly({
    d <- filtered_rcm() %>% count(process) %>% arrange(desc(n))
    plot_ly(d, x=~reorder(process,n), y=~n, type="bar", marker=list(color="#1a237e")) %>%
      layout(xaxis=list(title=""), yaxis=list(title="Controls")) })
  output$control_frequency <- renderPlotly({
    d <- filtered_rcm() %>% count(frequency) %>% arrange(desc(n))
    plot_ly(d, x=~reorder(frequency,n), y=~n, type="bar", marker=list(color="#0d47a1")) %>%
      layout(xaxis=list(title=""), yaxis=list(title="Controls")) })
  output$rcm_table <- renderDT({
    d <- filtered_rcm() %>% select(control_id, process, sub_process, control_description,
                                   control_owner, frequency, control_type, coso_component, risk_description, assertion, key_control)
    datatable(d, options=list(pageLength=10, scrollX=TRUE, dom="tip"), rownames=FALSE,
              colnames=c("ID","Process","Sub-Process","Description","Owner","Frequency","Type","COSO","Risk","Assertion","Key")) %>%
      formatStyle("key_control", backgroundColor=styleEqual(c(TRUE,FALSE), c("#C8E6C9","#FFFFFF"))) })
  
  # ===== TESTING TRACKER =====
  output$testing_tracker_table <- renderDT({
    d <- filtered_testing() %>% select(control_id, process, sub_process, test_period, test_date,
                                       tester, reviewer, sample_size, exceptions_found, test_status, remediation_status, exception_description) %>%
      arrange(desc(test_date))
    datatable(d, options=list(pageLength=15, scrollX=TRUE, dom="ftip"), rownames=FALSE, filter="top",
              colnames=c("ID","Process","Sub-Process","Period","Date","Tester","Reviewer","Samples",
                         "Exceptions","Status","Remediation","Detail")) %>%
      formatStyle("test_status", backgroundColor=styleEqual(
        c("Tested - Effective","Pending Review","Tested - Exception Noted","Tested - Deficiency"),
        c("#C8E6C9","#BBDEFB","#FFF9C4","#FFCDD2")), fontWeight="bold") })
  
  output$exception_trend <- renderPlotly({
    d <- filtered_testing() %>% group_by(test_period) %>%
      summarise(rate=round(sum(exceptions_found>0)/n()*100,1), .groups="drop")
    plot_ly(d, x=~test_period, y=~rate, type="scatter", mode="lines+markers",
            line=list(color="#F57F17",width=3), marker=list(size=12,color="#F57F17")) %>%
      layout(xaxis=list(title="Quarter"), yaxis=list(title="Exception Rate (%)", range=c(0,50))) })
  output$sample_exception_scatter <- renderPlotly({
    plot_ly(filtered_testing(), x=~sample_size, y=~exceptions_found, color=~process,
            type="scatter", mode="markers", marker=list(size=10, opacity=0.7),
            text=~paste(control_id,"-",sub_process)) %>%
      layout(xaxis=list(title="Sample Size"), yaxis=list(title="Exceptions Found")) })
  
  # ===== RECONCILIATION SLA =====
  output$recon_total <- renderInfoBox({ infoBox("Total Recons", nrow(recon_sla), icon=icon("calculator"), color="blue") })
  output$recon_sla_pct <- renderInfoBox({
    r <- round(sum(recon_sla$within_sla)/nrow(recon_sla)*100,1)
    infoBox("SLA Compliance", paste0(r,"%"), icon=icon("check"), color=if(r>=95)"green"else"yellow") })
  output$recon_avg_days <- renderInfoBox({
    infoBox("Avg Days", round(mean(recon_sla$days_to_complete),1), icon=icon("calendar-day"), color="purple") })
  output$recon_open_items <- renderInfoBox({
    t <- sum(recon_sla$open_items)
    infoBox("Open Items", t, icon=icon("folder-open"), color=if(t>20)"red"else"yellow") })
  
  output$sla_by_month <- renderPlotly({
    d <- recon_sla %>% group_by(month_num, period) %>%
      summarise(rate=round(sum(within_sla)/n()*100,1), .groups="drop") %>% arrange(month_num)
    plot_ly(d) %>%
      add_trace(x=~period, y=~rate, type="bar",
                marker=list(color=~ifelse(rate>=95,"#2E7D32",ifelse(rate>=80,"#F57F17","#C62828"))), name="SLA Rate") %>%
      add_trace(x=~period, y=rep(95,nrow(d)), type="scatter", mode="lines",
                line=list(color="#C62828",dash="dash",width=2), name="95% Target") %>%
      layout(xaxis=list(title="", categoryorder="array", categoryarray=d$period),
             yaxis=list(title="SLA %", range=c(0,100)), legend=list(orientation="h",y=-0.2)) })
  output$sla_by_type <- renderPlotly({
    d <- recon_sla %>% group_by(recon_type) %>%
      summarise(total=n(), met=sum(within_sla), rate=round(met/total*100,1),
                avg=round(mean(days_to_complete),1), .groups="drop")
    plot_ly(d, x=~recon_type, y=~rate, type="bar",
            marker=list(color=~ifelse(rate>=95,"#2E7D32","#F57F17")),
            text=~paste0(rate,"% | Avg: ",avg," days"), textposition="outside") %>%
      layout(xaxis=list(title=""), yaxis=list(title="SLA %", range=c(0,110))) })
  output$recon_detail_table <- renderDT({
    d <- recon_sla %>% select(control_id, recon_type, period, sla_due_date, completed_date,
                              days_to_complete, within_sla, preparer, reviewer, open_items) %>% arrange(desc(sla_due_date))
    datatable(d, options=list(pageLength=12, scrollX=TRUE, dom="tip"), rownames=FALSE,
              colnames=c("ID","Type","Period","SLA Due","Completed","Days","Within SLA","Preparer","Reviewer","Open Items")) %>%
      formatStyle("within_sla", backgroundColor=styleEqual(c(TRUE,FALSE), c("#C8E6C9","#FFCDD2")), fontWeight="bold") })
  
  # ===== COSO COVERAGE =====
  output$coso_coverage <- renderPlotly({
    d <- filtered_rcm() %>% count(coso_component) %>% arrange(desc(n))
    plot_ly(d, x=~reorder(coso_component,n), y=~n, type="bar", marker=list(color="#1a237e")) %>%
      layout(xaxis=list(title=""), yaxis=list(title="Controls"), margin=list(b=120)) })
  output$coso_effectiveness <- renderPlotly({
    d <- filtered_testing() %>% group_by(coso_component) %>%
      summarise(total=n(), eff=sum(test_status=="Tested - Effective"),
                rate=round(eff/total*100,1), .groups="drop")
    plot_ly(d, x=~reorder(coso_component,rate), y=~rate, type="bar",
            marker=list(color=~ifelse(rate>=90,"#2E7D32",ifelse(rate>=80,"#F57F17","#C62828"))),
            text=~paste0(rate,"%"), textposition="outside") %>%
      layout(xaxis=list(title=""), yaxis=list(title="Effectiveness %", range=c(0,110)), margin=list(b=120)) })
  output$coso_heatmap <- renderPlotly({
    d <- filtered_testing() %>% group_by(coso_component, process) %>%
      summarise(rate=round(sum(exceptions_found>0)/n()*100,1), .groups="drop")
    dw <- d %>% pivot_wider(names_from=process, values_from=rate, values_fill=0)
    m <- as.matrix(dw[,-1]); rownames(m) <- dw$coso_component
    plot_ly(x=colnames(m), y=rownames(m), z=m, type="heatmap",
            colorscale=list(c(0,"#C8E6C9"),c(0.5,"#FFF9C4"),c(1,"#FFCDD2")),
            hovertemplate="COSO: %{y}<br>Process: %{x}<br>Rate: %{z}%<extra></extra>") %>%
      layout(xaxis=list(title=""), yaxis=list(title=""), margin=list(l=180, b=120)) })
  output$coso_detail_table <- renderDT({
    d <- filtered_testing() %>% group_by(coso_component) %>%
      summarise(Controls=n_distinct(control_id), Tests=n(),
                Effective=sum(test_status=="Tested - Effective"),
                Exceptions=sum(test_status=="Tested - Exception Noted"),
                Deficiencies=sum(test_status=="Tested - Deficiency"),
                `Eff %`=round(Effective/(Tests-sum(test_status=="Pending Review"))*100,1), .groups="drop") %>%
      arrange(desc(`Eff %`))
    datatable(d, options=list(dom="t", pageLength=10), rownames=FALSE) %>%
      formatStyle("Eff %", background=styleColorBar(c(0,100),"#C8E6C9"),
                  backgroundSize="98% 80%", backgroundRepeat="no-repeat", backgroundPosition="center") })
  
  # ===== WORKPAPER GENERATOR =====
  observeEvent(input$generate_wp, {
    ctrl <- rcm %>% filter(control_id == input$wp_control)
    test <- testing_data %>% filter(control_id == input$wp_control, test_period == input$wp_period) %>% slice(1)
    ss <- switch(as.character(ctrl$frequency),
                 "Daily"=25,"Weekly"=5,"Monthly"=2,"Quarterly"=1,"Per Occurrence"=25,"Annual"=1)
    
    procs <- paste0(
      "1. Obtain the ", input$wp_period, " population listing from ", ctrl$control_owner, ".\n",
      "2. Verify population is complete and accurate (IPE validation).\n",
      "3. Select ", ss, " sample(s) using [random/systematic] sampling.\n",
      "4. For each sample, inspect documentation:\n",
      "   a. Verify control activity was performed as described.\n",
      "   b. Confirm appropriate authorization/approval is evidenced.\n",
      "   c. Validate timeliness per required frequency.\n",
      "   d. Check supporting documentation retained per policy.\n",
      "5. Document results for each sample. Note exceptions.\n",
      "6. Conclude on operating effectiveness.")
    
    output$workpaper_output <- renderUI({
      div(class="workpaper-box",
          div(class="wp-header",
              h3(style="margin:0;", "SOX TEST WORKPAPER — LEAD SHEET"),
              p(style="margin:5px 0 0 0; font-size:11px;", "CONFIDENTIAL — For Internal Audit Use Only")),
          h4("SECTION A: CONTROL IDENTIFICATION"),
          div(class="wp-field", span(class="wp-label","Company:"), "First National Bank (Simulated)"),
          div(class="wp-field", span(class="wp-label","Fiscal Year:"), "FY2025"),
          div(class="wp-field", span(class="wp-label","Workpaper Ref:"), paste0("WP-",ctrl$control_id,"-",gsub(" ","",input$wp_period))),
          div(class="wp-field", span(class="wp-label","Control ID:"), ctrl$control_id),
          div(class="wp-field", span(class="wp-label","Process:"), ctrl$process),
          div(class="wp-field", span(class="wp-label","Sub-Process:"), ctrl$sub_process),
          div(class="wp-field", span(class="wp-label","Control Owner:"), ctrl$control_owner),
          div(class="wp-field", span(class="wp-label","Frequency:"), ctrl$frequency),
          div(class="wp-field", span(class="wp-label","Type:"), ctrl$control_type),
          div(class="wp-field", span(class="wp-label","Key Control:"), ifelse(ctrl$key_control,"Yes","No")),
          div(class="wp-field", span(class="wp-label","COSO Component:"), ctrl$coso_component),
          div(class="wp-field", span(class="wp-label","Assertion(s):"), ctrl$assertion),
          hr(), h4("SECTION B: CONTROL & RISK"),
          div(class="wp-field", span(class="wp-label","Control Description:"), ctrl$control_description),
          div(class="wp-field", span(class="wp-label","Risk Addressed:"), ctrl$risk_description),
          hr(), h4("SECTION C: TEST PARAMETERS"),
          div(class="wp-field", span(class="wp-label","Test Period:"), input$wp_period),
          div(class="wp-field", span(class="wp-label","Test Method:"), "Inquiry + Inspection + Reperformance"),
          div(class="wp-field", span(class="wp-label","Population Size:"), "[From control owner]"),
          div(class="wp-field", span(class="wp-label","Sample Size:"), ss),
          div(class="wp-field", span(class="wp-label","Sampling Method:"), if(ss>1)"Random"else"Single instance"),
          hr(), h4("SECTION D: TEST PROCEDURES"),
          pre(style="background:#F5F5F5; padding:10px; font-size:11px;", procs),
          hr(), h4("SECTION E: TEST RESULTS"),
          if (nrow(test) > 0) {
            tagList(
              div(class="wp-field", span(class="wp-label","Test Date:"), as.character(test$test_date)),
              div(class="wp-field", span(class="wp-label","Tester:"), test$tester),
              div(class="wp-field", span(class="wp-label","Reviewer:"), test$reviewer),
              div(class="wp-field", span(class="wp-label","Samples Tested:"), test$sample_size),
              div(class="wp-field", span(class="wp-label","Exceptions Found:"), test$exceptions_found),
              if (!is.na(test$exception_description))
                div(class="wp-field", span(class="wp-label","Exception Detail:"),
                    span(style="color:#C62828; font-weight:bold;", test$exception_description))
            )
          } else { p(style="color:#1565C0;", "[Testing not yet performed for this period]") },
          hr(), h4("SECTION F: CONCLUSION"),
          if (nrow(test) > 0) {
            div(class="wp-field", span(class="wp-label","Conclusion:"),
                span(style=paste0("font-weight:bold; color:",
                                  ifelse(test$test_status=="Tested - Effective","#2E7D32","#C62828"),";"), test$test_status))
          } else { p("[Pending testing]") },
          hr(),
          div(style="text-align:right; font-size:10px; color:#90A4AE;",
              paste("Generated:", format(Sys.time(), "%B %d, %Y %I:%M %p"),
                    "| Ref:", paste0("WP-",ctrl$control_id,"-",gsub(" ","",input$wp_period))))
      )
    })
  })
}

# ==============================================
# RUN
# ==============================================
shinyApp(ui = ui, server = server)