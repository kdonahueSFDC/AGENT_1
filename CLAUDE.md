# CLAUDE.md - Project Context for AI Assistants

## Project Overview

**Project Name**: AGENT_1  
**Type**: Salesforce DX Project  
**API Version**: 65.0  
**Primary Language**: Apex, Lightning Web Components (LWC), JavaScript

This is a Salesforce development project following the SFDX structure with Apex classes, Lightning Web Components, and standard Salesforce metadata.

---

## Salesforce Best Practices - ALWAYS FOLLOW

### Apex Development

- **Governor Limits**: Always be mindful of Salesforce governor limits
  - Bulkify all code - handle collections, not single records
  - Avoid SOQL/DML inside loops
  - Maximum 100 SOQL queries per transaction
  - Maximum 150 DML statements per transaction
  - Maximum 50,000 records per SOQL query
- **Security**:
  - Use `WITH SECURITY_ENFORCED` or `WITH USER_MODE` in SOQL queries
  - Check CRUD/FLS permissions before DML operations
  - Avoid dynamic SOQL without proper sanitization (prevent SOQL injection)
  - Use `String.escapeSingleQuotes()` for dynamic queries
- **Error Handling**:
  - Always include try-catch blocks for DML operations
  - Provide meaningful error messages
  - Log errors appropriately for debugging
- **Test Coverage**:
  - Maintain 75%+ code coverage (Salesforce minimum)
  - Aim for 90%+ coverage for production code
  - Test bulk scenarios (200+ records)
  - Use `@testSetup` for test data creation
  - Test positive, negative, and bulk scenarios
  - Use `Test.startTest()` and `Test.stopTest()` to reset governor limits
- **Code Organization**:
  - One class per file
  - Use service layer pattern (Controller → Service → Data Access)
  - Keep controllers thin - business logic in service classes
  - Follow naming conventions: `*Controller`, `*Service`, `*Selector`, `*Test`

### Lightning Web Components (LWC)

- **Security**:
  - Always use `@AuraEnabled(cacheable=true)` for read-only operations
  - Validate all user inputs on both client and server side
  - Use Lightning Data Service when possible (automatic CRUD/FLS)
- **Performance**:
  - Minimize wire calls and imperatives
  - Use `@wire` for reactive data
  - Implement proper error handling with `.catch()`
  - Debounce user input handlers
- **Best Practices**:
  - Follow kebab-case for component names
  - Use composition over inheritance
  - Implement proper loading states and error messages
  - Use Lightning Base Components when possible
  - Follow accessibility guidelines (WCAG 2.1 AA)

### Data Model & SOQL

- **Queries**:
  - Always specify field names (never `SELECT *`)
  - Use selective filters to minimize query rows
  - Leverage indexed fields in WHERE clauses
  - Use `LIMIT` clauses to prevent large data sets
  - Consider query plan and execution time
- **Relationships**:
  - Use relationship queries efficiently
  - Avoid nested queries in loops
  - Consider parent-to-child vs child-to-parent relationships

### Deployment & CI/CD

- **Before Deployment**:
  - Run all local tests: `sf apex test run --test-level RunLocalTests`
  - Validate code coverage
  - Check for deployment warnings
  - Review static code analysis results
- **Version Control**:
  - Commit metadata in source format (not mdapi format)
  - Use meaningful commit messages
  - Keep .forceignore updated

---

## AI Expert Suite Integration

When working on specific domains or tasks, **engage appropriate AI Experts** from the AI Expert Suite:

### Development Workflow Experts

- **`/innerloop`** - For end-to-end development tasks following TDD
  - Automatically handles: plan → implement → test → review cycle
  - Use for new features or enhancements
  - Includes parallel code review across quality, security, and domain dimensions

### Code Quality & Review Experts

- **`/code-review`** - Review code for bugs and quality issues
  - Use after making changes or before committing
  - Supports `--comment` flag to post inline PR comments
  - Supports `--fix` flag to auto-apply fixes
- **`/simplify`** - Refactor code for reuse, simplification, efficiency
  - Use to clean up technical debt
  - Focuses on code quality improvements

### Security Experts

- **`/sf-security-review`** (via aisuite-nfr-analysis skill) - Security review for OWASP Top 10
  - SQL injection, XSS, auth issues, crypto flaws
  - Use before merging security-sensitive code
- **`/security-review`** - General security review
  - Use for comprehensive security analysis

### Accessibility Expert

