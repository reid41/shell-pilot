#!/usr/bin/env bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo -e "\033[36mThis script must be run as root.\033[0m"
  exit 1
fi

# Check for required dependencies
dependencies=(curl jq)
missing_deps=()

for dep in "${dependencies[@]}"; do
  if ! type "$dep" &>/dev/null; then
    missing_deps+=("$dep")
  fi
done

# Function to suggest how to install missing dependencies
suggest_installation() {
  local os_type="$(uname -s)"
  case "$os_type" in
    Darwin)
      echo "brew install ${1}"
      ;;
    Linux)
      if [[ -f /etc/debian_version ]]; then
        echo "sudo apt-get install ${1} -y"
      elif [[ -f /etc/redhat-release ]]; then
        echo "sudo yum install ${1} -y"
      fi
      ;;
    *)
      echo "echo 'Your operating system is not supported by this script's automatic dependency installation guide.'"
      ;;
  esac
}

if [ ${#missing_deps[@]} -ne 0 ]; then
  echo -e "\033[36mYou need to install the following to use the shell pilot script: ${missing_deps[*]}.\033[0m"
  for dep in "${missing_deps[@]}"; do
    echo -n "Would you like to install ${dep}? (y/n): "
    read answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
      install_command=$(suggest_installation "$dep")
      echo "Installing ${dep}..."
      eval "$install_command"
    else
      echo "${dep} installation skipped."
    fi
  done
fi

echo "==> All required dependencies are installed or skipped by the user."

# Define the installation path
INSTALL_PATH="/usr/local/bin"
PLUGINS_PATH="/usr/local/bin/plugins"
[ ! -d $PLUGINS_PATH ] && mkdir $PLUGINS_PATH -p

# Define URLs for the script and configuration file
SHELL_PILOT_SCRIPT_URL="https://raw.githubusercontent.com/reid41/shell-pilot/main/s-pilot"
SHELL_PILOT_COMMON_URL="https://raw.githubusercontent.com/reid41/shell-pilot/main/spilot_common.sh"
SHELL_PILOT_COMMON_URL="https://raw.githubusercontent.com/reid41/shell-pilot/main/spilot_llm_rq_apis.sh"
SHELL_PILOT_PLUGINS_PV_URL="https://raw.githubusercontent.com/reid41/shell-pilot/main/plugins/package_version.sh"
SHELL_PILOT_PLUGINS_SA_URL="https://raw.githubusercontent.com/reid41/shell-pilot/main/plugins/system_alias.sh"

# Function to download shell-pilot scripts with retries
shell_pilot_download_script() {
    local url="$1"
    local path="$2"
    local retries=3

    while [ $retries -gt 0 ]; do
        curl -sS "$url" -o "$path"
        if [ $? -eq 0 ]; then
            echo "$path downloaded successfully."
            return 0
        else
            echo "Failed to download $path, retrying..."
            retries=$((retries - 1))
            sleep 1
        fi
    done

    echo "Failed to download $path."
    return 1
}

# Function to add alias to a given profile
function add_alias_to_profile() {
    local profile_file="$1"
    local alias_name="ss-pilot"
    local alias_command="source s-pilot"

    # Check if the alias already exists in the profile
    if ! grep -q "^alias $alias_name=" "$profile_file"; then
        echo "alias $alias_name='$alias_command'" >> "$profile_file"
        echo "Alias '$alias_name' added to $profile_file"
        source "$profile_file"
    else
        echo "Alias '$alias_name' already in $profile_file"
    fi
}

# Download the s-pilot script
shell_pilot_download_script "$SHELL_PILOT_SCRIPT_URL" "${INSTALL_PATH}/s-pilot" || exit 1

# Download the configuration file spilot_common.sh
shell_pilot_download_script "$SHELL_PILOT_COMMON_URL" "${INSTALL_PATH}/spilot_common.sh" || exit 1
shell_pilot_download_script "$SHELL_PILOT_COMMON_URL" "${INSTALL_PATH}/spilot_llm_rq_apis.sh" || exit 1
shell_pilot_download_script "$SHELL_PILOT_PLUGINS_PV_URL" "${PLUGINS_PATH}/package_version.sh" || exit 1
shell_pilot_download_script "$SHELL_PILOT_PLUGINS_SA_URL" "${PLUGINS_PATH}/system_alias.sh" || exit 1

# Optionally, set execute permissions
chmod +x "${INSTALL_PATH}/s-pilot"
chmod +x "${INSTALL_PATH}/spilot_common.sh"
chmod +x "${INSTALL_PATH}/spilot_llm_rq_apis.sh"
chmod +x "${PLUGINS_PATH}/package_version.sh"
chmod +x "${PLUGINS_PATH}/system_alias.sh"

echo "==> Shell Pilot installation completed."

# Determine which shell profile is present and add the alias
if [ -f ~/.zprofile ]; then
  add_alias_to_profile ~/.zprofile
elif [ -f ~/.zshrc ]; then
  add_alias_to_profile ~/.zshrc
elif [ -f ~/.bash_profile ]; then
  add_alias_to_profile ~/.bash_profile
elif [ -f ~/.profile ]; then
  add_alias_to_profile ~/.profile
else
  echo "Could not find a known shell profile. Please manually add: alias ss-pilot='source s-pilot'"
fi

# Function to add environment variables to the user's shell profile
add_to_profile() {
  local profile_path="$1"
  local api_key="$2"
  local api_key_name="$3"

  echo "export $api_key_name='$api_key'" >> "$profile_path"
  if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
    echo 'export PATH="$PATH:/usr/local/bin"' >> "$profile_path"
  fi
  echo "$api_key_name and PATH were added to $profile_path"
  source "$profile_path"
}

# Function to validate the installation of API keys
validate_installation() {
  local api_key_name=$1
  local api_key=$2

  if [[ "${!api_key_name}" != "$api_key" ]]; then
    echo "Failed to set $api_key_name correctly."
    return 1
  fi

  echo "Verification successful: $api_key_name is correctly set."
  return 0
}

# Function to confirm the API key input
ask_for_confirmation() {
  local api_key_name="$1"
  local api_key_value=""

  while true; do
    read -p "Please enter your $api_key_name (leave blank if not using): " api_key_value
    if [[ -z "$api_key_value" ]]; then
      echo ""
      break
    fi
    
    # request confirmation
    while true; do
      read -p "Is this correct? (Y/n to confirm, any other key to re-enter): " confirm
      case $confirm in
        [Yy]* ) echo $api_key_value; return;;  # confirm the API key
        [Nn]* | * )
          read -p "Please re-enter your $api_key_name:" re_enter_key
          api_key_value=$re_enter_key
          continue;;  # re-enter the API key
      esac
    done
  done
}


