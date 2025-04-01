import os
import shutil

def move_files_recursively(source_directory, target_directory):
    """
    Recursively moves all files from the source directory and its subdirectories
    to the target directory.
    
    Args:
        source_directory (str): Path to the source directory.
        target_directory (str): Path to the target directory where files will be moved.
    """
    if not os.path.exists(target_directory):
        os.makedirs(target_directory)
        print(f"Created target directory: {target_directory}")
    
    for root, _, files in os.walk(source_directory):
        for file in files:
            source_path = os.path.join(root, file)
            target_path = os.path.join(target_directory, file)
            
            # Ensure unique file names in the target directory
            counter = 1
            while os.path.exists(target_path):
                name, ext = os.path.splitext(file)
                target_path = os.path.join(target_directory, f"{name}_{counter}{ext}")
                counter += 1
            
            try:
                shutil.move(source_path, target_path)
                print(f"Moved: {source_path} -> {target_path}")
            except Exception as e:
                print(f"Failed to move {source_path}: {e}")

if __name__ == "__main__":
    # Replace these paths with your source and target directories
    source_directory = "your/source/directory"
    target_directory = "your/target/directory"
    
    if os.path.isdir(source_directory):
        move_files_recursively(source_directory, target_directory)
    else:
        print(f"The source directory {source_directory} does not exist.")
