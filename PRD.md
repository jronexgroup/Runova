# Runova Shop --- Product Requirements Document (PRD)

**Version:** 1.1\
**Status:** Approved Architecture & Technical Blueprint\
**Product:** Runova Shop\
**Primary market:** India\
**Currency:** INR (₹)

------------------------------------------------------------------------

## 1. Product Overview

Runova Shop is a shop-management system for a multi-service retail and
repair business. It centralizes retail inventory and sales, print and
photocopy services, mobile repair jobs, expense recording, billing, and
business reports.

The product consists of two applications:

1.  **Runova Shop Main App** --- used by the shop owner and authorized
    administrators to manage the business and all financial operations.
2.  **Runova Repair Worker App** --- a smaller, separate application
    used by repair workers to register repair jobs and update their work
    progress.

Both applications use a shared backend and synchronized business
records. Workers must not be able to perform financial operations or
mark repairs as delivered.

This PRD defines product scope and business requirements. It does not
prescribe screen layouts or visual design.

## 2. Goals

-   Record shop transactions consistently across supported business
    areas.
-   Manage retail products, purchases, stock, and sales.
-   Calculate service prices automatically where pricing rules are
    defined.
-   Record mobile repair jobs and track their progress.
-   Keep financial controls in the Main App.
-   Generate invoices for applicable sales and completed repair
    deliveries.
-   Calculate revenue, costs, and profit from recorded data.
-   Preserve transaction history and prevent stock or financial
    inconsistencies.

## 3. Non-Goals for Version 1.0

The following are explicitly outside the initial release:

-   Cyber café and online form-filling workflows, including government
    application services.
-   Integration with Runova Diary for financial transactions. A future
    read-only integration may be considered.
-   Advanced accounting, tax filing, payroll, or full ERP functionality
    unless separately specified.
-   Unconfirmed workflows such as customer loyalty, online ordering, or
    payment gateway integration.

## 4. Users and Roles

### 4.1 Admin / Shop Owner

The Admin uses the Main App and has authority to:

-   Manage products, suppliers, purchases, and stock.
-   Record sales and applicable invoices.
-   Manage print and photocopy transactions.
-   View and manage repair jobs.
-   Record repair parts costs and customer payments.
-   Confirm repair delivery and generate repair invoices.
-   Record general expenses.
-   View reports and business records.
-   Manage worker accounts and permissions.

### 4.2 Repair Worker

The Worker uses the separate Worker App and can:

-   Register a new repair service.
-   Record the device name and reported/inspected problems.
-   Use speech-to-text to enter descriptions.
-   Self-assign / claim an unassigned repair job.
-   View only repair jobs assigned to or claimed by them (architected for future multi-worker scalability).
-   Update repair status to the allowed intermediate states (`Inspected`, `Part Bought`, `Done`).

The Worker cannot:

-   Register repair parts costs.
-   Record customer payments.
-   Access business financial reports.
-   Manage retail inventory or sales.
-   Generate invoices.
-   Mark a repair as delivered.

The backend must enforce these restrictions. Hiding controls in the
interface alone is insufficient.

## 5. Application and Module Scope

### 5.1 Main App Modules

1.  Print & Xerox
2.  Retail Management
    -   General Accessories
    -   Mobile Covers
    -   Tempered Glass
    -   Small Items
    -   Other Retail Products
3.  Mobile Repair Management
4.  Expenses
5.  Bills and Transaction Records
6.  Financial Reports
7.  User and Worker Access Management

### 5.2 Worker App Modules

1.  Repair Registration
2.  Repair Job List / Job Details
3.  Repair Status Updates
4.  Speech-to-Text input for descriptions

The exact navigation and screen structure are design decisions and are
not defined by this PRD.

------------------------------------------------------------------------

## 6. Functional Requirements

## 6.1 Print & Xerox

The system must support the following service types.

### 6.1.1 Xerox

Pricing:

    Number of copies   Total price
  ------------------ -------------
                   1            ₹3
                   2            ₹5
                   3            ₹8
                   4           ₹10
                   5           ₹13
                   6           ₹15
                   7           ₹18
                   8           ₹20

Pricing rule:

`total_price = 5 × floor(quantity / 2) + 3 × (quantity mod 2)`

Requirements:

