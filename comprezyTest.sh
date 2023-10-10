#!/bin/bash

# FILE: Comprezy
# USAGE: ./comprezy.sh
#
# DESC: Comprezy is just a simple terminal based tool to help with the use of compression tools like gz and xz along with
# gnupg encryption
#
# CREATED: by Azzy on 10/4/2023
# VERSION: 1.7.0

#Function to check if a package is installed and install it if not
checkPackage() {

	local packageName="$1"

	if ! command -v "$packageName" &>/dev/null; then
 
		echo "$packageName is not installed. Attempting to install..."

		#Check the package manager and install accordingly
		if command -v dnf &>/dev/null; then
  
			sudo dnf install -y "$packageName"

		elif command -v yum &>/dev/null; then
  
			sudo yum install -y "$packageName"

		elif command -v apt-get &>/dev/null; then
  
			sudo apt-get install -y "$packageName"

		else
			echo "Unsupported package manager. Please install $packageName manually."
            exit 1
        fi
    fi
}

# Function to update xz and gzip packages
updatePackages() {

    checkPackage "xz"
    checkPackage "gzip"
    echo "xz and gzip packages are up to date."
    read -p "Press Enter to continue..."

}

#Function to compress files/directories using tar and gzip
compressWith_gz() {

    checkPackage "tar"
    checkPackage "gzip"

    echo "Note: Enter the full file name including extension or full directory path unless the file/folder is in the current working directory."
    echo ""
    read -p "Enter the path to the file/directory: " sourcePath

    echo "Note: The compression will auto append .tar.gz to the output."
    echo ""
    read -p "Enter the desired name for the compressed file: " compressedName

    # Add .tar.gz extension to the user's input
    compressedName="${compressedName}.tar.gz"

    # Create the compressed file
    tar -czvf "$compressedName" "$sourcePath"

    read -p "Do you want to delete the original files (y/n)? " deleteOriginal

    if [ "$deleteOriginal" == "y" ]; then

		rm -r "$sourcePath"

    fi
}

# Function to compress files/directories using tar and xz
compressWith_xz() {

    checkPackage "tar"
    checkPackage "xz"

    echo "Note: Enter the full file name including extension or full directory path unless the file/folder is in the current working directory."
    echo ""
    read -p "Enter the path to the file/directory: " sourcePath

    echo "Note: The compression will auto append .tar.xz to the output."
	echo ""
    read -p "Enter the desired name for the compressed file: " compressedName

    # Add .tar.xz extension to the user's input
    compressedName="${compressedName}.tar.xz"

    # Create the compressed file
    tar -cvf - "$sourcePath" | xz -zv > "$compressedName"

    read -p "Do you want to delete the original files (y/n)? " deleteOriginal

    if [ "$deleteOriginal" == "y" ]; then

        rm -r "$sourcePath"

    fi
}

# Function to uncompress and unarchive files
uncompress() {

    read -p "Enter the compressed filename (with .tar.gz or .tar.xz extension): " compressedFile
    checkPackage "gzip"
    checkPackage "xz"

    if [[ "$compressedFile" == *.tar.gz ]]; then

        tar -xzvf "$compressedFile"

        read -p "Do you want to delete the original archive (y/n)? " deleteOriginal

            if [ "$deleteOriginal" == "y" ]; then

                rm -r "$compressedFile"

            fi

    elif [[ "$compressedFile" == *.tar.xz ]]; then

        tar -xJvf "$compressedFile"

        read -p "Do you want to delete the original archive (y/n)? " option

            if [ "$option" == "y" ]; then

                rm -r "$compressedFile"

            fi

    else

        echo "Unsupported compression format. Please use .tar.gz or .tar.xz files."

    fi

}

# Function to encrypt a file
encryptFile() {

    checkPackage "gpg"

    read -p "Enter the filename to encrypt: " fileToEncrypt

    gpg --symmetric --cipher-algo AES256 --armor -o "$fileToEncrypt".gpg "$fileToEncrypt"

    echo "File encrypted successfully."

    read -p "Do you want to delete the original archive (y/n)? " option

    if [ "$option" == "y" ]; then

        rm -r "$fileToEncrypt"

    fi

}

# Function to decrypt an encrypted file
decryptFile() {

    checkPackage "gpg"
    read -p "Enter the encrypted filename: " encryptedFile
    echo

    decryptedFile="${encryptedFile%????}"

    gpg -d -o "$decryptedFile" "$encryptedFile"

    echo "File decrypted successfully."

    read -p "Do you want to delete the original encrypted file? (y/n)? " option

    if [ "$option" == "y" ]; then

        rm -r "$encryptedFile"

    fi

}

# Function to create a tar archive
archiveWith_tar() {

    checkPackage "tar"

    read -p "Enter the path to the file/directory: " sourcePath
    read -p "Enter the desired name for the archive: " archiveName

    # Add .tar extension to the user's input
    archiveName="${archiveName}.tar"

    # Create the tar archive
    tar -cvf "$archiveName" "$sourcePath"

    read -p "Do you want to delete the original files (y/n)? " deleteOriginal

    if [ "$deleteOriginal" == "y" ]; then

        rm -r "$sourcePath"

    fi
}

