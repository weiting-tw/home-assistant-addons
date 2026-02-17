#!/bin/bash

# Claude Session Picker - Mobile-friendly with simple key controls
# Works inside tmux for session persistence

show_banner() {
    clear
    echo ""
    echo "  ╔═══════════════════════════════════════╗"
    echo "  ║        🤖 Claude Terminal             ║"
    echo "  ╚═══════════════════════════════════════╝"
    echo ""
}

show_menu() {
    echo "  [r] ⏩ Resume last conversation"
    echo "  [n] 🆕 New session"
    echo "  [l] 📋 List & pick conversation"
    echo "  [s] 🐚 Shell"
    echo "  [q] ❌ Quit"
    echo ""
}

launch_claude_new() {
    echo "  🚀 Starting new Claude session..."
    sleep 0.5
    claude
    # When claude exits, show menu again
    main
}

launch_claude_continue() {
    echo "  ⏩ Resuming last conversation..."
    sleep 0.5
    claude -c
    main
}

launch_claude_resume_list() {
    echo "  📋 Opening conversation list..."
    sleep 0.5
    claude -r
    main
}

launch_bash_shell() {
    echo "  🐚 Shell mode. Type 'exit' to return to menu."
    bash
    main
}

# Main execution flow
main() {
    while true; do
        show_banner
        show_menu
        printf "  > " >&2
        # Read single character (no Enter needed)
        read -rsn1 choice
        echo "$choice"
        echo ""
        
        case "$choice" in
            r|R|2)
                launch_claude_continue
                ;;
            n|N|1)
                launch_claude_new
                ;;
            l|L|3)
                launch_claude_resume_list
                ;;
            s|S|6)
                launch_bash_shell
                ;;
            q|Q|7)
                echo "  👋 Goodbye!"
                exit 0
                ;;
            "")
                # Enter key = resume (most common action)
                launch_claude_continue
                ;;
            *)
                echo "  ❌ Invalid: '$choice' — use r/n/l/s/q"
                sleep 1
                ;;
        esac
    done
}

main "$@"
