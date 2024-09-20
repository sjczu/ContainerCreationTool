#!/bin/bash

COMPOSE_PATH="/app"

print_main_menu() {
    clear
    echo "***************************************"
    echo "***************MAIN MENU***************"
    echo "*        1. Container creation        *"
    echo "*      2. Show Running Containers     *"
    echo "* 3. Scan App Logs for ERROR Messages *"
    echo "*               4. Exit               *"
    echo "***************         ***************"
    echo "***************************************"
}

choose_docker_image() {
    while true; do
        clear
        echo "Available Docker Images:"
        echo "-------------------------"

        docker images --format "{{.Repository}}:{{.Tag}}" > temp_images.txt

        local count=1
        while IFS= read -r line; do
            echo "$count: $line"
            count=$((count + 1))
        done < temp_images.txt

        echo "0: Go back to Main Menu"
        echo "-------------------------"

        read -p "Select an image by entering its number: " choice

        if [ "$choice" == "0" ]; then
            rm temp_images.txt
            return 0
        fi

        if [[ "$choice" =~ ^[0-9]+$ && "$choice" -ge 1 && "$choice" -lt "$count" ]]; then

            selected_image=$(sed -n "${choice}p" temp_images.txt)

            echo "You selected: $selected_image"
            read -p "Press any key to continue..."
            rm temp_images.txt
            return 0
        else
            echo "Invalid choice. Try again."
            read -p "Press any key to continue..."
        fi
    done
}


specify_service_name() {
    echo "Specify the service name:"
    read -r SERVICE_NAME
    echo "Service name set to $SERVICE_NAME."
}

select_compose() {
    navigate_directory "$COMPOSE_PATH"

    COMPOSE_FILE="$SELECTED_FILE"

    if [ -f "$COMPOSE_FILE" ]; then
        cp "$COMPOSE_FILE" "/app/composeBackup/$(basename "$COMPOSE_FILE")"
        sed -i "0/\${image}/s/\${image}/$IMAGE/" "$COMPOSE_FILE"
        echo "Docker Compose file set to $COMPOSE_FILE."
    else
            echo "ERROR: $(basename "$COMPOSE_FILE") does not exist in $COMPOSE_PATH"
    fi
}

select_flag(){
    echo "Choose Docker Compose options:"
    echo "1. Use '-d' flag (detached mode)"
    echo "2. Use '--no-start' flag"
    echo "3. No additional flags"
    echo "4. Go back to the previous menu"

    read -r opt
    case $opt in
        1) FLAGS="-d" ;;
        2) FLAGS="--no-start" ;;
        3) FLAGS="" ;;
        4) continue ;;
        *) FLAGS="" ;;
    esac
}


create_container() {
    while true; do
        clear
        echo "Create Container Menu:"
        echo "1. Choose Docker Compose File"
        echo "2. Choose Docker Image"
        echo "3. Choose Docker Compose Options"
        echo "4. Specify Service and Container Name"
        echo "5. Create Container"
        echo "6. Go back to Main Menu"

        read -r choice
        case $choice in
            1)
                clear
                select_compose
                ;;
            2)
                clear
                choose_docker_image
                ;;
            3)
                clear
                select_flag
                ;;
            4)
                clear
                specify_service_name
                ;;
            5)
                clear
                if [ -z "$COMPOSE_FILE" ] || [ -z "$IMAGE" ] || [ -z "$SERVICE_NAME" ]; then
                    echo "Please complete all previous steps before creating the container."
                else
                    cmd="docker-compose -f $COMPOSE_FILE up $FLAGS $SERVICE_NAME"
                    echo "Executing command: $cmd"
                    $cmd
                    echo "Container created. Press Enter to return to the Main Menu or 'b' to continue."
                    read -r key
                    if [ "$key" = "b" ]; then
                        continue
                    fi
                fi
                ;;
            6)
                break
                ;;
            *)
                echo "Invalid choice. Press Enter to try again or 'b' to return to the menu."
                read -r key
                if [ "$key" = "b" ]; then
                    continue
                fi
                ;;
        esac
    done
}


show_running_containers() {
    while true; do
        clear
        echo "Displaying running Docker containers:"
        docker ps
        echo "Press '0' to return to the Main Menu or 'b' to refresh the container list."

        read -r key
        if [ "$key" = "0" ]; then
            break
        elif [ "$key" = "b" ]; then
            continue
        fi

        sleep 1
    done
}


navigate_directory() {
    CURRENT_DIR="$1"
    while true; do
        clear
        echo "Current Directory: $CURRENT_DIR"
        echo "Choose a directory or file to scan, or type '..' to go back."
        echo "0: Go back to Main Menu"
        echo "-----------------------------"

        local options=($(ls -1 "$CURRENT_DIR"))
        local count=1

        for option in "${options[@]}"; do
            echo "$count: $option"
            count=$((count + 1))
        done

        read -p "Enter your choice: " choice

        if [ "$choice" == "0" ]; then
            return 0

        elif [ "$choice" == ".." ]; then
            CURRENT_DIR=$(dirname "$CURRENT_DIR")

        elif [[ "$choice" =~ ^[0-9]+$ && "$choice" -le "${#options[@]}" ]]; then
            selected="${options[$((choice - 1))]}"

            if [ -d "$CURRENT_DIR/$selected" ]; then
                CURRENT_DIR="$CURRENT_DIR/$selected"
            else
                SELECTED_FILE="$CURRENT_DIR/$selected"
                echo "You selected: $SELECTED_FILE"
                read -p "Press any key to continue..."
                return 0
            fi

        else
            echo "Invalid choice. Try again."
            read -p "Press any key to continue..."
        fi
        done
}

scan_error_logs() {
    while true; do
        clear

        navigate_directory "/app/log"
        LOG_PATH="$SELECTED_FILE"

        echo "Scanning app logs for ERROR messages..."

        grep "ERROR" "$LOG_PATH" | tail -n 10

        echo "Log scan complete. Press Enter to return to the Main Menu or 'b' to rescan."

        read -r key
        if [ "$key" = "b" ]; then
            continue
        elif [ "$key" = "" ]; then
            break
        fi
    done
}

while true; do
    print_main_menu
    read -r choice
    case $choice in
        1) create_container ;;
        2) show_running_containers ;;
        3) scan_error_logs ;;
        4) exit 0 ;;
        *) echo "Invalid choice. Press Enter to try again." ; read ;;
    esac
done
