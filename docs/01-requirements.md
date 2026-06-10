# SHURIKAPP v1 - Requirements

## 1. Functional requirements

### 1.1 Identity and access

- Users shall authenticate using Clerk.
- The system shall support user profiles.
- The system shall support organizations.
- The system shall support teams within organizations.
- The system shall support roles.
- The system shall support permissions.
- The system shall assign a user to one or more organizations.
- The system shall allow users to switch tenant context.

### 1.2 Foundation services

- The system shall create notifications for relevant events.
- The system shall record audit events for sensitive actions.
- The system shall support subscription plans and entitlement checks.

### 1.3 Work OS

- The system shall allow creation and management of projects.
- The system shall allow creation and management of tasks.
- The system shall track time entries.
- The system shall present a calendar view of relevant items.
- The system shall provide dashboards for user and organization contexts.

### 1.4 Methodology support

- The system shall allow a project to use one methodology.
- The system shall support Scrum, Kanban, Scrumban, Shape Up, XP, Waterfall, and Lean.
- The system shall allow methodology-specific workflow configuration.
- The system shall allow methodology-specific project templates.

### 1.5 Marketplace

- The system shall store professional profiles.
- The system shall store job postings.
- The system shall store freelance project postings.
- The system shall allow users to apply to jobs.
- The system shall allow users to apply to freelance projects.

### 1.6 Career Free

- The system shall support a career profile.
- The system shall support a digital CV.
- The system shall support a work history.
- The system shall support a personal dashboard.
- The system shall support a personal time tracker.
- The system shall limit personal projects to 7.

### 1.7 Freelancer Free

- The system shall support a freelancer profile.
- The system shall support a portfolio.
- The system shall support marketplace participation.
- The system shall support application to freelance projects.
- The system shall limit active projects to 7.

## 2. Non-functional requirements

### 2.1 Architecture

- The system shall be implemented as a monorepo.
- The backend shall be a Rails API.
- The frontend shall be a Next.js application.
- The system shall run in Docker containers.
- Backend and frontend shall be deployed as separate images.

### 2.2 Data

- The system shall use PostgreSQL.
- The system shall isolate tenant data by organization.
- The system shall preserve auditability for sensitive changes.

### 2.3 Security

- The system shall use Clerk for authentication.
- The system shall enforce authorization at the API layer.
- The system shall validate tenant access before data reads or writes.
- The system shall avoid exposing cross-tenant records.

### 2.4 Performance

- The system shall support pagination for list endpoints.
- The system shall keep dashboard queries efficient.
- The system shall use asynchronous jobs for non-critical background work.

### 2.5 Maintainability

- The system shall keep domain boundaries explicit.
- The system shall favor reusable shared models for common workflows.
- The system shall keep methodology logic declarative where possible.

## 3. Explicit requirements

- Use Ruby and Rails on the backend.
- Use Next.js, TypeScript, and React on the frontend.
- Use Supabase PostgreSQL as the database layer.
- Use Clerk as the authentication provider.
- Use Docker for deployment.
- Build the project as a monorepo.
- Support both Career Free and Freelancer Free from the start.

## 4. Implicit requirements

- Users will expect a responsive experience on desktop and mobile.
- Users will expect tenant switching to be obvious and safe.
- Users will expect marketplace data to remain separate from work-management data, even if the same user sees both.
- Users will expect methodology templates to be easy to apply to new projects.
- Users will expect limits like 7 projects to be enforced consistently in UI and backend.
