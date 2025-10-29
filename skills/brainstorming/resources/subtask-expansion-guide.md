### Phase 5: Refine Subtask Granularity

**Goal:** Check if any phase tasks are too large (>16 hours) and break them into subtasks with COMPLETE designs.

**CRITICAL:** Subtasks must have complete, self-contained designs. NO placeholders, NO "see parent", NO "see full details".

- Mark Phase 5 as in_progress in TodoWrite

#### Review Task Sizes

For each phase task created in Phase 3 and expanded in Phase 4:

1. **Estimate effort based on design**
   - Review the implementation checklist
   - Count files, functions, tests to implement
   - Estimate: 4-8 hours ideal, up to 16 hours acceptable

2. **If task is >16 hours, break it down**

   **MANDATORY PROCESS:**

   a. **First, read the parent task design from bd:**
      ```bash
      bd show bd-3 --format json  # Get parent task's complete design
      ```

   b. **Split the design content across subtasks:**
      - Each subtask gets its portion of architecture, components, implementation checklist
      - Each subtask must be COMPLETE and self-contained
      - NO references like "See parent" or "Full details in parent"
      - If implementation details are in parent, COPY them to subtasks

   c. **Create subtasks with COMPLETE designs:**

   ```bash
   # Example: Phase 2 (bd-3) is 50 hours - break into subtasks
   # After reading bd-3's complete design, split it:

   bd create "Subtask 1: Vehicle Identifiers" --type task --priority 1 \
     --design "## Goal
   Implement regex-based vehicle identifier scanner (VIN, license plates)

   ## Design

   ### Architecture
   VehicleScanner struct implements Scanner trait with:
   - Regex patterns for VINs (17 chars, specific format)
   - Regex patterns for US/EU license plates
   - Confidence scoring based on context

   ### Components
   - VehicleScanner::new() - initialize with compiled regexes
   - Scanner::scan() implementation - find all matches
   - Scanner::name() returns \"vehicle_identifiers\"

   ## Implementation Checklist
   - [ ] src/scanners/vehicle.rs - VehicleScanner struct
   - [ ] Implement Scanner trait (scan, name, confidence)
   - [ ] VIN regex: [A-HJ-NPR-Z0-9]{17} with validation
   - [ ] License plate regex: [A-Z]{3}[0-9]{4} (US format)
   - [ ] Confidence: 0.9 if in automotive context, 0.7 otherwise
   - [ ] tests/scanners/vehicle_test.rs - unit tests
   - [ ] Test: valid VINs detected
   - [ ] Test: invalid VINs rejected (I, O, Q chars)
   - [ ] Test: license plates with spaces/no spaces
   - [ ] Test: confidence scoring based on context

   ## Success Criteria
   - [ ] VehicleScanner fully implemented
   - [ ] All Scanner trait methods working
   - [ ] Unit tests passing (10+ test cases)
   - [ ] Pre-commit hooks pass
   - [ ] No TODOs without issue numbers

   ## Effort Estimate
   6-8 hours"
   # Returns bd-6

   bd create "Subtask 2: Medical Device IDs" --type task --priority 1 \
     --design "## Goal
   Implement medical device identifier scanner (FDA UDI, EU MDR)

   ## Design

   ### Architecture
   MedicalDeviceScanner struct with:
   - UDI parsing (device identifier + production identifier)
   - EU MDR number matching
   - Clinical context detection

   [FULL DESIGN HERE - NOT abbreviated]

   ## Implementation Checklist
   [COMPLETE CHECKLIST - NOT \"see parent\"]

   ## Success Criteria
   [SPECIFIC CRITERIA]

   ## Effort Estimate
   6-8 hours"
   # Returns bd-7

   # Link subtasks to parent phase
   bd dep add bd-6 bd-3 --type parent-child  # Subtask is child of Phase
   bd dep add bd-7 bd-3 --type parent-child

   # Add sequential dependencies if needed
   bd dep add bd-7 bd-6  # bd-7 depends on bd-6 (do bd-6 first)
   ```

   **VALIDATION:** Before proceeding, verify each subtask:
   - Has Goal section (not "TBD")
   - Has Design section with architecture details (not "See parent")
   - Has complete Implementation Checklist (not "See parent")
   - Has specific Success Criteria (not generic)
   - Has Effort Estimate (not "TBD")

   **If any subtask has placeholders, STOP and fix it.**

3. **Keep small tasks as-is**
   - If task is ≤16 hours, no changes needed
   - It will be implemented as a single unit

#### Verify Final Structure

