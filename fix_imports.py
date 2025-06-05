#!/usr/bin/env python3
"""
Networking 폴더의 불필요한 import를 제거하는 스크립트
"""

import os
import glob

def fix_networking_imports():
    """Networking 폴더의 파일들에서 불필요한 ACNHCore, ACNHShared import 제거"""
    networking_path = "Animal-Crossing-Wiki/Projects/App/Sources/Networking"
    swift_files = glob.glob(os.path.join(networking_path, "**/*.swift"), recursive=True)
    
    updated_files = []
    
    for file_path in swift_files:
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()
        
        original_content = content
        lines = content.split('\n')
        
        # ACNHCore, ACNHShared import 제거
        new_lines = []
        for line in lines:
            if line.strip() in ['import ACNHCore', 'import ACNHShared']:
                continue
            new_lines.append(line)
        
        new_content = '\n'.join(new_lines)
        
        # 변경사항이 있으면 파일 업데이트
        if new_content != original_content:
            with open(file_path, 'w', encoding='utf-8') as file:
                file.write(new_content)
            updated_files.append(file_path)
            print(f"Updated: {file_path}")
    
    print(f"\nProcessed {len(swift_files)} files, updated {len(updated_files)} files")
    return updated_files

if __name__ == "__main__":
    print("Fixing Networking imports...")
    fix_networking_imports()
    print("\nImports fixed successfully!")