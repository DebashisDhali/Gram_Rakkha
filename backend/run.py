import subprocess
import os

def run_command(command):
    print(f"Executing: {' '.join(command)}")
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode == 0:
        print(f"Success: {result.stdout}")
    else:
        print(f"Error: {result.stderr}")
    return result.returncode == 0

def setup_backend():
    print("Starting GramRaksha Backend Setup...")
    
    # Check if we are in the right directory
    if not os.path.exists('requirements.txt'):
        print("Error: requirements.txt not found. Run this from within the 'backend' folder.")
        return

    # 1. Upgrade pip first
    print("\n1/4. Upgrading pip...")
    run_command(['python', '-m', 'pip', 'install', '--upgrade', 'pip'])
    
    # 2. Install dependencies
    print("\n2/4. Installing dependencies...")
    if not run_command(['pip', 'install', '-r', 'requirements.txt']):
        return
    
    # 3. Database Initialization
    print("\n3/4. Initializing Database Schema (Local SQLite)...")
    if not run_command(['python', 'init_db.py']):
        return
    
    # 4. Start App
    print("\n4/4. Setup Complete. Starting Backend...")
    print("--------------------------------------------------")
    print("NOTE: Using LOCAL SQLITE for prototyping.")
    print("To use Postgres, update app/core/config.py")
    print("--------------------------------------------------")
    
    subprocess.run(['uvicorn', 'app.main:app', '--host', '0.0.0.0', '--port', '8000', '--reload'])

if __name__ == "__main__":
    setup_backend()
