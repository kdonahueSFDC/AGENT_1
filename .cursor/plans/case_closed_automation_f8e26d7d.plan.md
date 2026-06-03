---
name: Case Closed Automation
overview: "Two Record-Triggered Flows: (1) Before Save validation requiring Description when Status = Closed, and (2) After Save automation creating a follow-up Task for the Case Owner 3 days after close."
todos: []
isProject: false
---

# Case Closed Automation - Production-Ready Plan

## 1. SOLUTION SUMMARY

### High-Level Approach

**Two Record-Triggered Flows** (configuration-first, no Apex):


| Flow                             | Trigger     | Purpose                                                |
| -------------------------------- | ----------- | ------------------------------------------------------ |
| Case_Closed_Description_Required | Before Save | Validate Description is populated when Status = Closed |
| Case_Closed_Follow_Up_Task       | After Save  | Create follow-up Task for Case Owner                   |


**Why this approach over alternatives:**

- **Flow over Apex**: Configuration-first preference; flows are maintainable by admins, support bulk operations natively, and avoid test class maintenance.
- **Two flows vs one**: Before Save flows cannot create records (Task); After Save flows cannot block the save (validation). Splitting satisfies both requirements.
- **Flow over Validation Rule**: Flow allows custom error placement on the Description field and more complex logic if needed later.
- **Record-Triggered over Process Builder**: Record-Triggered Flows are the supported automation model; Process Builder is deprecated.

---

## 2. METADATA TO BE CREATED


| Artifact                           | API Name                           | Type                                |
| ---------------------------------- | ---------------------------------- | ----------------------------------- |
| Case Closed - Description Required | `Case_Closed_Description_Required` | Record-Triggered Flow (Before Save) |
| Case Closed - Follow-Up Task       | `Case_Closed_Follow_Up_Task`       | Record-Triggered Flow (After Save)  |


**No new fields, objects, or permission sets** - uses standard Case (Description, Status, OwnerId, ClosedDate) and Task (WhatId, OwnerId, ActivityDate, Subject) objects.

---

## 3. GENERATE ASSETS

### 3.1 Field Verification

**Description field**: Confirmed as standard API name `Description` on Case. Referenced in [Get_Open_Cases_for_Contact.flow-meta.xml](force-app/main/default/flows/Get_Open_Cases_for_Contact.flow-meta.xml) (line 30).

### 3.2 Flow 1: Case_Closed_Description_Required (Before Save)

**Purpose**: Block save when Status = Closed and Description is blank.

**Trigger configuration:**

- **Object**: Case
- **Trigger**: Record Before Save
- **When**: Only when a record is updated to meet the condition (optimize for "Status changed to Closed")
- **Entry conditions**: Status equals "Closed"

**Flow logic:**

```
Start (entry: Status = "Closed")
  → Decision: Is Description Empty?
      - Outcome "Yes" (Description is blank): Add Error [UI CONFIG REQUIRED]
      - Outcome "No" (Description has value): (implicit end)
      - Default: (implicit end)
```

**Decision logic:**

- Condition: `$Record.Description` IsNull **OR** `$Record.Description` Equal To "" (empty string)
- Use `IsChanged` operator for Status in entry conditions: `Status` IsChanged Equals true AND `Status` Equals "Closed" (to fire only when transitioning to Closed)

**Add Error action**: Must be configured in Flow Builder UI after deployment:

1. Add "Add Error" element (Fault Path or Custom Error component)
2. Set error message: "Description is required when closing a Case."
3. Set field: `Description` (field-level error)
4. Connect from Decision "Yes" outcome

**Metadata constraint**: `customErrors` / Add Error message cannot be fully expressed in metadata XML per your constraints. The flow metadata will include the decision and connector to the error element; the error message and field must be configured in the UI.

### 3.3 Flow 2: Case_Closed_Follow_Up_Task (After Save)

**Purpose**: Create a Task when Case Status = Closed.

**Trigger configuration:**

- **Object**: Case
- **Trigger**: Record After Save
- **When**: Only when a record is updated to meet the condition
- **Entry conditions**: Status equals "Closed"

**Flow logic:**

```
Start (entry: Status = "Closed", when record is updated to meet)
  → Decision: Did Status change to Closed? (IsChanged)
      - Outcome "Yes": Create Task
      - Default: (implicit end)
  → Create Task (Record Create)
```

**Task field mappings:**


| Task Field   | Value                            |
| ------------ | -------------------------------- |
| WhatId       | `$Record.Id` (Case Id)           |
| OwnerId      | `$Record.OwnerId` (Case Owner)   |
| Subject      | "Post-resolution follow-up"      |
| ActivityDate | `{!$Record.ClosedDate}` + 3 days |


**ActivityDate calculation**: Use formula resource or assignment:

- Formula: `ADD(3, DAY, $Record.ClosedDate)` - adds 3 days to ClosedDate
- **Edge case**: If `ClosedDate` is null (e.g., custom close process), use `TODAY()` + 3 days. Add a Decision: if ClosedDate is null, use formula based on `$Flow.CurrentDate`; else use ClosedDate + 3.

**Record Create** - CRUD/FLS: Flow runs in system context; Task creation respects sharing. Ensure Case Owner has Create access on Task (standard profile typically does).

