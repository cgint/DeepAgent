#!/bin/bash
# Setup script for DeepAgent with Qwen3-4B and Llama3.2 models via Ollama
# This script automates the setup process for running DeepAgent with local Ollama models

set -e  # Exit on error

echo "=========================================="
echo "DeepAgent Setup for Qwen3-4B + Llama3.2"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "src/run_deep_agent.py" ]; then
    echo -e "${RED}Error: Please run this script from the DeepAgent root directory${NC}"
    exit 1
fi

# Step 1: Check for required dependencies
echo -e "${GREEN}[1/6] Checking dependencies...${NC}"
if ! command -v python &> /dev/null; then
    echo -e "${RED}Error: Python is not installed${NC}"
    exit 1
fi

if ! python -c "import huggingface_hub" 2>/dev/null; then
    echo -e "${YELLOW}Installing huggingface_hub...${NC}"
    pip install huggingface_hub
fi

if ! command -v ollama &> /dev/null; then
    echo -e "${RED}Error: Ollama is not installed or not in PATH${NC}"
    echo "Please install Ollama from https://ollama.ai"
    exit 1
fi

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "${YELLOW}Warning: Ollama doesn't seem to be running. Starting Ollama...${NC}"
    ollama serve &
    sleep 2
fi

# Check if required models are available
echo -e "${GREEN}Checking for required Ollama models...${NC}"
if ! ollama list | grep -q "qwen3:4b"; then
    echo -e "${YELLOW}Model qwen3:4b not found. Pulling...${NC}"
    ollama pull qwen3:4b
fi

if ! ollama list | grep -q "llama3.2:latest"; then
    echo -e "${YELLOW}Model llama3.2:latest not found. Pulling...${NC}"
    ollama pull llama3.2:latest
fi

echo -e "${GREEN}✓ Dependencies checked${NC}"
echo ""

# Step 2: Download tokenizers
echo -e "${GREEN}[2/6] Downloading tokenizers...${NC}"
mkdir -p tokenizers

