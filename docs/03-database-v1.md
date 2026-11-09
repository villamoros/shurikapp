# SHURIKAPP v1 - Database Initial Draft

## Principles
- Multi-tenant by default.
- Every business record must belong to a tenant scope.
- Shared reference data should be minimized.
- Authorization should be enforceable from relational data, not only from code.
- Soft delete should be used only when auditability or product behavior requires it.

## Tenant model

### Tenant boundary

Primary tenant boundary: `organization`.

Secondary scope: `team` when a feature explicitly needs it.

### Tenant rules

- Any record that represents user-owned, organization-owned, or marketplace-owned data must include `organization_id` unless it is global reference data.
- Any record that can be accessed by a team must include `team_id` when team scope matters.
- Queries in the application layer must always filter by `organization_id` before returning tenant data.
- Foreign keys should preserve tenant consistency where possible.
- Unique constraints should usually be scoped by `organization_id`.

## Suggested enums

### user_account_status

- `active`
- `invited`
- `suspended`
- `archived`

### membership_status

- `pending`
- `active`
- `inactive`
- `removed`

### role_key

- `owner`
- `admin`
- `manager`
- `member`
- `viewer`

### project_status

- `draft`
- `active`
- `paused`
- `completed`
- `archived`

### task_status

- `backlog`
- `todo`
- `in_progress`
- `blocked`
- `review`
- `done`
- `archived`

### task_priority

- `low`
- `medium`
- `high`
- `urgent`

### time_entry_status

- `running`
- `stopped`
- `submitted`
- `approved`
- `rejected`

### methodology_type

- `scrum`
- `kanban`
- `scrumban`
- `shape_up`
- `xp`
- `waterfall`
- `lean`

### notification_status

- `unread`
- `read`
- `archived`

### application_type

- `job`
- `freelance_project`

### application_status

- `draft`
- `submitted`
- `in_review`
- `rejected`
- `shortlisted`
- `hired`
- `withdrawn`

### subscription_status

- `trialing`
- `active`
- `past_due`
- `canceled`
- `expired`

### audit_action

- `create`
- `update`
- `delete`
- `login`
- `logout`
- `invite`
- `approve`
- `reject`

## Tables

## 1. users

Purpose: internal application user profile linked to Clerk.

Columns:

- `id` uuid primary key
- `clerk_user_id` string not null unique
- `email` string not null
- `full_name` string null
- `avatar_url` string null
- `status` user_account_status not null default `active`
- `last_sign_in_at` datetime null
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- unique index on `clerk_user_id`
- index on `email`
- index on `status`

Relations:

- has many `memberships`
- has many `notifications`
- has many `audit_events`
- has one or many `career_profiles`
- has one or many `freelancer_profiles`
- has one or many `time_entries`

## 2. organizations

Purpose: primary tenant.

Columns:

- `id` uuid primary key
- `name` string not null
- `slug` string not null
- `owner_user_id` uuid not null foreign key -> users.id
- `plan_key` string not null default `career_free`
- `status` string not null default `active`
- `logo_url` string null
- `settings` jsonb not null default `{}`
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- unique index on `slug`
- index on `owner_user_id`
- index on `plan_key`
- index on `status`

Relations:

- belongs to `users` as owner
- has many `teams`
- has many `memberships`
- has many `projects`
- has many `job_postings`
- has many `freelance_project_postings`
- has many `notifications`
- has many `subscriptions`
- has many `audit_events`

## 3. teams

Purpose: sub-tenant grouping inside an organization.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `name` string not null
- `slug` string not null
- `description` text null
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- unique index on `organization_id, slug`
- index on `organization_id`

Relations:

- belongs to `organizations`
- has many `team_memberships`
- has many `projects`

## 4. memberships

Purpose: links users to organizations.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `user_id` uuid not null foreign key -> users.id
- `role_id` uuid not null foreign key -> roles.id
- `status` membership_status not null default `pending`
- `joined_at` datetime null
- `invited_by_user_id` uuid null foreign key -> users.id
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- unique index on `organization_id, user_id`
- index on `organization_id`
- index on `user_id`
- index on `role_id`
- index on `status`

Relations:

- belongs to `organizations`
- belongs to `users`
- belongs to `roles`
- may belong to inviter user