- **`/accessibility-code-review`** (via a11y_expert skill) - WCAG 2.2 compliance
  - Reviews LWC components for accessibility violations
  - Use before deploying customer-facing UI components

### Non-Functional Requirements (NFR) Experts

- **`/analyze-perf`** - Performance analysis and bottleneck identification
- **`/analyze-scale`** - Scalability evaluation
- **`/analyze-availability`** - High availability and reliability patterns
- **`/quality-review`** - Code quality and maintainability review

### Salesforce-Specific Experts

- **`/entity-expert-code-generation`** (UDD skills) - Universal Data Dictionary entity code generation
- **`/research-entities`** - Research Salesforce entities and relationships
- **`/core-entity-expert`** - Core entity expertise
- **API Expert** - API design and implementation guidance

### Testing & Debugging Experts

- **`/verify`** - Run and verify that changes work as expected
  - Use to manually test changes in a real environment
- **`/systematic-debugging`** (innerloop skill) - Debug failing tests or issues
  - Root cause analysis before patches
  - Reproduction tests before fixes

### Research & Documentation

- **`/deep-research`** - Multi-source, fact-checked research reports
  - Use for technical research, best practices, or architecture decisions
- **`/diagrams`** - Generate mermaid diagrams for flows, architecture, sequences
  - Use to visualize complex logic or document architecture

### Workflow Automation

- **`/loop`** - Run commands on recurring intervals
  - Use for monitoring, polling, or recurring tasks

---

## Development Commands

### Common Salesforce CLI Commands

```bash
# Authorize org
sf org login web --set-default-dev-hub --alias my-hub

# Create scratch org
sf org create scratch --definition-file config/project-scratch-def.json --set-default --alias scratch-org

# Push source to org
sf project deploy start

# Pull source from org
sf project retrieve start

# Run tests
sf apex test run --test-level RunLocalTests --code-coverage --result-format human

# Open org
sf org open
```

### Local Development

```bash
# Install dependencies
npm install

# Run linter
npm run lint

# Run prettier
npm run prettier

# Run Jest tests (for LWC)
npm test
```

---

## Project Structure

```
force-app/main/default/
├── classes/                 # Apex classes
├── triggers/                # Apex triggers
├── lwc/                     # Lightning Web Components
├── aura/                    # Aura components (if any)
├── objects/                 # Custom objects & fields
├── permissionsets/          # Permission sets
├── layouts/                 # Page layouts
├── tabs/                    # Custom tabs
└── [other metadata types]
```

---

## IT Request SLA Domain

The IT Help Desk domain enforces priority-driven SLAs on every `IT_Request__c` record.

**Fields on IT_Request__c**

- `Employee_Email__c` (Email) — recipient for confirmation emails; agents populate this at creation
- `Due_By__c` (DateTime) — SLA deadline, stamped by flow on create: Critical=4h, High=8h, Medium=24h, Low=72h from CreatedDate (clock hours, 24×7)
- `First_Response_At__c` (DateTime) — stamped when Status first changes from "New"
- `Resolved_At__c` (DateTime) — stamped when Status becomes "Resolved"; cleared if reopened
- `SLA_Breach_Notified__c` (Checkbox) — flow-only writable; suppresses duplicate breach alerts
- `SLA_Status__c` (Formula Text) — On Track / At Risk (within 25% of Due_By) / Breached / Met / Missed / Not Set
- `Time_To_Resolution_Hours__c` (Formula Number) — hours from CreatedDate to Resolved_At__c

**Automation**

- `IT_Request_SLA_Management` — record-triggered after-save; stamps Due_By, First_Response_At, Resolved_At
- `IT_Request_SLA_Breach_Alerts` — scheduled hourly, `runInMode=SystemModeWithoutSharing`; emails the Tier 2 queue and sets the notified flag
- `IT_Request_Triage` (before-insert) → `ITRequestTriageService` — evaluates active `IT_Triage_Rule__mdt` rows in ascending `Evaluation_Order__c`, stamps `Assigned_Tier__c`, and assigns `OwnerId` to the matching queue. Callers that pre-populate `Assigned_Tier__c` (admins, legacy invocables) opt out of auto-triage.

**Triage rules (`IT_Triage_Rule__mdt`)**

- `Keyword__c` — case-insensitive substring on `Issue_Description__c`; blank matches any request
- `Priority_Filter__c` — optional exact match on `Priority__c`
- `Target_Tier__c` — one of Tier 1 / Tier 2 / Tier 3
- `Target_Queue_DevName__c` — Queue DeveloperName; blank leaves OwnerId untouched
- `Evaluation_Order__c` — ascending, first match wins; use gaps of 10
- `Active__c` — deactivate instead of deleting to preserve history

