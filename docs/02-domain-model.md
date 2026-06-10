# SHURIKAPP v1 - Domain Model Draft

## Core tenancy

### Organization

Represents the main tenant boundary.

### Team

Represents a sub-group within an organization.

### Membership

Connects a user to an organization and optionally to teams.

### Role

Defines a named access profile.

### Permission

Defines an atomic action allowed in the system.

### RolePermission

Connects roles to permissions.

## Identity and profile

### User

Backed by Clerk identity and linked to internal application profile data.

### ProfessionalProfile

Public or semi-public professional identity for marketplace usage.

### CareerProfile

Profile specialized for job seekers.

### FreelancerProfile

Profile specialized for freelancers.

### CVDocument

Digital CV content and export metadata.

### PortfolioItem

Freelancer work sample or case study.

### WorkHistoryItem

Professional history entries for career users.

## Work OS

### Project

Container for execution work.

### Task

Atomic work item inside a project.

### TimeEntry

Trackable time record linked to a user and optionally to a project/task.

### CalendarItem

Scheduled item derived from tasks, milestones, events, or deadlines.

### DashboardWidget

Configurable view component for user or organization dashboards.

## Methodologies

### MethodologyType

Enum or reference table for the supported methodologies.

### MethodologyTemplate

Reusable structure for creating projects.

### WorkflowState

Configurable state in a project workflow.

### WorkflowTransition

Allowed state transition.

## Marketplace

### JobPosting

Employment opportunity.

### FreelanceProjectPosting

Freelance opportunity.

### Application

Represents a user's application to a job or freelance project.

## Foundation services

### Notification

System-generated or user-facing alert.

### Subscription

Plan and entitlement data.

### AuditEvent

Immutable record of sensitive actions.

## Recommended first-pass database boundaries

- `users`
- `organizations`
- `teams`
- `memberships`
- `roles`
- `permissions`
- `role_permissions`
- `professional_profiles`
- `career_profiles`
- `freelancer_profiles`
- `cv_documents`
- `portfolio_items`
- `work_history_items`
- `projects`
- `tasks`
- `time_entries`
- `calendar_items`
- `dashboard_widgets`
- `methodology_templates`
- `workflow_states`
- `workflow_transitions`
- `job_postings`
- `freelance_project_postings`
- `applications`
- `notifications`
- `subscriptions`
- `audit_events`