## 5. teams_memberships

Purpose: links users to teams.

Columns:

- `id` uuid primary key
- `team_id` uuid not null foreign key -> teams.id
- `user_id` uuid not null foreign key -> users.id
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- unique index on `team_id, user_id`
- index on `team_id`
- index on `user_id`

Relations:

- belongs to `teams`
- belongs to `users`

## 6. roles

Purpose: named access roles per organization or global template role.

Columns:

- `id` uuid primary key
- `organization_id` uuid null foreign key -> organizations.id
- `key` role_key not null
- `name` string not null
- `description` text null
- `is_system` boolean not null default false
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- unique index on `organization_id, key`
- index on `organization_id`
- index on `key`

Relations:

- belongs to `organizations` optionally
- has many `memberships`
- has many `role_permissions`

## 7. permissions

Purpose: atomic permission catalog.

Columns:

- `id` uuid primary key
- `key` string not null unique
- `name` string not null
- `description` text null
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- unique index on `key`

Relations:

- has many `role_permissions`

## 8. role_permissions

Purpose: join table between roles and permissions.

Columns:

- `id` uuid primary key
- `role_id` uuid not null foreign key -> roles.id
- `permission_id` uuid not null foreign key -> permissions.id
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- unique index on `role_id, permission_id`
- index on `role_id`
- index on `permission_id`

Relations:

- belongs to `roles`
- belongs to `permissions`

## 9. professional_profiles

Purpose: public or semi-public professional identity.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `user_id` uuid not null foreign key -> users.id
- `headline` string null
- `bio` text null
- `location` string null
- `website_url` string null
- `linkedin_url` string null
- `github_url` string null
- `visibility` string not null default `public`
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- unique index on `organization_id, user_id`
- index on `organization_id`
- index on `user_id`
- index on `visibility`

Relations:

- belongs to `organizations`
- belongs to `users`
- has one `career_profile`
- has one `freelancer_profile`
- has many `portfolio_items`

## 10. career_profiles

Purpose: career-seeker specific profile.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `user_id` uuid not null foreign key -> users.id
- `professional_profile_id` uuid not null foreign key -> professional_profiles.id
- `target_role` string null
- `seniority_level` string null
- `current_status` string null
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- unique index on `organization_id, user_id`
- unique index on `professional_profile_id`
- index on `organization_id`
- index on `user_id`

## 11. freelancer_profiles

Purpose: freelancer-specific profile.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `user_id` uuid not null foreign key -> users.id
- `professional_profile_id` uuid not null foreign key -> professional_profiles.id
- `hourly_rate` decimal null
- `currency_code` string null
- `availability_status` string null
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- unique index on `organization_id, user_id`
- unique index on `professional_profile_id`
- index on `organization_id`
- index on `user_id`

## 12. cv_documents

Purpose: digital CV content and metadata.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `user_id` uuid not null foreign key -> users.id
- `title` string not null
- `content` jsonb not null default `{}`
- `file_url` string null
- `is_current` boolean not null default false
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- index on `organization_id`
- index on `user_id`
- index on `is_current`

## 13. portfolio_items

Purpose: portfolio entries for freelancers.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `professional_profile_id` uuid not null foreign key -> professional_profiles.id
- `title` string not null
- `description` text null
- `url` string null
- `media` jsonb not null default `{}`
- `published_at` datetime null
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- index on `organization_id`
- index on `professional_profile_id`
- index on `published_at`

## 14. work_history_items

Purpose: career history records.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `career_profile_id` uuid not null foreign key -> career_profiles.id
- `company_name` string not null
- `job_title` string not null
- `start_date` date not null
- `end_date` date null
- `description` text null
- `is_current` boolean not null default false
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- index on `organization_id`
- index on `career_profile_id`
- index on `is_current`

## 15. projects

Purpose: execution container for work.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `team_id` uuid null foreign key -> teams.id
- `owner_user_id` uuid not null foreign key -> users.id
- `name` string not null
- `slug` string not null
- `description` text null
- `status` project_status not null default `draft`
- `methodology_type` methodology_type not null
- `template_key` string null
- `starts_on` date null
- `ends_on` date null
- `metadata` jsonb not null default `{}`
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- unique index on `organization_id, slug`
- index on `organization_id`
- index on `team_id`
- index on `owner_user_id`
- index on `status`
- index on `methodology_type`

