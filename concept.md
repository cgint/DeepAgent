Concept Memo: An Information-Centric Agent
Architecture (v3)

1. The Problem Domain: Evolving from Agent Structures to
   Information Coherence
   Our exploration focuses on creating robust, autonomous agents capable of handling long-horizon, complex
   tasks where effective context management is the central challenge. The understanding of this problem
   domain has evolved through evaluating potential architectures and their inherent limitations.
   Initial Problem Definition:
   ● Context Overload: The primary challenge identified was the "ever-growing context" in LLM agents. As
   agents perform actions, gather observations, and generate intermediate thoughts, the sheer volume of
   information quickly exceeds practical limits. This leads to high computational costs, increased latency,
   and potential performance degradation as the LLM struggles to discern relevant signals amidst noise
   ("context distraction," as noted in studies like ACON).
   ● Information Loss: Simple context management techniques (truncation, basic summarization) often fail,
   suffering from "brevity bias" or "context collapse" (highlighted by ACE). These methods risk discarding
   crucial details, domain-specific nuances, or historical error patterns, undermining the agent's ability to
   perform complex, multi-step reasoning.
   Evaluating the Hierarchical Agent Architecture:
   ● An initial architectural concept involved a hierarchical ReAct system. The idea was to manage
   complexity by having a "supervisor" agent decompose tasks and "isolate and delegate" sub-tasks to
   specialized "worker" agents.
   ● The anticipated benefit was modularity. However, the core challenge remained context management:
   ensuring the supervisor could effectively pass the correct subset and granularity of information to each
   worker, avoiding both overload and critical omissions.
   Refining the Problem Domain - Why Hierarchies Fall Short:
   ● Upon critical re-evaluation, inspired by analyses like Cognition AI's ("Don't Build Multi-Agents"), the
   hierarchical model was identified as fundamentally flawed for ensuring robust, coherent operation:
   ○ Unmanageable Complexity: The practicalities of managing agent interactions, state
   synchronization across isolated units, inter-agent communication protocols, and handling failures
   within a hierarchy introduce significant, often brittle, complexity. The focus shifts towards managing
   the agent structure rather than the task itself.
   ○ Inherent Context Fragmentation: The most critical flaw is that isolated agents do not
   inherently share context. Each worker operates on a potentially incomplete or inconsistent view of
   the overall state provided by the supervisor. This violates the crucial principle of shared context
   (Cognition AI's "Share Context"), leading inevitably to conflicting assumptions, misaligned actions,
   and unreliable outcomes. The supervisor becomes a bottleneck and a potential point of information
   distortion.
   ● Revised Problem Interpretation: The core issue is not just managing context size, but ensuring
   context coherence and accessibility. Fragile agent structures with information silos actively hinder this.
   Therefore, the problem is better framed as: How can we build a flexible, long-horizon system that
   maintains a unified, coherent information state accessible to all reasoning steps, facilitates
   iterative refinement based on that state, and avoids the fragility and information fragmentation
   of multi-agent architectures?
2. The Latest Concept: An Information-Centric Management
   System
   Instead of managing agent structures, this concept focuses on managing the flow, structure, and
   refinement of information itself, directly embracing Cognition AI's principles.
   Core Principle:
   The system operates around a central, evolving information pool serving as a shared context. This pool is
   iteratively refined by various tasks (tools or LLM calls) selected dynamically until the goal is achieved.
   System Components:
3. The Information Pool: A central repository holding all goal-related knowledge. This is more than just a
   transcript; it's a structured collection including:
   ○ Raw data, observations, user instructions.
   ○ Current plans, sub-goals, hypotheses.
   ○ Partial results, generated code, tool outputs.
   ○ Analyses, reflections on past steps (successes/failures).
   ○ Crucially, provenance information: tracking the origin of each piece of information (which task
   generated it, based on what inputs) directly supports Cognition's "Actions carry implicit decisions"
   principle by making the decision history explicit.
4. The Control Mechanism: A dynamic "decider" or "meta-reasoner." At each step, this component
   analyzes the entire information pool to determine the next logical task (e.g., Web-Search, Code-Search,
   Refine-Plan, Validate-Hypothesis, Execute-Tool).
   ○ Implementation via DSPy: This mechanism could be effectively implemented as a DSPy program.
   DSPy allows defining this complex decision-making logic programmatically using:
   ■ Modules (like dspy.ReAct or dspy.ChainOfThought) to encapsulate reasoning patterns.
   ■ Signatures to enforce structured analysis of the Information Pool (input) and structured
   selection of the next task (output).
5. Task Executors: A library of tools or specialized LLM calls (potentially also implemented as DSPy
   modules with specific Signatures) that perform the tasks selected by the Control Mechanism. Each
   executor:
   ○ Takes specific, structured inputs derived from the Information Pool (as defined by its Signature).
   ○ Produces structured outputs that add to or refine the Information Pool.
   Key Advantages:
   ● Solves Context Coherence: The Information Pool is the single, shared context, eliminating
   fragmentation and ensuring consistency (aligns with Cognition's "Share Context").
   ● Embraces Flexibility: The Control Mechanism dynamically adapts task selection based on the
   real-time state of the information, avoiding rigid, pre-defined workflows.
   ● Captures Provenance: Explicitly tracking information origins enhances debuggability, reliability, and
   allows for more nuanced reasoning by the Control Mechanism.
   ● Enables Self-Improvement: The iterative refinement loop, combined with structured components
   (DSPy) and provenance tracking, creates a foundation for automated optimization and learning.
6. Initial Prototyping Strategy
   To validate this concept, we will start pragmatically:
   ● Control Mechanism: Implement the core "decider" logic using the DSPy framework. Define the
   reasoning flow using appropriate DSPy modules and Signatures to structure the analysis of the
   information state and the selection of the next task. Utilize a capable LLM (e.g., Gemini 2.5 Pro or
   Flash) as the engine within these DSPy modules.
   ● Information Representation: Begin with simple Markdown files for the Information Pool. Use DSPy
   Signatures to define the expected structure for reading from and writing to these files, ensuring
   consistency even with a semi-structured format.
   ● Scalability & Validation: Test this core loop on smaller, well-defined tasks first. Focus on validating
   the workflow, the effectiveness of the DSPy-based Control Mechanism, and the utility of the
   provenance information before tackling larger problems where context size becomes a major factor.
   Appendix: Relevant Frameworks & Takeaways for Future
   Iterations
   The Information-Centric system's success hinges on managing the structure, size, and quality of the
   Information Pool, and the effectiveness of the Control Mechanism. Key frameworks offer powerful
   solutions:
   A. For Information Structure & Quality: ACE (Agentic Context Engineering)
   ● Key Idea: Treats context as an "evolving playbook" with structured entries (e.g., Strategies, Pitfalls,
   Code Snippets). Avoids "brevity bias" and "context collapse" seen in simple summarization.
   ● Relevance: Provides a methodology for structuring our Information Pool, making it more than just a log.
   We can organize derived knowledge into actionable playbook entries.
   ● Mechanisms:
   ○ Generate-Reflect-Curate Loop: A task is performed (Generate), the outcome analyzed (Reflect -
   identifying successes, failures, root causes), and key learnings added as structured entries to the
   pool (Curate). This loop can be implemented using DSPy modules.
   ○ Incremental Delta Updates: ACE modifies the playbook via small, targeted additions/updates
   rather than full rewrites, preserving existing knowledge reliably.
   ○ Label-Free Learning: ACE can improve the playbook using natural execution feedback (e.g., tool
   success/failure, test results) without needing ground-truth labels, enabling self-improvement.
   B. For Information Size Management: ACON (Agent Context Optimization)
   ● Key Idea: Learns an optimal compression strategy for long histories/contexts using failure-driven
   optimization.
   ● Relevance: Directly addresses the context window overflow problem when the Information Pool (even
   if structured) becomes too large.
   ● Mechanism:
   ○ Compares successful runs (full context) with failed runs (compressed context).
   ○ Uses an LLM to analyze why compression caused the failure.
   ○ Refines compression guidelines (rules) based on this analysis to learn what must be preserved.
   ○ Distillation: The learned compression strategy can potentially be distilled into a smaller, faster
   model to reduce overhead.
   C. For Control Mechanism Refinement: DSPy Optimizers (e.g., GEPA)
   ● Key Idea: DSPy includes optimizers that automatically tune the parameters (prompts/instructions and
   few-shot demonstrations) within a DSPy program to maximize performance on a given metric. GEPA is a
   state-of-the-art example.
   ● Relevance: Offers a powerful way to automate the improvement of the Control Mechanism itself.
   Instead of manually tuning the prompts that guide the "decider" LLM, GEPA can learn the most
   effective instructions.
   ● Mechanisms (GEPA):
   ○ Reflective Optimization: Uses a powerful LLM to analyze execution traces (provided by DSPy) of
   the Control Mechanism, identify failures or inefficiencies in its decision-making, and propose
   concrete improvements to its internal prompts/instructions.
   ○ Genetic-Pareto Evolution: Maintains a diverse set of high-performing instruction candidates,
   preventing convergence to a single, potentially brittle optimum.
   ○ Sample Efficiency: Significantly more efficient than traditional RL tuning, reducing the cost and
   time needed for optimization.
   ● Integration: By treating the DSPy-based Control Mechanism as the program to be optimized, and
   defining a metric for goal achievement, GEPA can be applied to autonomously enhance the system's
   core decision-making intelligence over time using collected execution data.
   ● Trade-off: Requires significant compute resources during the optimization ("compilation") phase but
   yields a potentially much more robust and performant Control Mechanism at inference time.
   D. DSPy vs. Orchestrators (e.g., LangChain)
   ● Distinction: Orchestrators focus on connecting components (LLMs, tools, data loaders) and defining
   high-level flow, often relying on static, hand-tuned prompts. DSPy focuses on the internal logic of LLM
   reasoning steps and automatically optimizing the prompts/parameters within those steps for maximum
   quality and reliability.
   ● Synergy: DSPy can optimize the core reasoning modules within a larger system potentially managed by
   an orchestrator, or it can manage the entire pipeline itself, offering a more programmatic and
   optimizable approach than traditional prompt templating.
   E. Referenced Papers/Documents
   ● ACON: 10191_ACON_Optimizing_Context_.pdf
   ● ACE: agentic-context-engineering.pdf
   ● Cognition: Cognition_Don_t_Build_Multi-Agents.pdf
   ● DSPy/GEPA: Technical Evaluation - DSPy and GEPA for Agentic Systems.pdf
