# Plan: Transform Eutelsat Demo to MiFibra Peru Demo

## Overview
Transform the complete Snowflake Intelligence demo from Eutelsat UK (satellite communications) to MiFibra Peru (fiber optic ISP).

## Current State Analysis

The existing demo contains:
- **20 CSV data files** themed for Eutelsat UK
- **UK geographic data**: London, Manchester, Scotland, Wales, etc.
- **UK company names**: "Harrison Martin Ltd", "Lee Turner Solutions", etc.
- **Satellite/UCaaS products**: "Horizon Cloud Phone System", "SIP Trunks", "Contact Centre"
- **UK vendors**: Microsoft UK, Cisco UK, BT Openreach
- **EUR/GBP currency context**

## Target State: MiFibra Peru

### Company Profile
- **Name**: MiFibra (Cala Servicios Integrales S.A.C.)
- **Industry**: Fiber optic ISP for homes and businesses
- **Location**: Peru
- **Currency**: Peruvian Soles (S/)
- **Products**: Internet (500Mbps-5000Mbps), TV Digital, WiFi equipment
- **Recognition**: Ookla Speedtest Awards - fastest network in Peru

---

## Files to Transform

### 1. README.md
**Changes**:
- Replace all Eutelsat references with MiFibra
- Update company description to fiber optic ISP
- Change currency from EUR to PEN (Peruvian Soles)
- Update sample questions for ISP context

### 2. region_dim.csv (12 rows)
**Current**: UK regions (London, South East, Scotland, Wales, etc.)

**New**: Peruvian departments
```
400,Lima
401,Arequipa
402,La Libertad
403,Cusco
404,Piura
405,Lambayeque
406,Cajamarca
407,Junin
408,Ancash
409,Ica
410,Callao
411,Loreto
```

### 3. customer_dim.csv (~1000 rows)
**Current**: UK company names with UK addresses

**New**: Peruvian companies
- Industries: Retail, Mining, Agriculture, Hospitality, Education, Healthcare, Banking, Manufacturing
- Cities: Lima, Arequipa, Trujillo, Cusco, Chiclayo, Piura, etc.
- Company naming: "Grupo [Surname]", "[Name] Peru SAC", "Corporacion [Name]", etc.
- Peruvian surnames: Garcia, Rodriguez, Martinez, Quispe, Huaman, Chavez, etc.

### 4. product_dim.csv (65 rows)
**Current**: Eutelsat UCaaS/satellite products

**New**: MiFibra ISP products organized by category:

| Category | Products |
|----------|----------|
| Internet Hogar | Plan 500 Mbps, Plan 1500 Mbps, Plan 2500 Mbps, Plan 5000 Mbps |
| Internet Empresas | Fibra Empresarial 100, Fibra Empresarial 500, Fibra Dedicada |
| TV Digital | MiFibra TV Basico (80 canales), MiFibra TV Premium, L1MAX |
| Equipamiento | Router WiFi 5, Router WiFi 6, Mesh WiFi, ONT Fibra |
| Servicios | Instalacion Estandar, Instalacion Express, Soporte Premium |
| Paquetes | Duo Internet+TV, Trio Empresarial |

### 5. vendor_dim.csv (51 rows)
**Current**: UK technology vendors

**New**: LatAm/Peru vendors
- Network equipment: Huawei, ZTE, Nokia, Furukawa
- Cloud providers: AWS, Google Cloud, Azure
- Content: DirecTV, Netflix, Disney+, L1MAX
- Equipment: TP-Link, Ubiquiti, Mikrotik
- Local partners: Claro, Movistar (competitors), local ISPs

### 6. location_dim.csv (31 rows)
**Current**: UK office locations

**New**: Peru locations
```
900,Sede Central - Lima
901,Oficina Miraflores
902,Centro Operaciones Callao
903,Oficina Arequipa
904,Oficina Trujillo
905,Oficina Cusco
...
```

### 7. sql_scripts/demo_setup.sql
**Changes**:
- Database: `EUTELSAT_AI_DEMO` → `MIFIBRA_AI_DEMO`
- Schema: `EUTELSAT_SCHEMA` → `MIFIBRA_SCHEMA`
- Role: `Eutelsat_Demo` → `MiFibra_Demo`
- Warehouse: `EUTELSAT_DEMO_WH` → `MIFIBRA_DEMO_WH`
- Agent: `Eutelsat_Executive_Agent` → `MiFibra_Executive_Agent`
- All comments and instructions updated for ISP context

### 8. unstructured_docs/ (all folders)
**Changes needed**:
- `/demo/` - Update demo scripts for MiFibra personas (CEO, CFO, CMO)
- `/finance/` - Update financial reports for ISP metrics (ARPU, churn, MRC)
- `/strategy/` - Update market position for Peru telecom market
- `/network/` - Replace satellite content with fiber network coverage
- Key facts file with MiFibra data (Ookla awards, coverage, speeds)

---

## Data Relationships to Preserve

The following relationships must remain consistent:
- `sales_fact.csv` references: customer_key, product_key, region_key, vendor_key
- `finance_transactions.csv` references the same dimensions
- `marketing_campaign_fact.csv` references: campaign_key, product_key, region_key
- `hr_employee_fact.csv` references: employee_key, department_key, job_key, location_key

**Approach**: Update dimension tables first, keeping key values intact so fact tables remain valid.

---

## Currency Considerations

- Change from EUR/GBP to PEN (Peruvian Soles)
- Typical ISP amounts in Peru:
  - Residential plans: S/59.90 - S/199.90/month
  - Business plans: S/200 - S/2000+/month
- Sales amounts in fact tables may need scaling adjustment

---

## Semantic View Updates

Update all semantic views in `demo_setup.sql`:
- `FINANCE_SEMANTIC_VIEW` - ISP financial metrics
- `SALES_SEMANTIC_VIEW` - Subscriptions, MRC, activations
- `MARKETING_SEMANTIC_VIEW` - Digital campaigns, lead gen
- `HR_SEMANTIC_VIEW` - Peru workforce structure

---

## Agent Guardrails

Update agent instructions to:
- Only answer MiFibra business questions
- Focus on: fiber coverage, internet speeds, TV packages, customer service
- Competitors: Claro, Movistar, Entel, Win
- Market context: Peru telecom industry