Relations:

- belongs to `organizations`
- belongs to `teams` optionally
- belongs to `users` as owner
- has many `tasks`
- has many `time_entries`
- has many `calendar_items`

## 16. tasks

Purpose: atomic unit of project execution.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `project_id` uuid not null foreign key -> projects.id
- `assignee_user_id` uuid null foreign key -> users.id
- `parent_task_id` uuid null foreign key -> tasks.id
- `title` string not null
- `description` text null
- `status` task_status not null default `backlog`
- `priority` task_priority not null default `medium`
- `position` integer not null default 0
- `due_date` date null
- `started_at` datetime null
- `completed_at` datetime null
- `metadata` jsonb not null default `{}`
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- index on `organization_id`
- index on `project_id`
- index on `assignee_user_id`
- index on `parent_task_id`
- index on `status`
- index on `priority`
- index on `due_date`
- composite index on `project_id, status`
- composite index on `project_id, position`

## 17. time_entries

Purpose: time tracking records.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `user_id` uuid not null foreign key -> users.id
- `project_id` uuid null foreign key -> projects.id
- `task_id` uuid null foreign key -> tasks.id
- `status` time_entry_status not null default `running`
- `description` text null
- `started_at` datetime not null
- `stopped_at` datetime null
- `duration_seconds` integer null
- `billable` boolean not null default false
- `metadata` jsonb not null default `{}`
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- index on `organization_id`
- index on `user_id`
- index on `project_id`
- index on `task_id`
- index on `status`
- index on `started_at`

## 18. calendar_items

Purpose: schedule view for tasks, milestones, and events.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `project_id` uuid null foreign key -> projects.id
- `task_id` uuid null foreign key -> tasks.id
- `title` string not null
- `starts_at` datetime not null
- `ends_at` datetime null
- `item_type` string not null
- `metadata` jsonb not null default `{}`
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- index on `organization_id`
- index on `project_id`
- index on `task_id`
- index on `starts_at`
- index on `item_type`

## 19. dashboard_widgets

Purpose: configurable dashboard blocks.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `user_id` uuid null foreign key -> users.id
- `widget_type` string not null
- `settings` jsonb not null default `{}`
- `position` integer not null default 0
- `scope` string not null default `personal`
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- index on `organization_id`
- index on `user_id`
- index on `widget_type`
- index on `scope`

## 20. methodology_templates

Purpose: reusable templates for project creation.

Columns:

- `id` uuid primary key
- `organization_id` uuid null foreign key -> organizations.id
- `methodology_type` methodology_type not null
- `name` string not null
- `description` text null
- `is_default` boolean not null default false
- `configuration` jsonb not null default `{}`
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- index on `organization_id`
- index on `methodology_type`
- index on `is_default`

## 21. workflow_states

Purpose: configurable workflow states per methodology template or project.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `methodology_template_id` uuid null foreign key -> methodology_templates.id
- `project_id` uuid null foreign key -> projects.id
- `name` string not null
- `key` string not null
- `position` integer not null default 0
- `is_terminal` boolean not null default false
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- index on `organization_id`
- index on `methodology_template_id`
- index on `project_id`
- unique index on `organization_id, methodology_template_id, key`

## 22. workflow_transitions

Purpose: allowed movement between workflow states.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `methodology_template_id` uuid null foreign key -> methodology_templates.id
- `from_state_id` uuid not null foreign key -> workflow_states.id
- `to_state_id` uuid not null foreign key -> workflow_states.id
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- index on `organization_id`
- index on `methodology_template_id`
- unique index on `from_state_id, to_state_id`

## 23. job_postings

Purpose: employment opportunities.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `posted_by_user_id` uuid not null foreign key -> users.id
- `title` string not null
- `company_name` string not null
- `description` text not null
- `location_type` string null
- `employment_type` string null
- `status` string not null default `draft`
- `published_at` datetime null
- `application_deadline` datetime null
- `metadata` jsonb not null default `{}`
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- index on `organization_id`
- index on `posted_by_user_id`
- index on `status`
- index on `published_at`
- index on `application_deadline`

