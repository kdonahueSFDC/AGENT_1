---
name: User Story Management App
overview: Create a Salesforce app to manage development user stories organized by features, with both list views and Kanban board interfaces.
todos:
  - id: create-feature-object
    content: ""
    status: completed
  - id: create-user-story-object
    content: ""
    status: completed
    dependencies:
      - create-feature-object
  - id: create-user-story-list-views
    content: Create User_Story__c list views (All_User_Stories, My_User_Stories, Backlog) with appropriate filters and columns for common use cases.
    status: completed
    dependencies:
      - create-user-story-object
  - id: add-user-story-related-list
    content: Add User_Story__c related list to Feature__c layout showing Name, Status, Priority, and Assignee fields. This was removed during initial Feature__c creation to avoid validation errors.
    status: completed
    dependencies:
      - create-user-story-object
  - id: create-apex-controller
    content: ""
    status: completed
    dependencies:
      - create-user-story-object
  - id: create-list-component
    content: ""
    status: pending
    dependencies:
      - create-apex-controller
  - id: create-kanban-component
    content: ""
    status: pending
    dependencies:
      - create-apex-controller
  - id: create-lightning-pages
    content: Create flexipages for User Story List, User Story Kanban, and Feature Record pages with appropriate component layouts.
    status: pending
    dependencies:
      - create-list-component
      - create-kanban-component
  - id: create-tabs
    content: Create tabs for Feature__c and User_Story__c objects. These tabs are required for the custom app navigation.
    status: pending
    dependencies:
      - create-feature-object
      - create-user-story-object
  - id: create-custom-app
    content: Create Development Management custom app with Feature and User Story tabs, navigation, and default landing page.
    status: pending
    dependencies:
      - create-lightning-pages
      - create-tabs
  - id: create-permission-set
    content: Create Development_Management_Access permission set without any permissions initially. This will be a base permission set that can be assigned to users, with permissions added incrementally as objects, fields, and components are created.
    status: completed
  - id: add-feature-permissions
    content: Update Development_Management_Access permission set to add full CRUD permissions (read, create, edit, delete) for Feature__c object and edit access to all Feature__c custom fields (Description__c, Status__c).
    status: completed
    dependencies:
      - create-feature-object
      - create-permission-set
  - id: add-user-story-permissions
    content: "Update Development_Management_Access permission set to add full CRUD permissions (read, create, edit, delete) for User_Story__c object and edit access to all User_Story__c custom fields (Description__c, Status__c, Priority__c, Assignee__c, Feature__c, Acceptance_Criteria__c). Note: Feature__c is a Master-Detail field and cannot be controlled via permission sets - it's automatically accessible with object access."
    status: completed
    dependencies:
      - create-user-story-object
      - create-permission-set
  - id: add-apex-class-permissions
    content: Update Development_Management_Access permission set to grant access to UserStoryController Apex class.
    status: pending
    dependencies:
      - create-apex-controller
      - create-permission-set
  - id: add-lwc-component-permissions
    content: Update Development_Management_Access permission set to grant access to userStoryList and userStoryKanban LWC components.
    status: pending
    dependencies:
      - create-list-component
      - create-kanban-component
      - create-permission-set
  - id: create-tests
    content: Create UserStoryControllerTest.cls with comprehensive unit tests achieving 80%+ code coverage, including error cases and security enforcement.
    status: completed
    dependencies:
      - create-apex-controller
  - id: create-user-story-layout
    content: Create User_Story__c-User Story Layout.layout-meta.xml page layout with all User_Story__c fields organized in logical sections.
    status: pending
    dependencies:
      - create-user-story-object
  - id: create-jest-tests-list-component
    content: Create Jest unit tests for userStoryList LWC component to test filtering, sorting, pagination, and user interactions.
    status: pending
    dependencies:
      - create-list-component
  - id: create-jest-tests-kanban-component
    content: Create Jest unit tests for userStoryKanban LWC component to test drag-and-drop functionality, status updates, and card rendering.
    status: pending
    dependencies:
      - create-kanban-component
---

# User Story Management App Development Plan

## Overview

Build a custom Salesforce app for managing development user stories organized by features. The app will include custom objects, Lightning Web Components for list and Kanban views, Apex controllers, and proper security configuration.

## Architecture

