# btrsnappr
**btrsnapper** can be used to automate btrfs snapshots of your system. Compared to other solutions this one also takes care about your /boot and /home directories if they are located on a separate btrfs volume or separate btrfs subvolume.

## Installation instructions
Simply clone the repository to your favourite script path e.g. _/opt_. Open and edit the script lines at the top of the btrsnap file to fit your needs. Especially the path and partition labels.

# Planned features
* use getopts to set options
* suppress all output
 * set debug levels (info, warning, error)
* option to include hostname in snapshot name (to be able to btrfs send and receive snapshots for backup of multiple systems)
* make it more awesome!



