import re
import os

def extract_prompt(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Extract the string within the buildSystemPrompt return
    match = re.search(r"return '''(.*?)''';", content, re.DOTALL)
    if match:
        return match.group(1).strip()
    return "Could not extract prompt."

def run_simulation():
    # Paths
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    llm_service_path = os.path.join(project_root, 'aidem_app', 'lib', 'services', 'llm_service.dart')
    
    prompt = extract_prompt(llm_service_path)
    
    print("="*60)
    print("AIDEM SIMULATION RUNNER")
    print("="*60)
    print("\n[SYSTEM PROMPT EXTRACTED]:\n")
    print(prompt)
    print("\n" + "="*60)
    print("\nINSTRUCTIONS:")
    print("1. Copy the System Prompt above.")
    print("2. Paste it into your LLM (Ollama, Gemini, etc.)")
    print("3. Start the conversation based on a scenario.")
    print("4. Verify if the agent follows the 'Humanity' and 'Urgency' rules.")
    print("="*60)

if __name__ == "__main__":
    run_simulation()