### 3.4 Metadata Structure Reference

**No Record-Triggered flows exist** in the project. Use existing flows as templates for element ordering:

- [ESA_Route_to_Queue.flow-meta.xml](force-app/main/default/flows/ESA_Route_to_Queue.flow-meta.xml) - recordCreates, element order
- [Get_Open_Cases_for_Contact.flow-meta.xml](force-app/main/default/flows/Get_Open_Cases_for_Contact.flow-meta.xml) - decisions with defaultConnector

**Record-Triggered Start element** (from Metadata API):

```xml
<start>
  <filterLogic>and</filterLogic>
  <filters>
    <field>Status</field>
    <operator>EqualTo</operator>
    <value><stringValue>Closed</stringValue></value>
  </filters>
  <filters>
    <field>Status</field>
    <operator>IsChanged</operator>
    <value><booleanValue>true</booleanValue></value>
  </filters>
  <object>Case</object>
  <recordTriggerType>Update</recordTriggerType>
  <triggerType>RecordAfterSave</triggerType>
  <connector>
    <targetReference>Decision_Status_Changed</targetReference>
  </connector>
</start>
```

**Note**: Exact element names (`recordTriggerType`, `triggerObjectType`, etc.) may vary by API version. Deploy and retrieve from org to validate structure.

### 3.5 Fallback: Apex (If Flow Cannot Satisfy)

If metadata deployment fails or Flow Builder does not support required constructs:


| Component  | Name                   |
| ---------- | ---------------------- |
| Trigger    | CaseTrigger            |
| Handler    | CaseTriggerHandler     |
| Test Class | CaseTriggerHandlerTest |


**Handler logic**: `afterUpdate` - loop records where Status = Closed and Status changed; create Task. `beforeUpdate` - loop records where Status = Closed and Description is blank; addError on Description.

---

## 4. PERMISSIONS


| Requirement                | How to Grant                                                                        |
| -------------------------- | ----------------------------------------------------------------------------------- |
| Activate Flows             | System Administrator or "Customize Application"                                     |
| Run Record-Triggered Flows | Runs in system context; no user permissions for execution                           |
| Create Task (Flow)         | Flow runs as system; Task creation succeeds if Case Owner can normally create Tasks |
| Case Owner receives Task   | OwnerId = Case Owner; they become Task owner automatically                          |


**Recommendation**: No permission set changes needed for standard Case/Task. If custom objects or fields are added later, include in permission sets.

---

## 5. TESTING

### 5.1 Test Plan


| #   | Scenario                                     | Steps                                                                     | Expected                                                                                                          |
| --- | -------------------------------------------- | ------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| 1   | Validation - Block close without Description | 1. Create Case, leave Description blank 2. Set Status = Closed, Save      | Error: "Description is required when closing a Case." on Description field                                        |
| 2   | Validation - Allow close with Description    | 1. Create Case, enter Description 2. Set Status = Closed, Save            | Case saves successfully                                                                                           |
| 3   | Task creation - New Case closed              | 1. Create Case, set Description, Status = Closed, Save                    | Task created: Owner = Case Owner, WhatId = Case, Subject = "Post-resolution follow-up", Due = ClosedDate + 3 days |
| 4   | No Task on create                            | 1. Create Case with Status = Closed, Description populated                | Task created (new record meets condition)                                                                         |
| 5   | No Task when reopening                       | 1. Case Status = Closed (Task exists) 2. Change Status to "Working", Save | No new Task created                                                                                               |
| 6   | Bulk - 200 Cases closed                      | Bulk update 200 Cases to Status = Closed                                  | All 200 get Tasks; no governor limit errors                                                                       |


### 5.2 Edge Cases

- **ClosedDate null**: If Case has no ClosedDate when Status = Closed, use `$Flow.CurrentDate` + 3 days for Task due date
- **Case Owner inactive**: Task creation may fail; consider fault path or default to running user
- **Multiple closed statuses**: If org has "Closed - Won", "Closed - Lost", etc., entry condition may need: Status Contains "Closed" or multiple Status values
- **Recursion**: After Save flow creates Task only; no Case update. No recursion risk.

---

## 6. DEPLOYMENT

1. Create flow metadata files in `force-app/main/default/flows/`
2. Run: `sf project deploy start --source-dir force-app/main/default/flows`
3. For Before Save flow: Open in Flow Builder, add "Add Error" element, configure message and field, Save, Activate
4. Re-retrieve flows if UI changes are needed: `sf project retrieve start -m Flow:Case_Closed_Description_Required,Flow:Case_Closed_Follow_Up_Task`

---

## 7. UI CONFIGURATION REQUIRED (Before Save Flow)

**After deploying Case_Closed_Description_Required:**

1. Setup → Flows → Case Closed - Description Required → Edit
2. Add "Add Error" (or Fault Connector with Custom Error) element after Decision "Yes" outcome
3. Configure:
  - Error Message: "Description is required when closing a Case."
  - Field: Description (field-level error)
4. Connect Decision "Yes" outcome to Add Error element
5. Save and Activate

This step cannot be automated via metadata; the Add Error message/field configuration is not fully deployable in XML.