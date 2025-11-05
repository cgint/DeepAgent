# Detailed Plan: Enhancing DeepAgent with Information-Centric Concepts

This document provides a granular, step-by-step guide for integrating the most promising ideas from `concept.md` into the DeepAgent framework. The phases are ordered by a combination of implementation complexity and potential impact, offering a clear roadmap for development.

---

### **Phase 1: Structured Knowledge Extraction (Knowledge Triplets)**

**This is the new, most promising first step.** It directly enhances the core memory folding mechanism to produce far richer, more structured, and less ambiguous context by creating a dynamic, task-specific Knowledge Graph.

*   **Concept Being Added**: A dynamic, lightweight Knowledge Graph built from extracted triplets, inspired by ACE/ACON's goal of preserving critical information.
*   **Goal**: Augment the three memory types so they produce not only text summaries but also a list of structured knowledge triplets (`subject`, `predicate`, `object`).

#### Step-by-Step Implementation:

1.  **Modify the Memory Prompts**: This is the core change. Update the three memory generation prompts in `src/prompts/prompts_deepagent.py` (`get_episode_memory_instruction`, `get_working_memory_instruction`, `get_tool_memory_instruction`).
    *   For each prompt, modify the required JSON output to include a new field: `"knowledge_triplets"`.
    *   Add a new instruction to the prompt:
        > "In addition to the summary, you **must** extract all key facts, relationships, and states as a list of knowledge triplets. Each triplet should be a list of three strings: `['subject', 'predicate', 'object']`. Be precise and comprehensive.
        > 
        > **Examples:**
        > *   `['user', 'wants_to_book', 'flight_to_SFO']`
        > *   `['search_flight_tool', 'requires_parameter', 'destination_city']`
        > *   `['last_tool_call', 'failed_with_error', 'InvalidAPIKey']`
        > *   `['current_subgoal', 'is', 'find_the_apple']`"

2.  **Update the Folding Function**: In `run_deep_agent.py`, the `run_thought_folding` function will need to be adjusted.
    *   It will now receive three JSON objects from the auxiliary LLM, not just text.
    *   It must parse these objects to separate the text summaries from the new lists of triplets.
    *   It should then aggregate all triplets from the three memories into a single, deduplicated list.

3.  **Design the Prompt Injection**: The main loop in `generate_main_reasoning_sequence` will be modified to inject this new structured knowledge. The `append_text` variable, which is prepended to the prompt after a fold, will be updated to a new format:
    ```
    Memory of previous folded thoughts:

    Episode Memory:
    {episode_memory_summary}

    Working Memory:
    {working_memory_summary}

    Tool Memory:
    {tool_memory_summary}

    **Inferred Knowledge Graph:**
    - (user) -[wants_to_book]-> (flight_to_SFO)
    - (search_flight_tool) -[requires_parameter]-> (destination_city)
    - (last_tool_call) -[failed_with_error]-> (InvalidAPIKey)
    - (current_subgoal) -[is]-> (find_the_apple)

    Now, begin your reasoning for...
    ```

*   **Why it's So Promising**:
    *   **Structured Reasoning**: It forces the main LLM to reason over structured data, which can dramatically reduce ambiguity and improve factual recall.
    *   **Reduces "Context Distraction"**: The LLM can instantly "look up" a specific fact from the triplet list rather than searching a long paragraph.
    *   **Foundation for Advanced Reasoning**: This is a gateway to more complex capabilities like logical inference or identifying contradictory facts.
    *   **A Concrete Goal for Compression**: It provides a perfect, concrete implementation of the ACE/ACON goal to "preserve critical information" in a dense, machine-readable format.

---

### **Phase 2: Explicit Provenance Tracking (Low Effort, High Impact)**

**Goal**: Enhance the `Episode Memory` to not just know *what* happened, but *why* it happened, building on the structured nature of Phase 1.

#### Step-by-Step Implementation:

1.  **Modify the Episode Memory Prompt**: In `src/prompts/prompts_deepagent.py`, enhance the `get_episode_memory_instruction` prompt.
2.  **Instruction**: Instruct the LLM to create triplets that explicitly link actions to their triggers. For example:
    > "When generating triplets for the Episode Memory, focus on causality. Create triplets like `['decision_to_search_APIs', 'was_caused_by', 'user_request_for_forecast']` or `['extracted_flight_number', 'has_source', 'output_of_get_details_tool']`."

*   **Why it's Promising**: It creates a rich, auditable trail of the agent's reasoning. When the agent gets stuck, the Knowledge Graph will make it trivial to see *why* a wrong turn was taken.

