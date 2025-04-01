import os
import random

def generate_random_number():
    """Generate a random five-digit number as a string."""
    return f"{random.randint(10000, 99999)}"

def rename_files_recursively(directory):
    """
    Recursively renames all files in the given directory and its subdirectories.
    The new file names start with 'IMG' followed by a random five-digit number.
    
    Args:
        directory (str): Path to the top-level directory.
    """
    for root, _, files in os.walk(directory):
        for file in files:
            # Generate a new name for each file
            new_name = f"IMG{generate_random_number()}{os.path.splitext(file)[1]}"
            old_path = os.path.join(root, file)
            new_path = os.path.join(root, new_name)
            
            try:
                os.rename(old_path, new_path)
                print(f"Renamed: {old_path} -> {new_path}")
            except Exception as e:
                print(f"Failed to rename {old_path}: {e}")

if __name__ == "__main__":
    # Replace 'your_directory_path' with the path to the directory you want to rename files in
    directory_path = "your_directory_path"
    
    if os.path.isdir(directory_path):
        rename_files_recursively(directory_path)
    else:
        print(f"The directory {directory_path} does not exist.")
