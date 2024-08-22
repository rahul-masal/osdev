#!/bin/bash

# Variables
USER="mgctuser"
USER_HOME="/home/$USER"
LOG_FILE="/var/log/setup_script.log"

websites=(
    "YouTube:https://www.youtube.com"
    "LinkedIn:https://www.linkedin.com"
    "Twitter:https://www.twitter.com"
    "Duolingo:https://www.duolingo.com"
    "NASA Kids Club:https://www.nasa.gov/kidsclub"
    "WhatsApp Web:https://web.whatsapp.com"
    "Discord:https://discord.com"
    "The Kid Should See This:https://thekidshouldseethis.com"
    "TED-Ed:https://ed.ted.com"
    "Swayam Central:https://swayam.gov.in"
    "National Digital Library:https://ndl.iitkgp.ac.in"
    "Code.org:https://code.org"
    "Udemy:https://www.udemy.com"
    "Khan Academy:https://www.khanacademy.org"
    "Cool Math Games:https://www.coolmathgames.com"
    "Crash Course:https://thecrashcourse.com"
)

# Function to handle errors and log them
error_exit() {
    echo "$1" | tee -a $LOG_FILE
    exit 1
}

# Update package lists and install necessary packages
echo "Updating package lists and installing required packages..."
sudo apt-get update -y && sudo apt-get install -y wget openssh-server xrdp gnome-tweaks || error_exit "Failed to install packages."

# Create the user if it does not exist
if id "$USER" &>/dev/null; then
    echo "User $USER already exists."
else
    echo "Creating user $USER..."
    sudo useradd -m -s /bin/bash $USER || error_exit "Failed to create user $USER."
    echo "$USER ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers
fi

# Ensure the home directory has standard folders
echo "Creating standard directories for $USER..."
sudo -u $USER mkdir -p $USER_HOME/{Desktop,Documents,Downloads,Pictures,Videos,Music,Public,Templates} || error_exit "Failed to create standard directories for $USER."

# Install Google Chrome
echo "Installing Google Chrome..."
wget -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb || error_exit "Failed to download Google Chrome."
sudo apt-get install -y /tmp/google-chrome.deb || error_exit "Failed to install Google Chrome."
sudo rm /tmp/google-chrome.deb

# Set up Chrome as the default browser
echo "Setting Google Chrome as the default browser for $USER..."
sudo -u $USER xdg-settings set default-web-browser google-chrome.desktop || error_exit "Failed to set Google Chrome as default browser."

# Create website application shortcuts
echo "Creating website application shortcuts..."
for entry in "${websites[@]}"; do
    IFS=":" read -r SHORTCUT_NAME WEBSITE <<< "$entry"
    sudo -u $USER tee $USER_HOME/Desktop/${SHORTCUT_NAME}.desktop > /dev/null <<EOL
[Desktop Entry]
Name=$SHORTCUT_NAME
Exec=google-chrome --new-window $WEBSITE
Icon=google-chrome
Terminal=false
Type=Application
EOL
    sudo chmod +x $USER_HOME/Desktop/${SHORTCUT_NAME}.desktop
done

# Set correct permissions for the user home directory
echo "Setting permissions for $USER_HOME..."
sudo chown -R $USER:$USER $USER_HOME || error_exit "Failed to set ownership of $USER_HOME"

# Enable required services
echo "Enabling openssh-server and xrdp services..."
sudo systemctl enable ssh || error_exit "Failed to enable SSH service."
sudo systemctl enable xrdp || error_exit "Failed to enable xrdp service."

# Final confirmation message
echo "Setup complete! Please check $LOG_FILE for details."