---

### **Phase 3: Refactor a Core Module with DSPy (High Effort, Very High Impact)**

**Goal**: Introduce a systematic optimization process for prompt engineering, moving from ad-hoc prompts to a more rigorous, optimizable structure.

#### Step-by-Step Implementation:

1.  **Setup**: Add `dspy-ai` to `requirements.txt` and configure it.
2.  **Create a DSPy Module**: Create a new file like `src/dspymodules/memory_modules.py` and define a signature and module for one of the memory generation tasks (e.g., `ToolMemoryGenerator`).
3.  **Integrate**: In `run_deep_agent.py`, import and use this new DSPy module within `run_thought_folding`.
4.  **Optimize**: Create a separate script to load training examples and use a DSPy optimizer (e.g., `BootstrapFewShot`) to automatically learn a better prompt for the module.

*   **Why it's Promising**: This is the path to making the agent **systematically improvable**. It replaces guesswork with a data-driven, engineered approach to prompt design, making the agent more reliable and performant.

---

### **Phase 4: Continuous Learning and Knowledge Integration**

**Goal**: Implement a two-level learning loop where fine-grained "learnings" from each step are collected and then explicitly used to improve the quality of the strategic, full memory fold.

#### Step-by-Step Implementation:

1.  **Create a Reflection Prompt**: In `src/prompts/prompts_deepagent.py`, create a new function `get_continuous_learning_instruction`. This prompt should be focused on extracting a single, key insight after a tool call.
    > "Based on the following tool call and its response, generate a single, concise insight or finding. This could be a rule, a cause-and-effect relationship, or a key piece of data. Prefix your response with 'Finding:'. If no significant insight is found, respond with 'No finding.'\n\nTool Call: {tool_call}\n\nTool Response: {tool_response}"

2.  **Add the Reflection Step**: In the main loop of `generate_main_reasoning_sequence` (in `run_deep_agent.py`), after each tool call, add a call to the auxiliary LLM using this new prompt.

3.  **Store Continuous Findings**: Initialize an empty list, `seq['continuous_findings'] = []`, at the start of the task. Append the output of each reflection step to this list.

4.  **(NEW) Enhance the Memory Folding Prompts**: This is the crucial integration step. Modify the three main memory folding prompts (`get_episode_memory_instruction`, `get_working_memory_instruction`, `get_tool_memory_instruction`).
    *   Add a new section to each prompt that accepts the list of continuous findings.
    *   Update the core instruction to leverage this input:
        > "You are analyzing the full interaction history to generate a structured memory. To assist you, here is a list of preliminary findings that were identified after each key step. **You must use these findings as a guide to ensure the most critical information is captured in your final summary and knowledge triplets.**\n\nPreliminary Findings:\n{findings_list}"

5.  **(NEW) Update the `run_thought_folding` Function**: 
    *   The `run_thought_folding` function in `run_deep_agent.py` must now accept `seq['continuous_findings']` as an argument.
    *   It will then pass this list into the updated prompts for the auxiliary LLM during the full memory fold.

*   **Why this is a Powerful Enhancement**:
    *   **Connects Tactical to Strategic**: It creates a formal bridge between immediate, tactical learnings and long-term, strategic memory. The agent doesn't have to rediscover these small insights during the big fold; they are fed in as established facts.
    *   **Improves Folding Quality and Efficiency**: The memory folding process becomes more accurate because it's "seeded" with pre-analyzed insights. This helps the auxiliary LLM focus on the most important events and relationships, potentially making the fold faster and more relevant.
    *   **Hierarchical Reflection**: The agent essentially reflects twice: a quick, tactical reflection after each action, and a deep, strategic reflection during a fold, with the former informing the latter.

---

### **Phase 5 (Advanced): Experiment with Learned Compression (ACON)**

**Goal**: Make the memory folding process itself adaptive and intelligent.

#### Step-by-Step Implementation:

1.  **Data Collection & Failure Analysis**: Create an offline pipeline to analyze failed runs and identify what critical information (or triplets) were lost during folding.
2.  **Generate Compression Guidelines**: The output of this analysis would be a set of guidelines (e.g., "For coding tasks, always preserve the exact definition of functions mentioned in error messages.").
3.  **Dynamic Prompt Injection**: Inject these learned guidelines into the memory generation prompts at runtime.

*   **Why it's Promising**: This would create a system that **learns from its own mistakes on a meta-level**, adapting its own memory-creation process. This is a significant step towards more general and robust AI.