-   The user enters the quantity.
-   The system calculates the total automatically.
-   Customer information is not required.
-   Each entry must be recorded as a transaction.
-   Revenue must be included in reports.

### 6.1.2 Normal Print

The supported options and rates are:

  Print type                  Price per copy
  ------------------------- ----------------
  Image --- Black & White                ₹10
  PDF --- Black & White                   ₹5
  Image --- Colour                       ₹15
  PDF --- Colour                         ₹10

Requirements:

-   The first option, Image --- Black & White, is selected by default.
-   The user selects the print type and enters quantity.
-   The system calculates the total automatically.
-   Each transaction is recorded.

### 6.1.3 Passport-Size Photo Print

Pricing:

    Quantity   Total price
  ---------- -------------
           3           ₹20
           6           ₹35
           9           ₹50
          12           ₹65
          15           ₹80

Requirements:

-   Minimum quantity is 3.
-   Quantity must be a multiple of 3.
-   The first group of 3 costs ₹20.
-   Each additional group of 3 costs ₹15.
-   Invalid quantities must be rejected.

Pricing rule:

`total_price = 20 + 15 × ((quantity / 3) - 1)`

This formula applies only when quantity is a valid multiple of 3 and
quantity is at least 3.

### 6.1.4 Large Document Print with Lamination

-   Price: ₹50 per document.
-   The user enters quantity.
-   The system calculates the total.
-   Each transaction is recorded.

### 6.1.5 Print & Xerox Expenses and Invoicing

Paper, ink, and other operating costs are recorded separately in the
Expenses module. Reports must distinguish recorded revenue from recorded
expenses.

**Receipts & Invoicing policy:** Print and Xerox transactions do NOT generate customer tax invoices. Instead, each transaction is logged immediately for audit/revenue reporting and produces a lightweight POS receipt record (e.g. `#PX-8842` format) with payment method (Cash vs. UPI/QR) and reprint support.

------------------------------------------------------------------------

## 6.2 Retail Management

Retail supports product registration, stock purchases, sales, and
transaction history.

### 6.2.1 General Accessories

Examples include chargers, cables, speakers, headphones, earbuds,
smartwatches, and similar accessories.

Product registration must support:

-   Product ID
-   Category
-   Product name
-   Wholesaler / supplier
-   Buy price
-   Default sell price
-   Quantity added

Requirements:

-   The supplier list must be manageable; it must not be limited to a
    fixed number of suppliers.
-   New purchases of an existing product increase its stock.
-   Purchase records must be retained.
-   The system must retain purchase cost information for profit
    calculations.
-   The product's default selling price is used during sale unless the
    Admin changes the actual selling price.

### 6.2.2 General Product Sales

Requirements:

-   Admin can search for and select a product.
-   Default sale quantity is 1.
-   The default selling price is prefilled.
-   Admin can change the actual selling price to support bargaining.
-   A successful sale decreases stock.
-   A sale record is created.
-   Normal accessories generally generate an invoice.
-   Customer name, phone number, and address are optional for billed
    sales.

A sale must not complete if the requested quantity exceeds available
stock.

### 6.2.3 Mobile Covers

Mobile covers use a separate product and stock model rather than the
general accessories form.

Each cover stock group has:

-   A Base Name
-   One or more linked / compatible model names
-   Wholesaler
-   Buy price
-   Default sell price (pre-filled at sale, supports cashier override for bargaining)
-   Quantity added

**Shared stock requirement:**

-   All linked models under one Base Name share the same stock quantity.
-   Selling a cover through any linked model reduces the shared stock
    for that Base Name.
-   The system must not create independent stock quantities for linked
    model names.

**Cover Finder requirement:**

A separate search capability must accept a model or product name and
find matching cover records. AI-assisted or fuzzy name matching may help
identify likely matches, but inventory truth must always come from the
database.

The result must distinguish:

-   `Not Found` --- no matching cover record exists.
-   `Out of Stock — 0` --- a matching cover record exists but its stock
    is zero.
-   Available --- a matching cover record exists and has stock.

If the match is uncertain, the system should present possible matches
rather than assert an incorrect match.

Mobile cover sales:

-   Do not generate an invoice.
-   Do not collect customer information.
-   Must still create a sale record and update stock.