# Function to list files in a directory
listFiles() {

    read -p "Enter the directory path (Enter for current directory): " dir
	
    if [ -z "$dir" ]; then
    
        dir="./"  # Use current working directory if no path is provided
	
    fi
	
    ls -l "$dir"
}

# Function to set up an automatic backup
setupAutoBackup() {
    read -p "Enter the source file/directory for backup: " sourcePath
    read -p "Enter the destination directory for backup: " destPath

    if [ ! -d "$destPath" ]; then
        echo "Destination directory does not exist. Creating it..."
        mkdir -p "$destPath"
    fi

    read -p "Enter the day and time for the backup (e.g., '0 3 * * *' for daily at 3 AM): " cronSchedule

    # Validate the cron schedule
    if ! cronjob_validate "$cronSchedule"; then
    
        echo "Invalid cron schedule. Please enter a valid cron schedule."
        return
	
    fi

    echo "Backup scheduled successfully with cron: $cronSchedule"

    # Ask compression and encryption options
    read -p "Do you want to compress the backup (xz/gz/none)? " compressionOption
    read -p "Do you want to encrypt the backup (yes/no)? " encryptionOption

    # Save the backup configuration to a file
    echo "sourcePath=\"$sourcePath\"" > backup_config.conf
    echo "destPath=\"$destPath\"" >> backup_config.conf
    echo "cronSchedule=\"$cronSchedule\"" >> backup_config.conf
    echo "compressionOption=\"$compressionOption\"" >> backup_config.conf
    echo "encryptionOption=\"$encryptionOption\"" >> backup_config.conf

    # Add the backup job to cron
    (crontab -l ; echo "$cronSchedule /path/to/your/backup_script.sh") | crontab -

    echo "Automatic backup scheduled successfully."
}

# Function to validate a cron schedule
cronjob_validate() {
    local cron="$1"
    
    if [[ ! "$cron" =~ ^(\*|[0-9\-,]+(\*?\/[0-9\-,]+)?\s+){4}\*$ ]]; then
    
        return 1
	
    fi
    
    return 0
    
}

# Function to perform the backup
performAutoBackup() {
    # Load backup configuration from file
    source backup_config.conf

    # Create the destination directory if it doesn't exist
    if [ ! -d "$destPath" ]; then
    
        mkdir -p "$destPath"
	
    fi

    # Copy or move the source to the destination
    cp -r "$sourcePath" "$destPath"  # Change to "mv" if you want to move instead of copy

    echo "Backup completed successfully."

    # Check for compression and encryption options
    if [ "$compressionOption" == "xz" ]; then
    
        tar -cJf "$destPath/backup.tar.xz" -C "$destPath" .
	
    elif [ "$compressionOption" == "gz" ]; then
    
        tar -czf "$destPath/backup.tar.gz" -C "$destPath" .
	
    fi

    if [ "$encryptionOption" == "yes" ]; then
    
        read -p "Enter a passphrase for encryption: " passphrase
        echo "$passphrase" | gpg --symmetric --cipher-algo AES256 --armor -o "$destPath/backup.gpg"
	
    fi

    echo "Backup completed with compression and encryption."
}

# Function to set the default directory in Settings for compressed files
setDefaultDirectory() {

	read -p "Enter the default directory path: " default_dir
	echo "DEFAULT_DIR=\"$default_dir\"" > settings.conf
	echo "Default directory is set to: $default_dir"
	read -p "Press Enter to continue..."

}

# Load Settings in from settings.conf if it exists
if [ -e settings.conf  ]; then

	source settings.conf

else

	DEFAULT_DIR=""

fi

# Main menu
while true; do

    clear
    echo "-=-=-=- Comprezy: Azzy's Archive Tool -=-=-=-"
    echo " "
    echo "1. Compress using gz"
    echo "2. Compress using xz"
    echo "3. Uncompress file"
    echo "4. Encrypt file"
    echo "5. Decrypt file"
    echo "6. Archive with Tar"
    echo "7. List Files"
    echo "8. Set up Auto Backup"
    echo "9. Settings"
    echo "10. Exit"
    echo " "

    read -p "Choose an Option: " choice

    case $choice in

        1) compressWith_gz ;;
        2) compressWith_xz ;;
	3) uncompress ;;
        4) encryptFile ;;
        5) decryptFile ;;
        6) archiveWith_tar ;;
	7) listFiles ;;
 	8) setupAutoBackup ;;
        9)

		clear
            	echo "-=-=-=- Settings -=-=-=-"
		echo " "
            	echo "1. Set Default Directory"
            	echo "2. Update Packages"
            	echo "3. Back"
		echo " "
            	read -p "Choose an Option: " settings_choice
            	case $settings_choice in
                	1) setDefaultDirectory ;;
                	2) updatePackages ;;
                	3) ;;
                	*) echo "Invalid choice. Please select a valid option." ;;
            	esac ;;
        10) exit 0 ;;
        *) echo "Invalid choice. Please select a valid option." ;;

    esac

    done