Seeded rules: Critical→Tier 2, breach/phishing→Tier 3, outage/vpn→Tier 2, password/mfa→Tier 1, catch-all fallback→Tier 1.

**Email templates** live under `force-app/main/default/email/IT_Requests/`: `IT_Request_Confirmation`, `IT_Request_Escalation_Notification`, `IT_Request_SLA_Breach`.

**Post-deploy ops actions (required)**

- Replace placeholder `it-tier1@example.com` / `it-tier2@example.com` / `it-tier3@example.com` on the tier queues with the real ops distribution lists
- Update `startDate` on `IT_Request_SLA_Breach_Alerts` scheduled flow if past
- Add queue members via Setup → Queues (metadata only creates the shell); triage cannot route to a queue that doesn't exist
- Tune `IT_Triage_Rule__mdt` records for the tenant's terminology — new keywords/queues need no code change

---

## When to Engage Experts - Quick Reference

| Task                    | Expert Skill                 | When to Use                               |
| ----------------------- | ---------------------------- | ----------------------------------------- |
| New feature development | `/innerloop`                 | Starting any new feature or enhancement   |
| Code review             | `/code-review`               | Before committing or merging              |
| Security review         | `/sf-security-review`        | Before merging sensitive code             |
| Accessibility check     | `/accessibility-code-review` | Before deploying UI changes               |
| Refactoring             | `/simplify`                  | Cleaning up technical debt                |
| Performance issues      | `/analyze-perf`              | Investigating slow operations             |
| Manual testing          | `/verify`                    | Confirming fixes work in real environment |
| Research                | `/deep-research`             | Understanding complex topics              |
| Documentation           | `/diagrams`                  | Visualizing architecture or flows         |

---

## Code Review Checklist

Before committing code, ensure:

- [ ] All Apex code is bulkified (handles 200+ records)
- [ ] No SOQL/DML inside loops
- [ ] Security enforced (`WITH SECURITY_ENFORCED` or proper FLS checks)
- [ ] Test coverage ≥ 75% (aim for 90%+)
- [ ] Bulk test scenarios included
- [ ] Error handling implemented
- [ ] LWC components handle loading and error states
- [ ] Accessibility requirements met (for UI components)
- [ ] Code follows naming conventions
- [ ] No hardcoded IDs or credentials
- [ ] Debug statements removed
- [ ] Comments explain "why", not "what"

---

## Testing Strategy

### Apex Tests

1. **Setup Phase**: Use `@testSetup` for common test data
2. **Test Bulk**: Always test with 200+ records
3. **Test Scenarios**:
   - Positive cases (happy path)
   - Negative cases (validation errors)
   - Edge cases (null values, empty collections)
   - Permission scenarios (different user profiles)
4. **Assertions**: Use meaningful assertions with messages
5. **Isolation**: Each test method should be independent

### LWC Tests

1. Use Jest for unit testing LWC components
2. Mock Apex method calls
3. Test user interactions (button clicks, input changes)
4. Test conditional rendering
5. Test error handling paths

---

## Security Guidelines

### Input Validation

- Validate all user inputs on server-side
- Sanitize dynamic SOQL queries
- Use bind variables when possible
- Escape special characters

### Access Control

- Check object and field-level security
- Use `WITH SECURITY_ENFORCED` in SOQL queries
- Implement sharing rules appropriately
- Test with different user profiles

### Sensitive Data

- Never log sensitive information
- Encrypt sensitive fields
- Use Platform Encryption when needed
- Follow PII handling guidelines

---

## Notes for AI Assistants

- **Always prioritize Salesforce best practices** over generic patterns
- **Engage appropriate experts** from AI Suite for specialized tasks
- **Test coverage is critical** - never skip test class generation
- **Governor limits are non-negotiable** - bulkify all code
- **Security is paramount** - always consider FLS and CRUD permissions
- When uncertain about Salesforce-specific patterns, use `/deep-research` to investigate best practices
- Use `/diagrams` to explain complex trigger frameworks, integration flows, or data models
- Run `/code-review` proactively before marking work complete

---

## Additional Resources

- [Salesforce Developer Documentation](https://developer.salesforce.com/docs)
- [Apex Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/)
- [Lightning Web Components Guide](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/)
