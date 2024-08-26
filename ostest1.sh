#!/bin/bash

# Update and install necessary packages
echo "Updating package lists and installing required packages..."
apt-get update && apt-get install -y wget gnome-tweaks xrdp openssh-server

# Create a new user
username="mgctuser"
password="MegaAstra@8431#"

echo "Creating user $username..."
useradd -m -s /bin/bash "$username"
echo "$username:$password" | chpasswd
usermod -aG sudo "$username"
echo "$username ALL=(ALL:ALL) ALL" | tee /etc/sudoers.d/$username

# Set up Google Chrome
echo "Installing Google Chrome..."
wget -q -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt-get install -y /tmp/google-chrome.deb
rm /tmp/google-chrome.deb

# Set Google Chrome as the default browser for the user
echo "Setting Google Chrome as the default browser for $username..."
sudo -u "$username" xdg-settings set default-web-browser google-chrome.desktop

# Array of websites for shortcuts
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

# Directory for shortcuts
desktop_dir="/home/$username/Desktop"
mkdir -p "$desktop_dir"
chown -R "$username:$username" "$desktop_dir"

# Create shortcuts
echo "Creating website application shortcuts..."
for site in "${websites[@]}"; do
    name=$(echo "$site" | cut -d':' -f1)
    url=$(echo "$site" | cut -d':' -f2)
    
    shortcut="[Desktop Entry]
Name=$name
Exec=google-chrome-stable $url
Terminal=false
Type=Application
Icon=google-chrome
Categories=Network;WebBrowser;"

    shortcut_file="$desktop_dir/$name.desktop"
    echo "$shortcut" | tee "$shortcut_file"
    chmod +x "$shortcut_file"
    chown "$username:$username" "$shortcut_file"
done

# Set permissions for the home directory
echo "Setting permissions for /home/$username..."
chown -R "$username:$username" "/home/$username"

# Enable services
echo "Enabling openssh-server and xrdp services..."
systemctl enable ssh
systemctl enable xrdp

echo "Setup complete! Please check /var/log/setup_script.log for details."
