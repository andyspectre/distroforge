#!/bin/bash

# Constants
readonly SCRIPTS_DIR
SCRIPTS_DIR="$(pwd)"
export SCRIPTS_DIR

# Initialize variables
container_name=""
distrobox_ini="./distrobox.ini" # Default value in current directory
dotfiles_path=""                # Default dotfiles path

# Function to display help information
show_help() {
	cat <<EOF
Usage: $0 [OPTIONS]
Options:
  -n, --name NAME     Container name to create
  -f, --file FILE     Path to distrobox.ini file (default: ./distrobox.ini)
  -d, --dotfiles DIR  Path to dotfiles directory for configuration
  -h, --help          Show this help message
If no options are provided, creates all containers from ./distrobox.ini
EOF
	exit 1
}

# Parse arguments
parse_arguments() {
	while :; do
		case $1 in
		-h | --help)
			show_help
			;;
		-n | --name)
			if [ -n "$2" ]; then
				container_name="$2"
				shift
				shift
			fi
			;;
		-f | --file)
			if [ -n "$2" ]; then
				distrobox_ini="$2"
				shift
				shift
			fi
			;;
		-d | --dotfiles)
			if [ -n "$2" ]; then
				dotfiles_path="$2"
				shift
				shift
			else
				echo "--dotfiles requires a non-empty option argument."
				exit 1
			fi
			;;
		-*)
			echo "Unknown option: $1"
			show_help
			;;
		*)
			if [ -n "$1" ]; then
				echo "Unknown argument: $1"
				show_help
			fi
			break
			;;
		esac
	done
}

# Check if the environment is set up correctly
check_environment() {
	# Check if the distrobox.ini file exists
	if [ ! -f "${distrobox_ini}" ]; then
		echo "Distrobox configuration file ${distrobox_ini} not found."
		exit 1
	fi

	# Check if the dotfiles_path directory exists if provided
	if [ -n "${dotfiles_path}" ]; then
		if [ ! -d "${dotfiles_path}" ]; then
			echo "Dotfiles path ${dotfiles_path} does not exist."
			exit 1
		fi
	fi
}

# Check if the container is rootful
is_rootful() {
	container_name="$1"

	if sed -n "/\[${container_name}\]/,/^$/p" "distrobox.ini" | grep -q "root=true"; then
		echo "true"
	else
		echo "false"
	fi
}

# Get a list of tags
get_tags() {
	container_name="$1"
	tags=$(grep <"${distrobox_ini}" -B 1 "\[${container_name}\]" | grep "# tags:" | sed 's/# tags: \(.*\)/\1/')
	if [ -z "${tags}" ]; then
		echo ""
	else
		# Return the tags as a string
		echo "${tags}"
	fi
}

# Check that config script is available
check_config_script() {
	config_script="$1"

	if [ ! -f "${SCRIPTS_DIR}/${config_script}" ]; then
		echo "Error: ${config_script} not found in SCRIPTS_DIR: (${SCRIPTS_DIR}). Skipping it."
		return 1
	fi
	return 0
}

# Configure the container
configure_container() {
	container="$1"
	tags=$(get_tags "${container}")

	if [ -z "${tags}" ]; then
		echo "No tags found for container ${container}. No configuration needed."
		return
	else
		echo "Configuring container: ${container} with the following tags: ${tags}"
		for tag in ${tags}; do
			if check_config_script "${tag}_config.sh"; then
				rootful=$(is_rootful "${container}")
				if [ "${rootful}" = "true" ]; then
					echo "Container ${container} is a rootful container."
					distrobox-enter --root "${container}" -- bash -c "export DOTFILES_PATH=${dotfiles_path}  && cd ${SCRIPTS_DIR} && ./${tag}_config.sh"
				else
					distrobox-enter "${container}" -- bash -c "export DOTFILES_PATH=${dotfiles_path} && cd ${SCRIPTS_DIR} && ./${tag}_config.sh"
				fi
			else
				continue
			fi
		done
	fi
}

# Create the container
create_container() {
	# Create all the containers listed in the distrobox.ini file or the specified container
	if [ -z "${container_name}" ]; then
		echo "No container name provided. Creating all containers from ${distrobox_ini}."

		distrobox-assemble create --file "${distrobox_ini}"

		# Get all container names from distrobox.ini
		containers=$(grep -E '^\[.*\]' "${distrobox_ini}" | tr -d '[]')

		# Configure each container
		for cont in ${containers}; do
			configure_container "${cont}"
		done
	else
		if ! grep -q "${container_name}" "${distrobox_ini}"; then
			echo "Container name ${container_name} not found in ${distrobox_ini}."
			exit 1
		else
			echo "Creating container: ${container_name}"
			distrobox-assemble create --name "${container_name}" --file "${distrobox_ini}"

			# Configure the container
			configure_container "${container_name}"
		fi
	fi
}

# Main function
main() {
	# Parse arguments
	parse_arguments "$@"

	# Check environment first
	check_environment

	# Create the container
	create_container
}

main "$@"
