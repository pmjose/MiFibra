# IT Ops, Vendors, and BI Adoption (Gamma)

Use these reference points for Snowflake Intelligence questions in the Gamma demo. All amounts in PEN unless stated.

## IT Operational Expenses (finance_transactions)
- Use `FINANCE_SEMANTIC_VIEW` and slice by `account_type`, `department_name`, `vendor_name` / `vendor_dim.vertical`, and `product_category_dim.category_name`.
- Suggested IT opex buckets (map by vendor vertical + product category):
  - **Connectivity & Carrier Services:** Connectivity Provider, Voice Provider, Mobile Partner, Network Equipment.
  - **Cloud & Platform:** Cloud Provider, Platform Partner, CRM Partner, ITSM Partner, CX Platform.
  - **Security & Compliance:** Security Partner.
  - **Hardware & Endpoints:** Hardware Partner.
  - **Contact Centre & Fibra Partners:** Contact Centre, Fibra Partner.
- Metrics: total spend, average transaction, transaction count, vendor, department, month/quarter.
- Example prompt: “Break down IT opex by connectivity, cloud/platform, security, and hardware for last quarter (PEN).”

**Illustrative Q4 IT opex (PEN):**
- Connectivity & Carrier Services: S/12.9M
- Cloud & Platform: S/8.1M
- Security & Compliance: S/3.4M
- Hardware & Endpoints: S/4.7M
- Contact Centre & Fibra Partners: S/2.6M

**Illustrative Q4 total IT opex:** S/31.7M

## Top Vendors and Supplier Risk (vendor_dim + finance_transactions)
- Largest tech spend: sum `amount` by `vendor_name`; join to `vendor_dim` for `vertical`.
- Supplier exposure: % of spend by vendor and by vertical; flag single-source categories (Cloud Provider, Security Partner, Contact Centre).
- Example prompts:
  - “Top 10 vendors by IT spend last quarter; show PEN, category, and % of total.”
  - “Which vendor categories are single-source, and what % of total IT spend do they represent?”

**Illustrative top vendors (Q4, PEN):**
- Microsoft Peru: S/4.1M (Platform Partner)
- Amazon Web Services Peru: S/3.5M (Cloud Provider)
- Cisco Peru: S/2.6M (Network Equipment)
- Movistar Openreach: S/2.2M (Connectivity Provider)
- Claro Business: S/1.9M (Connectivity Provider)

**Supplier risk notes (illustrative):**
- Cloud spend concentrated in top 2 providers (medium exposure).
- Security tooling concentrated in one primary partner (medium exposure).
- Connectivity spend spread across multiple carriers (lower exposure).

## Tech Investment vs Revenue (sales_fact + finance_transactions + product_dim)
- Correlate platform and connectivity spend vs revenue by product category:
  - Spend: `finance_transactions` joined to `product_dim` + `product_category_dim`, filtered to `account_type = 'Expense'`.
  - Revenue: `sales_fact` joined to `product_dim` + `product_category_dim`.
  - Use the same time window (e.g., last two quarters) and segment splits (vertical, region).
- Example prompts:
  - “Compare spend vs revenue by product category for the last two quarters; show correlation and PEN.”
  - “Revenue per S/ of platform spend by customer vertical (SMB, Enterprise, Public Sector, Partner).”

**Illustrative spend vs revenue (Q4, PEN):**
- Connect: S/6.8M spend vs S/52.0M revenue (7.6x)
- Enable: S/4.9M spend vs S/31.5M revenue (6.4x)
- Connectivity: S/3.7M spend vs S/18.2M revenue (4.9x)
- Experience: S/2.6M spend vs S/14.0M revenue (5.4x)

## Customer Segment Prompts (aligned to dataset)
- Use `customer_dim.vertical` (SMB, Enterprise, Public Sector, Partner) and `customer_dim.industry`.
- Example prompts:
  - “Show revenue and units by customer vertical and industry for the last two quarters.”
  - “Which industries show the highest attach of Connect vs Experience products this quarter?”

## Analytics / BI Adoption (usage proxy)
- Use available proxies (counts over time):
  - Marketing: campaigns executed (`marketing_campaign_fact`), impressions, leads.
  - Sales: opportunities created/closed (`sf_opportunities`), sales transaction counts (`sales_fact`).
  - Finance: transaction counts and approval cycle time (`finance_transactions`).
  - HR: headcount and attrition counts (`hr_employee_fact`).
- Example prompts:
  - “Show trend of campaigns, leads, and impressions by month.”
  - “Show opportunities created vs closed by month and region.”
  - “Count finance transactions and average approval time by month; show top departments.”
  - “Show headcount and attrition by department over the last 12 months.”

**Illustrative BI adoption snapshot (Q4):**
- Marketing campaigns run: 34 (avg 1.1/week)
- Leads generated: 5,400
- Sales opportunities created: 1,850; closed-won: 620
- Finance transactions processed: 3,100; average approval time: 4.0 days
- HR records updated: 2,700 (monthly)

## How to Query via Agent
- Use:
  - `Query Finance Datamart` for spend by category/vendor (`FINANCE_SEMANTIC_VIEW`).
  - `Query Sales Datamart` for revenue by product/vertical/region (`SALES_SEMANTIC_VIEW`).
  - `Search_finance_docs` for policy and vendor contract context.
  - `Search_strategy_docs` for market positioning context.
  - `Search_network_docs` for connectivity and coverage context.
- Mention time windows (last quarter/6 months) and segments (verticals, regions) to keep answers tight.