### Data Model

- **Feature__c** (Custom Object): Organizes user stories by feature
  - Fields: Name, Description__c (Long Text Area), Status__c (Picklist: Planning, In Progress, Completed)

- **User_Story__c** (Custom Object): Individual user stories
  - Fields: Name (Title), Description__c (Long Text Area), Status__c (Picklist: Backlog, In Progress, In Review, Done, Blocked), Priority__c (Picklist: Low, Medium, High, Critical), Assignee__c (Lookup to User), Feature__c (Master-Detail to Feature__c), Acceptance_Criteria__c (Long Text Area)

### Components Structure

```
force-app/main/default/
├── objects/
│   ├── Feature__c/
│   │   ├── Feature__c.object-meta.xml
│   │   ├── fields/
│   │   │   ├── Description__c.field-meta.xml
│   │   │   └── Status__c.field-meta.xml
│   │   ├── listViews/
│   │   │   └── All_Features.listView-meta.xml
│   │   └── layouts/
│   │       └── Feature__c-Feature Layout.layout-meta.xml
│   └── User_Story__c/
│       ├── User_Story__c.object-meta.xml
│       ├── fields/
│       │   ├── Description__c.field-meta.xml
│       │   ├── Status__c.field-meta.xml
│       │   ├── Priority__c.field-meta.xml
│       │   ├── Assignee__c.field-meta.xml
│       │   ├── Feature__c.field-meta.xml
│       │   └── Acceptance_Criteria__c.field-meta.xml
│       ├── listViews/
│       │   ├── All_User_Stories.listView-meta.xml
│       │   ├── My_User_Stories.listView-meta.xml
│       │   └── Backlog.listView-meta.xml
│       └── layouts/
│           └── User_Story__c-User Story Layout.layout-meta.xml
├── classes/
│   ├── UserStoryController.cls
│   ├── UserStoryController.cls-meta.xml
│   ├── UserStoryControllerTest.cls
│   └── UserStoryControllerTest.cls-meta.xml
├── lwc/
│   ├── userStoryList/
│   │   ├── userStoryList.html
│   │   ├── userStoryList.js
│   │   ├── userStoryList.css
│   │   └── userStoryList.js-meta.xml
│   └── userStoryKanban/
│       ├── userStoryKanban.html
│       ├── userStoryKanban.js
│       ├── userStoryKanban.css
│       └── userStoryKanban.js-meta.xml
├── flexipages/
│   ├── User_Story_List_Page.flexipage-meta.xml
│   ├── User_Story_Kanban_Page.flexipage-meta.xml
│   └── Feature_Record_Page.flexipage-meta.xml
├── applications/
│   └── Development_Management.app-meta.xml
├── tabs/
│   ├── Feature__c.tab-meta.xml
│   └── User_Story__c.tab-meta.xml
└── permissionsets/
    └── Development_Management_Access.permissionset-meta.xml
```

## Implementation Details

### 1. Custom Objects & Fields

- ✅ Create `Feature__c` object with standard and custom fields
  - **Note**: User_Story__c related list was intentionally omitted from Feature__c layout during initial creation to avoid validation errors. It will be added after User_Story__c object is created.
- Create `User_Story__c` object with Master-Detail relationship to `Feature__c`
- Add User_Story__c related list to Feature__c layout after User_Story__c object exists
- Configure field-level security and validation rules
- Set up list views with filters for common use cases

### 2. Apex Controller (`UserStoryController.cls`)

- `getUserStories(String featureId, String status)` - Query user stories with filtering
- `getUserStoriesByStatus()` - Group user stories by status for Kanban
- `updateUserStoryStatus(Id storyId, String newStatus)` - Update status (for Kanban drag-and-drop)
- `getFeatures()` - Query all features for filtering
- Implement `WITH SECURITY_ENFORCED` for all queries
- Include proper error handling and input validation

### 3. Lightning Web Components

#### `userStoryList` Component

- Display user stories in a data table with sorting and filtering
- Filter by Feature, Status, Priority, Assignee
- Pagination support
- Link to record detail pages
- Use `lightning-datatable` base component

#### `userStoryKanban` Component

- Kanban board with columns for each status
- Drag-and-drop to change status
- Cards show Title, Priority, Assignee, Feature
- Click card to navigate to record detail
- Use SLDS styling for board layout

