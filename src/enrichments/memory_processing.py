# This module contains the enhanced memory processing logic, including knowledge triplet extraction.

import asyncio
import json
import re
from typing import List, Dict

def get_knowledge_triplet_extraction_instruction(question: str, full_history: str) -> str:
    """Creates a prompt to instruct an LLM to extract a knowledge graph from an agent's history."""
    return f"""You are a high-precision knowledge extraction AI. Your task is to analyze the full reasoning history of a task and extract all significant factual information as a list of knowledge triplets.

Task Goal: {question}

Full Reasoning History:
{full_history}

Instructions:
1.  Read the entire history, including thoughts, tool calls, and tool responses.
2.  Identify key entities (e.g., 'user', 'agent', 'current_goal', tool names, specific parameters) and their relationships or states.
3.  Extract this information into a structured list of triplets, where each triplet is `['subject', 'predicate', 'object']`.
4.  Focus on facts, requirements, states, and causal relationships. Ignore conversational filler.
5.  Output a single JSON object containing a single key, `"knowledge_graph"`, whose value is the list of extracted triplets.

Example Output Format:
```json
{{
  "knowledge_graph": [
    ["user", "requires_price_lower_than", "$50.00"],
    ["user", "requires_scent", "bright_citrus"],
    ["agent", "identified_product", "B078GWRC1J"],
    ["product_B078GWRC1J", "price_is", "$10.99"],
    ["search_tool", "requires_parameter", "query"],
    ["last_action", "was", "click(B078GWRC1J)"]
  ]
}}
```

Now, analyze the provided history and extract the knowledge graph. Output only the JSON object.
"""

def extract_json_from_response(response: str) -> dict:
    """Extract JSON content from response, handling markdown code blocks."""
    try:
        pattern = r'```json\s*(.*?)\s*```'
        match = re.search(pattern, response, re.DOTALL)
        json_str = match.group(1).strip() if match else response.strip()
        return json.loads(json_str)
    except (json.JSONDecodeError, AttributeError) as e:
        print(f"Error decoding JSON from response: {e}\nResponse was: {response}")
        return None

async def extract_knowledge_triplets(
    client,
    tokenizer,
    semaphore,
    args,
    question: str,
    current_output: str,
    generate_response_func
) -> List[List[str]]:
    """
    Analyzes the agent's history and extracts a consolidated list of knowledge triplets.
    """
    full_history = "\n\n".join([f"Step {i+1}: {step}" for i, step in enumerate(current_output.split("\n\n"))])
    
    prompt = get_knowledge_triplet_extraction_instruction(question, full_history)
    
    _, response = await generate_response_func(
        client=client,
        tokenizer=tokenizer,
        model_name=args.aux_model_name,
        prompt=prompt,
        semaphore=semaphore,
        generate_mode="chat",
        temperature=args.temperature,
        top_p=args.top_p,
        max_tokens=args.max_tokens,
        repetition_penalty=args.repetition_penalty,
        top_k=args.top_k_sampling,
    )
    
    extracted_data = extract_json_from_response(response)
    
    if extracted_data and isinstance(extracted_data.get('knowledge_graph'), list):
        return extracted_data['knowledge_graph']
    else:
        print("Could not extract a valid knowledge graph from the response.")
        return []