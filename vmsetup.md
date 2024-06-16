sudo apt update
sudo apt upgrade
sudo apt install vim
sudo apt install qemu-guest-agent
sudo apt install net-tools
# enable root login and tcp forwarding
sudo vi /etc/ssh/sshd_config

# enable and set root pass
sudo passwd root
reboot

