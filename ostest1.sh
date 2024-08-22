#!/bin/bash

# Variables
USER="mgctuser"
PASSWORD="MegaAstra@8431#"
WALLPAPER_URL="https://raw.githubusercontent.com/rahul-masal/images/main/mgct.png"
BOOT_LOGO_URL="https://raw.githubusercontent.com/rahul-masal/images/main/bootlogo.png"
PROFILE_PIC_URL="https://raw.githubusercontent.com/rahul-masal/images/main/image.png"
IMAGE_DIR="/mnt/data"
USER_HOME="/home/$USER"
DESKTOP_DIR="$USER_HOME/Desktop"
AUTOSTART_DIR="$USER_HOME/.config/autostart"
WALLPAPER_PATH="$IMAGE_DIR/mgct.png"
PROFILE_PIC_PATH="$IMAGE_DIR/image.png"
BOOT_LOGO_PATH="$IMAGE_DIR/bootlogo.png"

# Error logging
LOG_FILE="/var/log/setup_script.log"
exec 2>>$LOG_FILE

# Function to handle errors
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Update and install packages
echo "Updating package lists and installing required packages..."
sudo apt-get update || error_exit "Failed to update package lists"
sudo apt-get install -y openssh-server xrdp gnome-tweaks || error_exit "Failed to install required packages"

# Enable services
echo "Enabling openssh-server and xrdp services..."
sudo systemctl enable ssh || error_exit "Failed to enable SSH service"
sudo systemctl enable xrdp || error_exit "Failed to enable XRDP service"

# Add user with sudo permissions
echo "Adding user $USER..."
sudo useradd -m -s /bin/bash $USER || error_exit "Failed to add user $USER"
echo "$USER:$PASSWORD" | sudo chpasswd || error_exit "Failed to set password for user $USER"
sudo usermod -aG sudo $USER || error_exit "Failed to add user $USER to sudo group"
echo "$USER ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers || error_exit "Failed to update sudoers file"

# Download images
echo "Downloading images..."
wget -O $WALLPAPER_PATH $WALLPAPER_URL || error_exit "Failed to download desktop wallpaper"
wget -O $PROFILE_PIC_PATH $PROFILE_PIC_URL || error_exit "Failed to download profile picture"
wget -O $BOOT_LOGO_PATH $BOOT_LOGO_URL || error_exit "Failed to download boot logo"

# Set desktop wallpaper
echo "Setting desktop wallpaper for $USER..."
sudo -u $USER gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_PATH" || error_exit "Failed to set desktop wallpaper"

# Set profile picture
echo "Setting profile picture for $USER..."
sudo cp $PROFILE_PIC_PATH /var/lib/AccountsService/icons/$USER || error_exit "Failed to copy profile picture"
echo "[User]" | sudo tee /var/lib/AccountsService/users/$USER > /dev/null
echo "Icon=/var/lib/AccountsService/icons/$USER" | sudo tee -a /var/lib/AccountsService/users/$USER > /dev/null || error_exit "Failed to set profile picture"

# Set boot logo (note: this may not be possible depending on the distro and bootloader)
echo "Setting boot logo..."
if [[ -d "/usr/share/plymouth/themes/default.grub" ]]; then
    sudo cp $BOOT_LOGO_PATH /usr/share/plymouth/themes/default.grub/splash.png || error_exit "Failed to set boot logo"
else
    echo "Boot logo setup is not supported on this system."
fi

# Creating Desktop shortcuts
echo "Creating website application shortcuts..."
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

for site in "${websites[@]}"; do
    name="${site%%:*}"
    url="${site##*:}"
    cat <<EOF > "$DESKTOP_DIR/$name.desktop"
[Desktop Entry]
Name=$name
Exec=xdg-open $url
Type=Application
Icon=google-chrome
EOF
    chmod +x "$DESKTOP_DIR/$name.desktop"
done

# Ensure shortcuts appear in RDP session
echo "Ensuring desktop shortcuts appear in RDP session..."
mkdir -p $AUTOSTART_DIR || error_exit "Failed to create autostart directory"
for shortcut in "$DESKTOP_DIR"/*.desktop; do
    cp "$shortcut" "$AUTOSTART_DIR/" || error_exit "Failed to copy shortcut to autostart"
done

# Set correct permissions for the user home directory
echo "Setting permissions for $USER_HOME..."
sudo chown -R $USER:$USER $USER_HOME || error_exit "Failed to set ownership of $USER_HOME"

echo "Setup complete! Please check $LOG_FILE for details."