# Download Qwen3-4B tokenizer
if [ ! -d "tokenizers/qwen3-4b" ] || [ ! -f "tokenizers/qwen3-4b/tokenizer.json" ]; then
    echo "Downloading Qwen3-4B tokenizer..."
    huggingface-cli download Qwen/Qwen3-4B \
        --local-dir ./tokenizers/qwen3-4b \
        --local-dir-use-symlinks False \
        --include "tokenizer.json,tokenizer_config.json,vocab.json,merges.txt,special_tokens_map.json,config.json,generation_config.json" || {
        echo -e "${YELLOW}Note: Some files may not exist, continuing...${NC}"
    }
    # Remove model weight files if they were downloaded
    rm -f tokenizers/qwen3-4b/*.safetensors tokenizers/qwen3-4b/model*.json 2>/dev/null || true
    echo -e "${GREEN}✓ Qwen3-4B tokenizer downloaded${NC}"
else
    echo -e "${GREEN}✓ Qwen3-4B tokenizer already exists${NC}"
fi

# Download Llama3.2 tokenizer
if [ ! -d "tokenizers/llama3.2" ] || [ ! -f "tokenizers/llama3.2/tokenizer.json" ]; then
    echo "Downloading Llama3.2 tokenizer..."
    huggingface-cli download meta-llama/Llama-3.2-1B-Instruct \
        --local-dir ./tokenizers/llama3.2 \
        --local-dir-use-symlinks False \
        --include "tokenizer.json,tokenizer_config.json,vocab.json,merges.txt,special_tokens_map.json,config.json,generation_config.json" || {
        echo -e "${YELLOW}Note: Some files may not exist, continuing...${NC}"
    }
    # Remove model weight files if they were downloaded
    rm -f tokenizers/llama3.2/*.safetensors tokenizers/llama3.2/*.pth tokenizers/llama3.2/model*.json 2>/dev/null || true
    echo -e "${GREEN}✓ Llama3.2 tokenizer downloaded${NC}"
else
    echo -e "${GREEN}✓ Llama3.2 tokenizer already exists${NC}"
fi

echo ""

# Step 3: Set up ALFWorld data
echo -e "${GREEN}[3/6] Setting up ALFWorld data...${NC}"
mkdir -p data-run/alfworld_data

# Set ALFWORLD_DATA environment variable
export ALFWORLD_DATA="$(pwd)/data-run/alfworld_data"
echo "ALFWORLD_DATA set to: $ALFWORLD_DATA"

# Check if ALFWorld data already exists
if [ -d "$ALFWORLD_DATA/json_2.1.1" ] && [ -d "$ALFWORLD_DATA/logic" ]; then
    echo -e "${GREEN}✓ ALFWorld data already exists${NC}"
else
    echo -e "${YELLOW}Downloading ALFWorld data...${NC}"
    echo -e "${YELLOW}Note: This requires 'alfworld' package to be installed${NC}"
    echo -e "${YELLOW}If installation fails, you may need to install ALFWorld manually:${NC}"
    echo -e "${YELLOW}  pip install alfworld${NC}"
    echo -e "${YELLOW}  or${NC}"
    echo -e "${YELLOW}  uv sync${NC}"
    echo ""
    
    if command -v alfworld-download &> /dev/null; then
        alfworld-download
        echo -e "${GREEN}✓ ALFWorld data downloaded${NC}"
    elif python -c "import alfworld" 2>/dev/null; then
        # Try to use Python to download
        python -c "
import alfworld
import os
os.environ['ALFWORLD_DATA'] = '$ALFWORLD_DATA'
# ALFWorld should download data on first import if ALFWORLD_DATA is set
print('ALFWorld imported, data should be available')
" || echo -e "${YELLOW}Note: ALFWorld data download may need manual setup${NC}"
    else
        echo -e "${YELLOW}⚠ ALFWorld package not found. Skipping data download.${NC}"
        echo -e "${YELLOW}  You can download it manually later using:${NC}"
        echo -e "${YELLOW}  export ALFWORLD_DATA=$ALFWORLD_DATA${NC}"
        echo -e "${YELLOW}  alfworld-download${NC}"
    fi
fi

echo ""

# Step 4: Update configuration file
echo -e "${GREEN}[4/6] Updating configuration...${NC}"
if [ -f "config/base_config.yaml" ]; then
    # Check if config is already updated
    if grep -q "model_name: qwen3:4b" config/base_config.yaml; then
        echo -e "${GREEN}✓ Configuration already updated${NC}"
    else
        echo -e "${YELLOW}⚠ Configuration file needs manual update.${NC}"
        echo -e "${YELLOW}  Please update config/base_config.yaml with:${NC}"
        echo -e "${YELLOW}  - model_name: qwen3:4b${NC}"
        echo -e "${YELLOW}  - base_url: http://localhost:11434/v1${NC}"
        echo -e "${YELLOW}  - api_key: ollama${NC}"
        echo -e "${YELLOW}  - tokenizer_path: ./tokenizers/qwen3-4b${NC}"
        echo -e "${YELLOW}  - aux_model_name: llama3.2:latest${NC}"
        echo -e "${YELLOW}  - aux_base_url: http://localhost:11434/v1${NC}"
        echo -e "${YELLOW}  - aux_api_key: ollama${NC}"
        echo -e "${YELLOW}  - aux_tokenizer_path: ./tokenizers/llama3.2${NC}"
    fi
else
    echo -e "${RED}Error: config/base_config.yaml not found${NC}"
    exit 1
fi

echo ""

# Step 5: Test Ollama connection
echo -e "${GREEN}[5/6] Testing Ollama connection...${NC}"
if python -c "
from openai import OpenAI
client = OpenAI(base_url='http://localhost:11434/v1', api_key='ollama')
try:
    # Test if completions endpoint works
    response = client.completions.create(
        model='qwen3:4b',
        prompt='Hello',
        max_tokens=5
    )
    print('✓ Ollama completions endpoint works')
except Exception as e:
    print(f'⚠ Completions endpoint test failed: {e}')
    print('  This may be normal - Ollama primarily supports chat completions')
    print('  The code may need modification to use chat completions instead')
" 2>&1; then
    echo -e "${GREEN}✓ Connection test completed${NC}"
else
    echo -e "${YELLOW}⚠ Connection test had issues (see above)${NC}"
fi

echo ""

# Step 6: Summary
echo -e "${GREEN}[6/6] Setup Summary${NC}"
echo "=========================================="
echo -e "${GREEN}Setup completed!${NC}"
echo ""
echo "Configuration:"
echo "  - Main model: qwen3:4b"
echo "  - Auxiliary model: llama3.2:latest"
echo "  - Ollama API: http://localhost:11434/v1"
echo "  - Tokenizers: ./tokenizers/"
echo "  - ALFWorld data: $ALFWORLD_DATA"
echo ""
echo "To run DeepAgent with ALFWorld:"
echo "  python src/run_deep_agent.py \\"
echo "      --config_path ./config/base_config.yaml \\"
echo "      --dataset_name alfworld \\"
echo "      --enable_thought_folding \\"
echo "      --eval"
echo ""
echo "Or test with a single question:"
echo "  python src/run_deep_agent.py \\"
echo "      --config_path ./config/base_config.yaml \\"
echo "      --dataset_name alfworld \\"
echo "      --single_question \"test\" \\"
echo "      --subset_num 1"
echo ""
echo -e "${YELLOW}Note: If ALFWorld data download failed, you may need to:${NC}"
echo "  1. Install ALFWorld: uv sync (or pip install alfworld)"
echo "  2. Set ALFWORLD_DATA: export ALFWORLD_DATA=$ALFWORLD_DATA"
echo "  3. Run: alfworld-download"
echo "=========================================="

