import os
import shutil

def organize_folders():
    # Prompt for the directory to organize
    target_directory = input("Enter the path of the directory to organize (leave blank for current directory): ").strip()

    if not target_directory:
        target_directory = os.getcwd()

    if not os.path.exists(target_directory):
        print(f"The specified directory does not exist: {target_directory}")
        return

    # Prompt for the folder name to be created
    new_folder_name = input("Enter the name of the folder to be created: ").strip()

    # Prompt for the starting letter to filter folders
    starting_letter = input("Enter the starting letter for folders to move: ").strip().lower()
    
    if not starting_letter or len(starting_letter) != 1 or not starting_letter.isalpha():
        print("Invalid starting letter. Please enter a single alphabet character.")
        return

    # Create the new folder if it doesn't already exist
    new_folder_path = os.path.join(target_directory, new_folder_name)
    if not os.path.exists(new_folder_path):
        os.makedirs(new_folder_path)
        print(f"Folder '{new_folder_name}' created successfully.")
    else:
        print(f"Folder '{new_folder_name}' already exists.")

    # Loop through items in the target directory
    for item in os.listdir(target_directory):
        item_path = os.path.join(target_directory, item)
        
        # Check if the item is a folder and starts with the specified letter
        if os.path.isdir(item_path) and item.lower().startswith(starting_letter):
            # Move the folder into the newly created directory
            shutil.move(item_path, new_folder_path)
            print(f"Moved folder: {item} -> {new_folder_name}")

    print("Operation completed.")

if __name__ == "__main__":
    organize_folders()
