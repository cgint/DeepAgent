# Plan and Status: Implementing Knowledge Triplet Extraction

## 1. Purpose of this Document

This document outlines the step-by-step plan for implementing the **Structured Knowledge Extraction (Knowledge Triplets)** feature. Its purpose is to serve as a live tracker for the implementation status and to capture any important insights, challenges, or decisions made during the development process.

---

## 2. Implementation Plan & Status

- [X] **1. Initial Module File Creation**
  - `[X]` 1a. Create a new directory `src/enrichments/`.
  - `[X]` 1b. Create a new file `src/enrichments/memory_processing.py`.

- [X] **2. Implement a Focused Knowledge Triplet Extractor**
  - `[X]` 2a. In `src/enrichments/memory_processing.py`, create a single function, e.g., `extract_knowledge_triplets`.
  - `[X]` 2b. Inside this function, define a new, focused prompt. This prompt will instruct the auxiliary LLM to take the full interaction history and extract a single, consolidated list of knowledge triplets (`['subject', 'predicate', 'object']`).

- [X] **3. Augment the Folding Process in `run_deep_agent.py`**
  - `[X]` 3a. Add an import for the new `extract_knowledge_triplets` function from the enrichments module.
  - `[X]` 3b. In the `elif seq['output'].rstrip().endswith(FOLD_THOUGHT):` block, **keep the existing call** to `run_thought_folding` to generate the three memory summaries.
  - `[X]` 3c. **Add a second `await` call** to the new `extract_knowledge_triplets` function, passing it the same interaction history.
  - `[X]` 3d. Modify the prompt injection logic (`append_text`) to combine the results from both calls: the text summaries from the first call, and the formatted knowledge graph from the second call.

- [ ] **4. Final Review and Testing**
  - `[ ]` 4a. Perform a test run to ensure the augmented folding mechanism works as expected.
  - `[ ]` 4b. Inspect the agent's prompt after a memory fold to verify that both the original summaries and the new Knowledge Graph are being injected correctly.

---

## 3. Learnings While Implementing

- **Initial architectural decision was flawed.** The first plan proposed replacing the entire `run_thought_folding` function. This was overly disruptive. The corrected approach is to **augment, not replace**. By creating a separate, single-purpose function for triplet extraction and calling it alongside the existing summary function, we create a more modular, safer, and more maintainable design.