## 24. freelance_project_postings

Purpose: freelance opportunities.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `posted_by_user_id` uuid not null foreign key -> users.id
- `title` string not null
- `client_name` string not null
- `description` text not null
- `budget_min` decimal null
- `budget_max` decimal null
- `currency_code` string null
- `status` string not null default `draft`
- `published_at` datetime null
- `application_deadline` datetime null
- `metadata` jsonb not null default `{}`
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- index on `organization_id`
- index on `posted_by_user_id`
- index on `status`
- index on `published_at`
- index on `application_deadline`

## 25. applications

Purpose: application to jobs or freelance projects.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `user_id` uuid not null foreign key -> users.id
- `application_type` application_type not null
- `application_status` application_status not null default `draft`
- `job_posting_id` uuid null foreign key -> job_postings.id
- `freelance_project_posting_id` uuid null foreign key -> freelance_project_postings.id
- `cover_letter` text null
- `portfolio_snapshot` jsonb not null default `{}`
- `submitted_at` datetime null
- `reviewed_at` datetime null
- `decision_at` datetime null
- `metadata` jsonb not null default `{}`
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- index on `organization_id`
- index on `user_id`
- index on `application_type`
- index on `application_status`
- index on `job_posting_id`
- index on `freelance_project_posting_id`
- unique partial style rule recommended in application layer to prevent duplicate active applications per user and posting

## 26. notifications

Purpose: in-app notification delivery.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `user_id` uuid not null foreign key -> users.id
- `title` string not null
- `body` text null
- `category` string not null
- `status` notification_status not null default `unread`
- `read_at` datetime null
- `metadata` jsonb not null default `{}`
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- index on `organization_id`
- index on `user_id`
- index on `status`
- index on `category`
- index on `created_at`

## 27. subscriptions

Purpose: organization plan and entitlement tracking.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `plan_key` string not null
- `status` subscription_status not null
- `provider` string null
- `provider_subscription_id` string null
- `starts_at` datetime null
- `ends_at` datetime null
- `trial_ends_at` datetime null
- `metadata` jsonb not null default `{}`
- `created_at` datetime not null
- `updated_at` datetime not null

Indexes:

- index on `organization_id`
- index on `plan_key`
- index on `status`
- index on `provider_subscription_id`

## 28. audit_events

Purpose: immutable audit log.

Columns:

- `id` uuid primary key
- `organization_id` uuid not null foreign key -> organizations.id
- `actor_user_id` uuid null foreign key -> users.id
- `action` audit_action not null
- `entity_type` string not null
- `entity_id` uuid null
- `before_data` jsonb null
- `after_data` jsonb null
- `ip_address` string null
- `user_agent` string null
- `metadata` jsonb not null default `{}`
- `created_at` datetime not null

Indexes:

- index on `organization_id`
- index on `actor_user_id`
- index on `action`
- index on `entity_type`
- index on `entity_id`
- index on `created_at`

## Relationship summary

- `users` connect to `organizations` through `memberships`.
- `organizations` own the tenant-scoped data.
- `teams` belong to `organizations`.
- `roles` and `permissions` define authorization.
- `professional_profiles` bridge career and freelancer identities.
- `projects` contain `tasks`, `time_entries`, and `calendar_items`.
- `methodology_templates` define workflow structure for projects.
- `job_postings` and `freelance_project_postings` feed the marketplace.
- `applications` connect users to marketplace postings.
- `notifications`, `subscriptions`, and `audit_events` support the foundation layer.

## Recommended first implementation order

1. `users`
2. `organizations`
3. `memberships`
4. `roles`
5. `permissions`
6. `role_permissions`
7. `teams`
8. `professional_profiles`
9. `career_profiles`
10. `freelancer_profiles`
11. `projects`
12. `tasks`
13. `time_entries`
14. `notifications`
15. `audit_events`
16. `subscriptions`
17. `job_postings`
18. `freelance_project_postings`
19. `applications`
20. `methodology_templates`
21. `workflow_states`
22. `workflow_transitions`
23. `calendar_items`
24. `dashboard_widgets`
25. `cv_documents`
26. `portfolio_items`
27. `work_history_items`