# Function to get and confirm API key
get_and_confirm_api_key() {
  local api_key_name="$1"
  local api_key_value=""

  # Keep asking until a valid confirmation is received or input is left blank
  api_key_value=$(ask_for_confirmation "$api_key_name")
  echo $api_key_value
}


# Prompt the user to enter the API keys
echo "==> The script will add the OPENAI_KEY and MISTRAL_API_KEY environment variables to your shell profile and add /usr/local/bin to your PATH."
read -p "==> Would you like to continue? (y/n): " -n 1 -r
echo


if [[ $REPLY =~ ^[Yy]$ ]]; then
  openai_key=$(get_and_confirm_api_key "OpenAI API key")
  mistral_key=$(get_and_confirm_api_key "Mistral API key")

  # Determine which shell profile is present and add the API keys
  if [ -f ~/.zprofile ]; then
    [[ ! -z "$openai_key" ]] && echo "export OPENAI_KEY='$openai_key'" >> ~/.zprofile
    [[ ! -z "$mistral_key" ]] && echo "export MISTRAL_API_KEY='$mistral_key'" >> ~/.zprofile
  elif [ -f ~/.zshrc ]; then
    [[ ! -z "$openai_key" ]] && echo "export OPENAI_KEY='$openai_key'" >> ~/.zshrc
    [[ ! -z "$mistral_key" ]] && echo "export MISTRAL_API_KEY='$mistral_key'" >> ~/.zshrc
  elif [ -f ~/.bash_profile ]; then
    [[ ! -z "$openai_key" ]] && echo "export OPENAI_KEY='$openai_key'" >> ~/.bash_profile
    [[ ! -z "$mistral_key" ]] && echo "export MISTRAL_API_KEY='$mistral_key'" >> ~/.bash_profile
  elif [ -f ~/.profile ]; then
    [[ ! -z "$openai_key" ]] && echo "export OPENAI_KEY='$openai_key'" >> ~/.profile
    [[ ! -z "$mistral_key" ]] && echo "export MISTRAL_API_KEY='$mistral_key'" >> ~/.profile
  else
    echo "Could not find a known shell profile. Please manually add your API keys."
  fi
fi


# Function to check and append OLLAMA_SERVER_IP to the specified configuration file
add_ollama_ip() {
  local config_file=$1

  # Check if the OLLAMA_SERVER_IP variable already exists in the configuration file
  if grep -q "OLLAMA_SERVER_IP=" "$config_file"; then
    local existing_ip=$(grep "OLLAMA_SERVER_IP=" "$config_file" | cut -d'=' -f2)
    if [[ $existing_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "OLLAMA_SERVER_IP is already set to a valid IP address: $existing_ip"
      return 0
    else
      echo "Error: OLLAMA_SERVER_IP is set but not valid: $existing_ip"
      return 1
    fi
  else
    # The variable does not exist, prompt user for input
    while true; do
      read -p "Enter the OLLAMA server IP address[q to quit]: " ip_address
      if [[ $ip_address =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "OLLAMA_SERVER_IP=$ip_address" >> "$config_file"
        echo "OLLAMA_SERVER_IP added to $config_file"
        break
      elif [[ "$ip_address" == "q" ]]; then
        echo "OLLAMA_SERVER_IP not added."
        break
      else
        echo "Error: Invalid IP address entered. Please enter a valid IP address."
      fi
    done
  fi
}

# Specify the configuration file path
CONFIG_FILE="${INSTALL_PATH}/spilot_common.sh"

# Check and append OLLAMA_SERVER_IP
if add_ollama_ip "$CONFIG_FILE"; then
  echo "Operation successful."
else
  echo "Operation failed. Please check the errors above."
fi