### 6.2.4 Tempered Glass

Tempered glass is managed as bulk stock by product/type, not as
individually unique units.

Each stock item must support:

-   Product/type name
-   Quantity available
-   Price per piece
-   Stock and sale/usage history

Requirements:

-   Price is calculated per piece.
-   The user records the quantity sold or used.
-   Revenue is `quantity × price_per_piece`.
-   Stock decreases by the quantity sold or used.
-   No invoice is generated.
-   No customer information is collected.
-   The sale/usage record is retained.

### 6.2.5 Small Items

Small low-cost items, typically ₹1--2 items, have a dedicated list or
category.

Requirements:

-   Items are recorded by product name and applicable stock/pricing
    information.
-   Sales update stock and create sale records.
-   No invoice is generated.
-   No customer information is collected.

### 6.2.6 Other Retail Products

The system should allow additional retail categories and products to be
added without redesigning the core inventory model.

Unless a product category has a specifically defined exception, it
follows the general accessories purchase and sale rules.

### 6.2.7 Invoicing Rules Across Modules

  Transaction / Product type   Invoice   Customer information   Receipt / Record
  ---------------------------- --------- ---------------------- ----------------------------
  Normal accessories           Yes       Optional               Invoice Record + PDF
  Charger without guarantee    No        None                   Sale Transaction Record
  Mobile covers                No        None                   Sale Transaction Record
  Tempered glass               No        None                   Sale Transaction Record
  Small items                  No        None                   Sale Transaction Record
  Print & Xerox POS            No        None                   POS Thermal Receipt (PX-#)
  Delivered Mobile Repair      Yes       Required at Delivery   Repair Invoice Record + PDF

"No invoice" does not mean "no transaction." Every sale must be recorded
and stock/revenue must be updated.

------------------------------------------------------------------------

## 6.3 Mobile Repair Management

Mobile repair management is shared between the Main App and Worker App.

### 6.3.1 Repair Registration

A Worker can register a new repair job.

Required fields:

-   Device name
-   Customer-reported problem
-   Inspection findings / problem identified after inspection
-   Description

Optional fields:

-   Customer name
-   Customer mobile number

System-generated fields:

-   Repair ID
-   Registration date and time
-   Worker ID
-   Initial status

Speech-to-text should be available to help the Worker enter problem
descriptions. The recognized text must be reviewable and editable before
submission.

On successful registration, the repair job must become available in the
Main App.

### 6.3.2 Repair Status Workflow

The four defined statuses are:

1.  `Inspected`
2.  `Part Bought`
3.  `Done`
4.  `Delivered`

Worker permissions:

-   Worker may update the job to `Inspected`, `Part Bought`, or `Done`.
-   Worker may not set `Delivered`.

Main App permissions:

-   Admin can view and manage repair jobs.
-   Admin alone confirms delivery.

Every status change must record:

-   Repair ID
-   Previous status
-   New status
-   Actor / user ID
-   Timestamp

The system must prevent delivery until the repair is marked `Done`.

### 6.3.3 Repair Parts and Costs

The Admin records parts costs in the Main App.

A repair may have one or more part-cost entries. Each entry should
record the part description and cost. The system calculates the total
recorded repair cost.

Example:

-   Device: Redmi Note 8 Pro
-   Problem: Phone does not turn on
-   Inspection finding: Battery damaged
-   Part: Replacement battery
-   Part cost: ₹700

Workers cannot create or edit these financial cost records.

### 6.3.4 Repair Delivery and Payment

Delivery is performed only in the Main App.

Before confirming delivery:

-   Repair status must be `Done`.
-   Customer name must be provided or confirmed at delivery.
-   Total amount received from the customer must be entered.

Customer phone number remains optional unless a later requirement
changes this.

On successful delivery, the system must:

1.  Record the customer name.
2.  Record the total customer payment.
3.  Generate a repair invoice.
4.  Mark the repair as `Delivered`.
5.  Record the delivery actor and timestamp.
6.  Make the repair's financial result available to reports.

Duplicate delivery must be prevented.

### 6.3.5 Repair Profit

Basic calculation:

`repair_net_profit = customer_payment - total_recorded_repair_cost`

Example:

  Item                              Amount
  ------------------------------- --------
  Customer payment                  ₹1,000
  Recorded battery cost               ₹700
  Net profit before other costs       ₹300

If multiple parts are recorded, their costs are summed.

The calculation must not imply that unrecorded costs have been included.

### 6.3.6 Repair Invoice

A repair invoice is generated when the Admin confirms delivery.

Proposed invoice data:

-   Invoice ID
-   Repair ID
-   Customer name
-   Customer phone number, if available
-   Device name
-   Customer-reported problem
-   Inspection finding / repair description
-   Total amount charged / received
-   Invoice date

**Open requirement:** It has not been decided whether the invoice should
itemize parts and service charges separately or show only the total
customer charge. Internal parts cost must not be exposed as a
customer-facing cost by default.

------------------------------------------------------------------------

## 6.4 Expenses Management

The Main App must support recording general business expenses.

Proposed fields:

-   Expense ID
-   Expense title
-   Category
-   Amount
-   Date and time
-   Optional description
-   Optional related module/reference

Initial categories may include:

-   Printing supplies
-   Shop maintenance
-   General expense
-   Other expense

Repair part costs are recorded against their repair jobs. They must not
also be counted as general expenses unless a deliberate accounting
adjustment is made. This prevents double counting.

------------------------------------------------------------------------

## 6.5 Financial Reports

The system must provide date-filtered business reports, including daily,
weekly, and monthly summaries.

Revenue sources:

-   Retail sales
-   Print and Xerox transactions
-   Repair customer payments

Cost sources:

-   Cost of retail goods sold
-   Repair part costs
-   Printing supplies and other operating expenses
-   General business expenses

Requirements:

-   Show revenue and expenses separately.
-   Calculate retail profit using the cost of goods sold, not by
    subtracting all inventory purchases from the same day's revenue.
-   Calculate repair profit using recorded customer payments less
    recorded repair costs.
-   Calculate print/service results using recorded service revenue and
    relevant recorded expenses.
-   Avoid counting the same expense twice.
-   Clearly indicate that reports are based on recorded data.

The overall result should be calculated from the included revenue and
cost records. The exact accounting treatment for taxes, returns, damaged
stock, and owner withdrawals is not defined in Version 1.0.

------------------------------------------------------------------------

## 7. Data Model Requirements

The following is a logical entity list. It is not tied to a specific
database vendor.

  Entity / Collection     Purpose
  ----------------------- -------------------------------------------
  users                   Admin and Worker accounts
  workers                 Worker profile and account association
  products                General retail products
  wholesalers             Supplier records
  purchases               Product purchase and stock-in records
  sales                   Sale transaction header
  sale_items              Product and quantity details for a sale
  mobile_covers           Cover Base Name and shared stock group
  cover_models            Linked compatible model names
  tempered_glass          Bulk glass inventory
  small_items             Small-item inventory
  print_transactions      Print and Xerox service transactions
  repair_services         Repair job registration and current state
  repair_parts            Parts and cost entries for a repair
  repair_status_history   Repair status change history
  invoices                Generated invoice records
  expenses                General expense records

### 7.1 Common Record Fields

Where applicable, records should include:

-   Unique ID
-   `createdAt`
-   `updatedAt`
-   `createdBy`
-   Current status

Financial records should also include:

-   Amount
-   Transaction date
-   Related module
-   Reference ID

### 7.2 Money Representation

Use integer paise for stored monetary values to avoid floating-point
rounding errors.

Examples:

-   ₹700.00 = `70000` paise
-   ₹30.00 = `3000` paise

The interface may display values in rupees.

### 7.3 Historical Records

Sales, purchases, invoices, repair costs, and expense records must
retain historical snapshots of relevant names and prices. Editing a
product's current name or default price must not silently rewrite old
transactions.

------------------------------------------------------------------------

## 8. Data Integrity and Transaction Rules

### 8.1 Stock Integrity

-   Stock must not become negative.
-   Sale creation and stock deduction must be atomic.
-   A failed sale must not reduce stock.
-   A successful sale must create a corresponding transaction record.
-   Shared cover stock must be updated at the Base Name level.
-   Historical sales must remain available if a product is later
    discontinued.

### 8.2 Financial Integrity

-   Every transaction must have a unique identifier.
-   Every invoice must have a unique invoice number.
-   Delivery, payment recording, invoice generation, and status
    transition must be performed as one protected business operation
    where possible.
-   Duplicate delivery and duplicate payment submission must be
    prevented.
-   Corrections must preserve an audit trail.
-   Reports must not double count a transaction or cost.

### 8.3 Repair Integrity

-   Device name is mandatory.
-   Customer name and phone are optional at registration.
-   Customer name is required at delivery.
-   A repair cannot be delivered before `Done`.
-   Workers cannot perform delivery or financial actions.
-   Delivered jobs should not be casually editable; corrections must be
    authorized and audited.

------------------------------------------------------------------------

## 9. Security and Access Control

-   Require authenticated access to both applications.
-   Assign explicit roles to Admin and Worker accounts.
-   Enforce permissions in backend/database security rules.
-   Restrict Workers to permitted repair records and operations.
-   Prevent Workers from reading financial data.
-   Validate stock, payment, cost, and delivery operations on trusted
    backend logic.
-   Maintain audit logs for important changes.
-   Protect stored customer information and uploaded files.
-   Use secure credential and session handling.

**Worker Assignment & Scoping Model (Confirmed):**
- Workers have self-assignment authority to claim unassigned repair jobs.
- Workers only see and update jobs assigned to or claimed by them.
- Admin maintains full visibility and can reassign any job across all workers.
- The system is architected to scale seamlessly from 1 current technician to multiple workers.

------------------------------------------------------------------------

## 10. Technical Direction & Architecture (Locked)

The target tech stack and architecture are formally approved:

  Layer                          Technology / Tool
  ------------------------------ -------------------------------------------------------------
  Main App (Admin)               Flutter (Counter Precision UI, Tablet/Mobile)
  Worker App                     Flutter (Technician Workbench, Speech-to-Text)
  Shared Domain & Math           Pure Dart Package (`runova_core`: models, formulas, tests)
  Authentication                 Firebase Authentication (Role-based claims)
  Authoritative Cloud Database   Cloud Firestore
  Local Client Database          Local SQLite (Offline-first caching via Drift / sqflite)
  Synchronization Engine         High-Priority Bidirectional Sync Queue (Offline-to-Cloud)
  File Storage                   Firebase Storage (Repair photos, generated invoice PDFs)
  Trusted Server Operations      Cloud Functions & Firestore Security Rules

### 10.1 Offline-First & High-Priority Synchronization Architecture

Counter environments cannot tolerate network latency or dropouts. The technical architecture guarantees:

1. **Immediate Local Execution:** All critical counter actions (Xerox/Print POS billing, retail sales, repair registration, status updates) execute immediately against the **Local SQLite** database with optimistic updates.
2. **High-Priority Sync Queue:** Local mutations generate sync events stored in a dedicated SQLite outbox queue. When online, the sync engine drains this queue with highest network priority to Cloud Firestore.
3. **Atomic Stock & Conflict Resolution:** Stock deductions and repair status changes are reconciled on Cloud Firestore using atomic transactions and server timestamps. Local rollbacks are applied if an atomic conflict occurs.
4. **Authoritative Backend Security:** Firestore Security Rules and Cloud Functions strictly enforce that workers cannot read financial metrics, alter parts costs, or trigger delivery transitions.

------------------------------------------------------------------------

## 11. Non-Functional Requirements

### Reliability

-   Transactions must not partially update stock, payment, invoice, or
    repair status.
-   The system must handle retries without creating duplicate records.

### Performance

-   Product search and repair-job lookup should remain practical as
    records grow.
-   Common data lists should support pagination or equivalent efficient
    retrieval.

### Maintainability

-   Business modules should be separated logically.
-   Shared business rules should not be duplicated inconsistently across
    the two apps.
-   New product categories and future modules should be addable without
    rewriting existing transaction history.

### Backup and Recovery

-   A backup and restore strategy is required before production use.
-   Restore procedures must be tested, not merely configured.

### Auditability

-   Important stock, financial, status, and permission changes must be
    traceable to an actor and timestamp.

------------------------------------------------------------------------

## 12. Acceptance Criteria

Version 1.0 is not ready for release until the following can be
demonstrated:

### Print & Xerox

-   Xerox pricing matches the defined quantity-price rule.
-   Normal print options use the correct rates.
-   Passport photo quantities below 3 or not divisible by 3 are
    rejected.
-   Large document printing calculates ₹50 per document.
-   Transactions appear in revenue records.

### Retail

-   Products can be registered with supplier, buy price, sell price, and
    quantity.
-   Additional purchases increase stock and retain purchase history.
-   Sale uses the default selling price but permits an Admin override.
-   Sale reduces stock and creates a sale record.
-   No-bill sales do not create invoices or customer records.
-   Mobile cover linked models share one stock quantity.
-   Cover search distinguishes Not Found, Out of Stock, and Available
    using database stock.
-   Tempered glass stock and revenue are calculated per piece.
-   Stock cannot become negative.

### Mobile Repair

-   Worker can register a repair with mandatory device name and problem
    details.
-   Customer name and phone are optional during registration.
-   Speech-to-text can populate an editable description.
-   Worker can update only the permitted statuses.
-   Worker cannot record costs, payments, invoices, or delivery.
-   Admin can record one or more part costs.
-   Delivery requires Done status, customer name, and payment amount.
-   Delivery generates an invoice and updates the status exactly once.
-   Repair profit uses recorded payment less recorded repair costs.

### Expenses and Reports

-   General expenses can be recorded and categorized.
-   Repair costs are not accidentally counted twice.
-   Reports use date filters and show revenue and costs separately.
-   Retail profit uses cost of goods sold rather than total inventory
    purchases.

### Security and Recovery

-   Backend rules enforce Admin/Worker permissions.
-   Unauthorized financial actions are rejected by the backend.
-   Important changes are auditable.
-   Backup restoration is tested.

------------------------------------------------------------------------

## 13. Open Questions

These items must be resolved before the relevant feature is finalized:

1.  **Print & Xerox Invoices [RESOLVED]:** No customer invoice. Transactions generate an audit record and a rapid POS thermal receipt (e.g., `PX-8842`).
2.  **Mobile Cover Pricing [RESOLVED]:** Cover records specify a default catalog selling price, pre-filled during sale with cashier bargaining override enabled.
3.  **Repair Invoice Charges [RESOLVED]:** Repair invoices present the total customer charge agreed upon; internal parts cost remains strictly confidential to Admin.
4.  **Retail Returns / Exchanges:** Excluded in Version 1.0 (deferred to future minor release).
5.  **Offline Operation [RESOLVED]:** Mandatory offline-first architecture via Local SQLite. Counter operations never block, and a high-priority background sync engine reconciles changes with Cloud Firestore upon network availability.
6.  **Worker Visibility & Claims [RESOLVED]:** Workers can self-assign/claim unassigned jobs and only see jobs assigned to or claimed by them (architected for future multi-worker teams). Admin retains master oversight.
7.  **Invoice & Receipt Numbering [RESOLVED]:**
    - Retail Invoices: `INV-YYYYMM-XXXX`
    - Repair Invoices: `REP-YYYYMM-XXXX`
    - POS Print Receipts: `PX-XXXX`
8.  **Damaged Stock & Corrections:** Tracked via manual stock adjustment logs with mandatory reason code.
9.  **Backup & Recovery:** Daily automated Cloud Firestore export to Google Cloud Storage.

Unanswered questions must remain configurable or explicitly marked as
pending. The implementation team must not invent business rules.

------------------------------------------------------------------------

## 14. Future Scope

Potential future work, not included in Version 1.0:

-   Cyber Café and online form services.
-   Read-only Runova Diary integration.
-   More advanced accounting.
-   Additional shop service modules.
-   Expanded reporting and analytics.

------------------------------------------------------------------------

## 15. Product Principles

1.  **Business-first:** implement the shop's actual working process, not
    unnecessary enterprise complexity.
2.  **Accurate records:** every sale, expense, purchase, and repair
    event must be traceable.
3.  **Clear authority:** financial control stays in the Main App.
4.  **No false inventory claims:** AI may help search, but the database
    determines stock.
5.  **History matters:** correcting or discontinuing records must not
    erase transaction history.
6.  **Incremental development:** build and test modules in phases.
7.  **No invented requirements:** unresolved decisions must be confirmed
    with the product owner.

------------------------------------------------------------------------

**End of PRD --- Runova Shop v1.0**
