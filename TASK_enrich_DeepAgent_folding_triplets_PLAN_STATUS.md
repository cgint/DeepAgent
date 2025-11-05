# Plan and Status: Implementing Knowledge Triplet Extraction

## 1. Purpose of this Document

This document outlines the step-by-step plan for implementing the **Structured Knowledge Extraction (Knowledge Triplets)** feature as detailed in Phase 1 of the enhancement plan. 

Its purpose is to serve as a live tracker for the implementation status and to capture any important insights, challenges, or decisions made during the development process in the "Learnings while implementing" section. This ensures that knowledge is retained and we avoid repeating problems.

---

## 2. Implementation Plan & Status

- [ ] **1. Create New Module File**
  - `[ ]` 1a. Create a new directory `src/enrichments/`.
  - `[ ]` 1b. Create a new file `src/enrichments/memory_processing.py` to house the new logic, keeping it separate from the core `run_deep_agent.py`.

- [ ] **2. Define Enhanced Memory Prompts for Triplet Extraction**
  - `[ ]` 2a. In `memory_processing.py`, create a new prompt function `get_triplet_episode_memory_instruction` that requires the LLM to output a JSON containing both a text summary and a `knowledge_triplets` list.
  - `[ ]` 2b. Create `get_triplet_working_memory_instruction` with the same JSON structure requirement.
  - `[ ]` 2c. Create `get_triplet_tool_memory_instruction` with the same JSON structure requirement.

- [ ] **3. Implement Core Triplet Generation Logic**
  - `[ ]` 3a. In `memory_processing.py`, create a primary function, `run_triplet_thought_folding`, which will orchestrate the folding process.
  - `[ ]` 3b. This function will take the interaction history as input and use `asyncio.gather` to call the auxiliary LLM in parallel for the three memory types using the new triplet-extracting prompts.
  - `[ ]` 3c. The function will parse the JSON outputs, aggregate the triplets from all three memories, and return the structured data (e.g., a dictionary containing the three summaries and one combined list of triplets).

- [ ] **4. Integrate the New Module into `run_deep_agent.py`**
  - `[ ]` 4a. Add `from src.enrichments.memory_processing import run_triplet_thought_folding` to the top of `run_deep_agent.py`.
  - `[ ]` 4b. Locate the `elif seq['output'].rstrip().endswith(FOLD_THOUGHT):` block in the `generate_main_reasoning_sequence` function.
  - `[ ]` 4c. Replace the existing call to `run_thought_folding` with a call to the new `run_triplet_thought_folding` function.
  - `[ ]` 4d. Modify the prompt injection logic to handle the new structured data. This involves formatting the `append_text` variable to include both the memory summaries and the new `**Inferred Knowledge Graph:**` section with the formatted triplets.

- [ ] **5. Final Review and Testing**
  - `[ ]` 5a. Perform a test run on a benchmark like `ToolBench` or `ALFWorld` to ensure the new folding mechanism works as expected.
  - `[ ]` 5b. Inspect the agent's prompt after a memory fold to verify that the Knowledge Graph is being injected correctly.

---

## 3. Learnings While Implementing

*(This section will be populated with any insights, challenges, or key decisions made during the implementation process.)*
