#!/bin/sh

# todo: undo in case of failure?

BACKUP_LOCATION="~/.backups"
SCRIPT_LOCATION="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# all paths must be within the user's home folder!
backupOne() {
  original_file="${1/#\~/$HOME}"
  parent_dir=$( dirname "$original_file" )
  parent_dir="${parent_dir/#\~/$HOME}"

  if [ "$parent_dir" = "$(readlink -f ~)" ]; then
    path_within_user=""
  else
    path_within_user=${parent_dir#~/}
  fi

  backup_path="$BACKUP_LOCATION"/"$path_within_user"
  backup_path="${backup_path/#\~/$HOME}"

  mkdir -p "$backup_path"
  mv "$original_file" "$backup_path"
}

backup() {
  for var in "$@"
  do
    backupOne "$var"
  done
}

link() {
  for var in "$@"
  do
    source_path="${var/#\~\/}"
    destination_path="${var/#\~/$HOME}"
    ln -s "$SCRIPT_LOCATION"/"$source_path" "$destination_path"
  done
}

fileList=$(echo "~/.config/onedrive/config" "~/.vimrc" "~/.config/nvim" "~/.zshrc" "~/.p10k.zsh" "~/.p10k-nix-shell.zsh" "~/.oh-my-zsh/oh-my-zsh.sh")

backup $fileList
link $fileList

echo "Installed successfully!"
