import os
import subprocess
import sys
import shutil

def build_codegen_if_needed(build_dir, source_dir):
    executable = os.path.join(build_dir, "Codegen.exe")
    release_executable = os.path.join(build_dir, "Release", "Codegen.exe")

    if os.path.isfile(executable):
        print("Found existing Codegen executable. Skipping build.")
        return executable
    elif os.path.isfile(release_executable):
        print("Found existing Codegen Release executable. Skipping build.")
        return release_executable

    print("Codegen executable not found, starting build process...")

    os.makedirs(build_dir, exist_ok=True)

    cmake_configure_cmd = [
        "cmake",
        "-S", source_dir,
        "-B", build_dir,
    ]

    print("Configuring CMake...")
    result = subprocess.run(cmake_configure_cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print("CMake configuration failed:")
        print(result.stdout)
        print(result.stderr)
        sys.exit(1)

    cmake_build_cmd = [
        "cmake",
        "--build", build_dir,
        "--config", "Release"
    ]

    print("Building project...")
    result = subprocess.run(cmake_build_cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print("Build failed:")
        print(result.stdout)
        print(result.stderr)
        sys.exit(1)

    if os.path.isfile(executable):
        return executable
    elif os.path.isfile(release_executable):
        return release_executable
    else:
        print(f"Executable not found in expected locations after build:")
        print(f"  {executable}")
        print(f"  {release_executable}")
        sys.exit(1)

def run_codegen_on_folders(exe_path):
    bindings_dir = os.path.abspath("./bindings/bindings")
    output_base_dir = os.path.abspath("../src/data/versions")

    print(f"Bindings directory: {bindings_dir}")
    print(f"Output base directory: {output_base_dir}")

    # Ensure output base directory exists before processing
    os.makedirs(output_base_dir, exist_ok=True)

    if not os.path.isdir(bindings_dir):
        print(f"Bindings directory not found: {bindings_dir}")
        sys.exit(1)

    successful_folders = []

    for folder_name in sorted(os.listdir(bindings_dir)):
        folder_path = os.path.join(bindings_dir, folder_name)

        if not os.path.isdir(folder_path):
            print(f"Skipping {folder_name}: Not a directory")
            continue

        if folder_name.lower() == "include":
            print(f"Skipping folder: {folder_name}")
            continue

        entry_bro_path = os.path.join(folder_path, "Entry.bro")
        if not os.path.isfile(entry_bro_path):
            print(f"Warning: Entry.bro not found in {folder_name}, skipping.")
            continue

        print(f"Running executable on folder: {folder_name}")

        args = [
            exe_path,
            "Win64",
            folder_path,
            "./"
        ]

        print("Executing command:")
        print(" ".join(args))

        result = subprocess.run(args, text=True)
        if result.returncode != 0:
            print(f"Codegen error in folder {folder_name} with return code {result.returncode}")
        else:
            print(f"Completed folder: {folder_name}")
            successful_folders.append(folder_name)

    # After processing all folders, copy CodegenData.json for each successful folder
    for version in successful_folders:
        src_file = os.path.join(bindings_dir, version, "Geode", "CodegenData.json")
        dest_dir = os.path.join(output_base_dir, version)
        dest_file = os.path.join(dest_dir, "codegen.json")

        if not os.path.isfile(src_file):
            print(f"Warning: CodegenData.json not found for {version} at expected path: {src_file}")
            continue

        os.makedirs(dest_dir, exist_ok=True)
        try:
            shutil.copy2(src_file, dest_file)
            print(f"Copied CodegenData.json for {version} to {dest_file}")
        except Exception as e:
            print(f"Failed to copy CodegenData.json for {version}: {e}")

def main():
    source_dir = os.path.abspath("./bindings/codegen")
    build_dir = os.path.abspath("./bindings/codegen/build")

    exe_path = build_codegen_if_needed(build_dir, source_dir)
    run_codegen_on_folders(exe_path)

if __name__ == "__main__":
    main()
