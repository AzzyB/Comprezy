#!/bin/bash

# FILE: Comprezy
# USAGE: ./comprezy.sh
# DESC: Comprezy is just a simple temrinal based tool to help with the use of compression tools like gz and xz
# CREATED: by Azzy on 10/4/2023
# VERSION: 1.4.1
# 

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

#Function to compress files/directories using tar and gzip
compressWith_gz() {

    checkPackage "tar"
    checkPackage "gzip"
    
    read -p "Enter the path to the file/directory: " sourcePath
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
    
    read -p "Enter the path to the file/directory: " sourcePath
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
    read -p "Enter the desired uncompressed filename: " uncompressedName
    
    if [[ "$compressedFile" == *.tar.gz ]]; then
        checkPackage "gzip"
        tar -xzvf "$compressedFile" -C "$(dirname "$uncompressedName")"
    elif [[ "$compressed_file" == *.tar.xz ]]; then
        checkPackage "xz"
        tar -xJvf "$compressedFile" -C "$(dirname "$uncompressedName")"
    else
        echo "Unsupported compression format. Please use .tar.gz or .tar.xz files."
    fi

}

# Function to encrypt a file
encryptFile() {

    checkPackage "gpg"

    read -p "Enter the filename to encrypt: " file_to_encrypt

    if [ "$passphrase" != "$confirm_passphrase" ]; then

        echo "Passphrases do not match. Encryption canceled."
        return

    fi

    gpg -c --passphrase "$passphrase" "$file_to_encrypt"
    echo "File encrypted successfully."

}

# Function to decrypt an encrypted file
decryptFile() {

    checkPackage "gpg"
    read -p "Enter the encrypted filename: " encrypted_file
    echo

    gpg --batch --yes --passphrase "$passphrase" -d "$encrypted_file" > decrypted_file
    echo "File decrypted successfully."

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

# Function to set the default directory in Settings for compressed files 
setDefaultDirectory() {

	read -p "Enter the default directory path: " default_dir
	echo "DEFAULT_DIR=\"$default_dir\"" > settings.conf
	echo "Default directory is set to: $default_dir"
	read -p "Press Enter to continue..."

}

# Function to update xz and gzip packages
updatePackages() {

	checkPackage "xz"
    checkPackage "gzip"
    echo "xz and gzip packages are up to date."
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
    echo "7. Settings"
    echo "8. Exit"
    echo " "
		
    read -p "Choose an Option: " choice
	
    case $choice in
	
        1) compressWith_gz ;;
        2) compressWith_xz ;;
	    3) uncompress ;;
        4) encryptFile ;;
        5) decryptFile ;;
        6) archiveWith_tar ;;
        7) 

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
        8) exit 0 ;;
        *) echo "Invalid choice. Please select a valid option." ;;
		
    esac
	
    read -p "Press Enter to continue..."
	
    done