### 4. Lightning Pages

- **User Story List Page**: Home page with list component and filters
- **User Story Kanban Page**: Alternative view with Kanban component
- **Feature Record Page**: Shows feature details with related list of user stories

### 5. Custom App

- Create "Development Management" app
- Include Feature and User Story tabs
- Configure app navigation and utility items
- Set default landing page to User Story List

### 6. Security & Permissions

- Create permission set `Development_Management_Access` initially without any permissions (can be assigned to users)
- Incrementally add permissions as objects, fields, and components are created:
  - Add Feature permissions: Full CRUD (read, create, edit, delete) for `Feature__c` object and edit access to Description__c, Status__c fields
  - Add User Story permissions: Full CRUD (read, create, edit, delete) for `User_Story__c` object and edit access to Description__c, Status__c, Priority__c, Assignee__c, Feature__c, Acceptance_Criteria__c fields
  - Add Apex class access: Grant access to `UserStoryController` Apex class
  - Add LWC component access: Grant access to `userStoryList` and `userStoryKanban` LWC components
- Set up sharing rules if needed for team collaboration

### 7. Testing

- Apex unit tests with 80%+ code coverage
- Test all controller methods including error cases
- Test security enforcement
- Jest tests for LWC components (if time permits)

## Data Flow

```mermaid
flowchart TD
    A[User opens Development Management App] --> B{Select View}
    B -->|List View| C[userStoryList Component]
    B -->|Kanban View| D[userStoryKanban Component]
    C --> E[UserStoryController.getUserStories]
    D --> F[UserStoryController.getUserStoriesByStatus]
    E --> G[Query User_Story__c]
    F --> G
    G --> H[Return Results]
    H --> C
    H --> D
    D --> I{User Drags Card}
    I -->|Yes| J[UserStoryController.updateUserStoryStatus]
    J --> K[Update User_Story__c.Status__c]
    K --> D
```

## Key Files to Create/Modify

### New Files

- ✅ `force-app/main/default/objects/Feature__c/Feature__c.object-meta.xml` (completed)
- ✅ `force-app/main/default/objects/Feature__c/fields/Description__c.field-meta.xml` (completed)
- ✅ `force-app/main/default/objects/Feature__c/fields/Status__c.field-meta.xml` (completed)
- ✅ `force-app/main/default/objects/Feature__c/listViews/All_Features.listView-meta.xml` (completed)
- ✅ `force-app/main/default/objects/Feature__c/layouts/Feature__c-Feature Layout.layout-meta.xml` (completed - User_Story__c related list added)
- ✅ `force-app/main/default/objects/User_Story__c/User_Story__c.object-meta.xml` (completed)
- `force-app/main/default/objects/User_Story__c/listViews/All_User_Stories.listView-meta.xml`
- `force-app/main/default/objects/User_Story__c/listViews/My_User_Stories.listView-meta.xml`
- `force-app/main/default/objects/User_Story__c/listViews/Backlog.listView-meta.xml`
- `force-app/main/default/classes/UserStoryController.cls`
- `force-app/main/default/lwc/userStoryList/userStoryList.*`
- `force-app/main/default/lwc/userStoryKanban/userStoryKanban.*`
- `force-app/main/default/tabs/Feature__c.tab-meta.xml`
- `force-app/main/default/tabs/User_Story__c.tab-meta.xml`
- `force-app/main/default/applications/Development_Management.app-meta.xml`
- ✅ `force-app/main/default/permissionsets/Development_Management_Access.permissionset-meta.xml` (completed)

### Files to Modify

- None (all modifications completed)

### Reference Existing Patterns

- Follow patterns from `ExperienceController.cls` for Apex structure
- Follow patterns from `recentExperiences` LWC for component structure
- Use similar permission set structure as `Sales_Experience_Access.permissionset-meta.xml`

## Success Criteria

- Users can create and manage Features
- Users can create User Stories linked to Features
- Users can view User Stories in list format with filtering
- Users can view User Stories in Kanban format
- Users can update User Story status via drag-and-drop in Kanban
- All code has 80%+ test coverage
- App is accessible via custom app launcher entry
- Security is properly configured with permission sets that grant full CRUD and edit permissions
- Permission set can be assigned to users to grant access to all app functionality