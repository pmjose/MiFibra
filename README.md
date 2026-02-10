# Snowflake Intelligence Demo – MiFibra Peru (Fiber Optic ISP)

This repo configures a Snowflake Intelligence demo themed for **MiFibra**, using synthetic structured data plus reports in `unstructured_docs` to ground answers in fiber optic operations, subscriber growth, network coverage, and customer service.

## About MiFibra (real-world facts)
- Peru's fastest fiber optic internet provider recognized by **Ookla Speedtest Awards** as the fastest, best rated in Peru, and most stable network in Latin America (H1 2025).
- **100% fiber optic** infrastructure using **XGS-PON technology** delivering speeds from **500 Mbps to 5,000 Mbps**.
- Company: **Cala Servicios Integrales S.A.C.**

### Product Lines
**Internet Hogar (Residential):**
- 500 Mbps - S/79.90/mes (promo S/59.90)
- 1500 Mbps - S/99.90/mes (promo S/59.90) [RECOMENDADO]
- 2500 Mbps - S/139.90/mes (includes TV + L1MAX)
- 5000 Mbps - S/199.90/mes (includes TV + L1MAX)

**Dúos Internet + TV:**
- All plans include **MiFibra TvGo** (80+ channels) + **L1MAX** deportes

**Internet Empresas (Business):**
- Professional 1500 Mbps (simétrico)
- Business 2500 Mbps
- Enterprise 5000 Mbps
- Enterprise Plus 5000 Mbps (simétrico)

**Equipment:** WiFi 5, WiFi 6, Mesh routers, Router Mikrotik (empresas)

**Services:** IP Pública Fija (S/15/mes), Firewall en la nube, Monitoreo 24/7, SLA empresarial

### Contact
- **Hogar**: 0 800 74 007 | WhatsApp: 923 418 300
- **Empresas**: 01 - 646 2222 | WhatsApp: 908 863 682
- Website: [mifibra.pe](https://www.mifibra.pe/)

## What's included
- **SQL setup script**: `sql_scripts/demo_setup.sql` builds `MIFIBRA_AI_DEMO` and loads sample data + documents into stages.
- **Structured sample data** (`demo_data/`): synthetic fact/dim tables to model revenue, subscriber metrics, service performance, campaigns, and workforce. Segments reflect MiFibra's business (Residential, Enterprise).
- **Unstructured reports** (`unstructured_docs/`): narrative files used by Cortex Search. Notable references:
  - Finance: Financial reports, revenue mix, subscriber growth, ARPU analysis.
  - Strategy: Board presentations, market position, competitive analysis.
  - Network: Fiber coverage, network performance, expansion plans.
  - Demo: Demo scripts for CEO, CFO, CMO personas.

## Quick start
1. Open `sql_scripts/demo_setup.sql` in a Snowflake worksheet (use `ACCOUNTADMIN` to create integrations, then the `MiFibra_Demo` role created by the script).
2. Run the script end-to-end to create the database, schema, stage, load CSVs, and register Cortex Search services and the `MiFibra_Executive_Agent`.
3. Verify objects:
   - `SHOW TABLES IN MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA;`
   - `SHOW SEMANTIC VIEWS;`
   - `SHOW CORTEX SEARCH SERVICES;`

## Suggested prompts (ISP context)
- **Subscriber metrics**: "What is our total subscriber count by region and plan type?"
- **Revenue & ARPU**: "Show monthly recurring revenue (MRR) and ARPU trends by segment."
- **Product performance**: "Which internet plans (500Mbps to 5000Mbps) have the highest adoption?"
- **Churn analysis**: "What is our churn rate by plan type and region?"
- **Marketing ROI**: "Which marketing campaigns generated the most new subscribers?"
- **Competitive position**: "How do our speeds and pricing compare to Claro and Movistar?"

## Personas
- **CEO**: Strategy, subscriber growth, market share, competitive position.
- **CFO**: Revenue, ARPU, churn, MRR/ARR, cost per acquisition.
- **COO/CTO**: Network coverage, fiber deployment, uptime SLAs, capacity planning.
- **CMO**: Campaign performance, lead generation, brand awareness, customer acquisition cost.

## Notes
- Structured data is synthetic but aligned to ISP business metrics; unstructured reports supply realistic narrative context.
- Update or replace CSVs/documents as needed—`sql_scripts/demo_setup.sql` will stage whatever is present in `demo_data/` and `unstructured_docs/`.
- Guardrails in the agent are tuned to only answer questions about MiFibra's business (fiber internet, TV services, network coverage, customer service).
- Currency is **Peruvian Soles (S/)** throughout.
