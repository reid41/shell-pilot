#!/usr/bin/env bash

# This script is used to call the APIs of the SPilot LLM service.
# request to OpenAI API/ollama/mistral completions endpoint function
# $1 should be the request prompt
request_to_completions() {
	local prompt="$1"

	if [[ "$USE_API" == "ollama" ]]
	then
		curl http://${OLLAMA_SERVER_IP}:11434/api/generate \
		-sS \
		-d '{
			"model": "'"$MODEL_OLLAMA"'",
			"prompt": "'"$prompt"'",
			"max_tokens": '$MAX_TOKENS',
			"temperature": '$TEMPERATURE',
			"stream": false
			}'
	elif [[ "$USE_API" == "openai" ]]
	then
		curl https://api.openai.com/v1/completions \
		-sS \
		-H 'Content-Type: application/json' \
		-H "Authorization: Bearer $OPENAI_KEY" \
		-d '{
			"model": "'"$MODEL_OPENAI"'",
			"prompt": "'"$prompt"'",
			"max_tokens": '$MAX_TOKENS',
			"temperature": '$TEMPERATURE'
			}'
	elif [[ "$USE_API" == "localai" ]]
	then
		curl http://${LOCALAI_SERVER_IP}:8080/v1/completions \
		-sS \
		-H 'Content-Type: application/json' \
		-d '{
			"model": "'"$MODEL_LOCALAI"'",
			"prompt": "'"$prompt"'",
			"max_tokens": '$MAX_TOKENS',
			"temperature": '$TEMPERATURE'
			}'
	elif [[ "$USE_API" == "mistralai" ]]
	then 
		curl https://api.mistral.ai/v1/chat/completions \
		-sS \
		-H 'Content-Type: application/json' \
		-H 'Accept: application/json' \
		-H "Authorization: Bearer $MISTRAL_API_KEY" \
		-d '{
			"model": "'"$MODEL_MISTRALAI"'",
			"prompt": "'"$prompt"'",
			"max_tokens": '$MAX_TOKENS',
			"temperature": '$TEMPERATURE'
			}'
	else
		echo "Error: No API specified".
		exit 1
	fi
}

# request to OpenAPI API/ollama/mistral chat completion endpoint function
# $1 should be the message(s) formatted with role and content
request_to_chat() {
	local message="$1"
	escaped_system_prompt=$(escape "$SYSTEM_PROMPT")
	
	if [[ "$USE_API" == "ollama" ]]
	then
		curl http://${OLLAMA_SERVER_IP}:11434/api/chat \
		-sS \
		-d '{
            "model": "'"$MODEL_OLLAMA"'",
            "messages": [
                {"role": "system", "content": "'"$escaped_system_prompt"'"},
                '"$message"'
                ],
            "max_tokens": '$MAX_TOKENS',
            "temperature": '$TEMPERATURE',
			"stream": false
            }'
	elif [[ "$USE_API" == "openai" ]]
	then
		curl https://api.openai.com/v1/chat/completions \
			-sS \
			-H 'Content-Type: application/json' \
			-H "Authorization: Bearer $OPENAI_KEY" \
			-d '{
				"model": "'"$MODEL_OPENAI"'",
				"messages": [
					{"role": "system", "content": "'"$escaped_system_prompt"'"},
					'"$message"'
					],
				"max_tokens": '$MAX_TOKENS',
				"temperature": '$TEMPERATURE'
				}'
	elif [[ "$USE_API" == "localai" ]]
	then
		curl http://${LOCALAI_SERVER_IP}:8080/v1/chat/completions \
			-sS \
			-H 'Content-Type: application/json' \
			-d '{
				"model": "'"$MODEL_LOCALAI"'",
				"messages": [
					{"role": "system", "content": "'"$escaped_system_prompt"'"},
					'"$message"'
					],
				"temperature": '$TEMPERATURE'
				}'			
	elif [[ "$USE_API" == "mistralai" ]]
	then 
		curl https://api.mistral.ai/v1/chat/completions \
		-sS \
		-H 'Content-Type: application/json' \
		-H 'Accept: application/json' \
		-H "Authorization: Bearer $MISTRAL_API_KEY" \
		-d '{
			"model": "'"$MODEL_MISTRALAI"'",
			"messages": [
				{"role": "system", "content": "'"$escaped_system_prompt"'"},
				'"$message"'
				],
			"max_tokens": '$MAX_TOKENS',
			"temperature": '$TEMPERATURE'
		}'
	else
		echo "Error: No API specified".
		exit 1
	fi
}

fetch_model_from_ollama(){
    curl -s http://${OLLAMA_SERVER_IP}:11434/api/tags
}

fetch_model_from_openai(){
    curl https://api.openai.com/v1/models \
    -sS \
    -H "Authorization: Bearer $OPENAI_KEY"
}

fetch_model_from_localai(){
    curl http://${LOCALAI_SERVER_IP}:8080/v1/models
}

fetch_model_from_mistralai(){
    curl https://api.mistral.ai/v1/models\
    -sS \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -H "Authorization: Bearer $MISTRAL_API_KEY"
}
