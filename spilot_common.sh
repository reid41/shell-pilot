# This is config file for spilot
GLOBIGNORE="*"
# output formatting
SHELLPILOT_CYAN_LABEL="\033[94m<<ShellPilot>> \033[0m"
PROCESSING_LABEL="\n\033[92m  Processing... \033[0m\033[0K\r"
OVERWRITE_PROCESSING_LINE="             \033[0K\r"
COLUMNS=$(tput cols)

# version: major.minor.patch
SHELL_PILOT_VERSION=1.13.7

# store directory
SPILOT_FILES_DEFAULT_DIR=~/spilot_files_dir

# the list models cache setting
CACHE_MAX_AGE=3600
LIST_MODELS_CACHE_FILE="$SPILOT_FILES_DEFAULT_DIR/models_list.cache"

# Configuration settings: ollama, openai, mistralai
USE_API=ollama
CURRENT_DATE=$(date +%m/%d/%Y)

# Set default values for Ollama settings
if [ "$USE_API" == "ollama" ]; then
    MODEL_NAME="Ollama"
    ORGANIZATION="Ollama"
fi

# Adjust settings for OpenAI settings
if [ "$USE_API" == "openai" ]; then
    MODEL_NAME="ChatGPT"
    ORGANIZATION="OpenAI"
fi

# Adjust settings for Mistral AI API
if [ "$USE_API" == "mistralai" ]; then
    MODEL_NAME="Mistral AI"
    ORGANIZATION="Mistral AI"
fi

# Adjust settings for Mistral AI API
if [ "$USE_API" == "localai" ]; then
    MODEL_NAME="LocalAI"
    ORGANIZATION="LocalAI"
fi

# Adjust settings for ZhipuAI AI API
if [ "$USE_API" == "zhipuai" ]; then
    MODEL_NAME="ZhipuAI"
    ORGANIZATION="ZhipuAI"
fi

if [ "$USE_API" == "moonshot" ]; then
    MODEL_NAME="Moonshot"
    ORGANIZATION="Moonshot"
fi

# Define prompts using the adjusted settings
CHAT_INIT_PROMPT="You are $MODEL_NAME, a Large Language Model trained by $ORGANIZATION. You will be answering questions from users. Answer as concisely as possible for each response. Keep the number of items short. Output your answer directly, with no labels in front. Today's date is $CURRENT_DATE."
SYSTEM_PROMPT="You are $MODEL_NAME, a large language model trained by $ORGANIZATION. Answer as concisely as possible. Current date: $CURRENT_DATE."
COMMAND_GENERATION_PROMPT="You are a Command Line Interface expert and your task is to provide functioning shell commands. Return a CLI command and nothing else - do not send it in a code block, quotes, or anything else, just the pure text CONTAINING ONLY THE COMMAND. If possible, return a one-line bash command or chain many commands together. Return ONLY the command ready to run in the terminal. The command should do the following:"

# chat settings
TEMPERATURE=0.9
MAX_TOKENS=4096
MODEL_OPENAI=gpt-3.5-turbo
MODEL_OLLAMA=llama2
MODEL_MISTRALAI=mistral-small
MODEL_LOCALAI=gpt-4
MODEL_ZHIPUAI=glm-4
MODEL_MOONSHOT=moonshot-v1-8k
MODEL_ANTHROPIC=claude-3-opus-20240229
CONTEXT=false
MULTI_LINE_PROMPT=false
ENABLE_DANGER_FLAG=false
DANGEROUS_COMMANDS=("rm" ">" "mv" "mkfs" ":(){:|:&};" "dd" "chmod" "wget" "curl")
