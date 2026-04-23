#!/bin/bash

# Manico Configuration Sync Script
# This script handles exporting and importing Manico settings via 'defaults'

DOMAIN="im.manico.Manico"
CONFIG_FILE="$(dirname "$0")/settings.txt"

export_settings() {
    echo "Exporting Manico settings (excluding sensitive data)..."
    # List of keys to sync
    KEYS=(
        "overlay-alpha"
        "overlay-border-width"
        "overlay-center-x"
        "overlay-center-y"
        "overlay-size-scale"
        "running-mode"
        "screen-bar-position"
        "skip-welcome-window-v2"
    )

    > "$CONFIG_FILE"
    for KEY in "${KEYS[@]}"; do
        VAL=$(defaults read "$DOMAIN" "$KEY" 2>/dev/null)
        if [ $? -eq 0 ]; then
            TYPE=$(defaults read-type "$DOMAIN" "$KEY" | awk '{print $3}')
            echo "$KEY|$TYPE|$VAL" >> "$CONFIG_FILE"
        fi
    done
    echo "Settings saved to $CONFIG_FILE"
}

import_settings() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: $CONFIG_FILE not found!"
        exit 1
    fi

    echo "Importing Manico settings..."
    while IFS="|" read -r KEY TYPE VAL; do
        if [ -n "$KEY" ]; then
            case $TYPE in
                boolean)
                    defaults write "$DOMAIN" "$KEY" -bool "$VAL"
                    ;;
                integer)
                    defaults write "$DOMAIN" "$KEY" -int "$VAL"
                    ;;
                float|real)
                    defaults write "$DOMAIN" "$KEY" -float "$VAL"
                    ;;
                *)
                    defaults write "$DOMAIN" "$KEY" "$VAL"
                    ;;
            esac
        fi
    done < "$CONFIG_FILE"
    
    echo "Restarting Manico to apply changes..."
    killall Manico 2>/dev/null
    open -a Manico
    echo "Done!"
}

case "$1" in
    export)
        export_settings
        ;;
    import)
        import_settings
        ;;
    *)
        echo "Usage: $0 {export|import}"
        exit 1
        ;;
esac
