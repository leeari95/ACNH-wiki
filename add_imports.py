#!/usr/bin/env python3
"""
App 모듈의 Swift 파일들에 ACNHCore와 ACNHShared import를 추가하는 스크립트
"""

import os
import re
import glob

def add_imports_to_swift_file(file_path):
    """Swift 파일에 ACNHCore와 ACNHShared import 추가"""
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()
    
    original_content = content
    lines = content.split('\n')
    
    # 이미 import가 있는지 확인
    has_acnh_core = any('import ACNHCore' in line for line in lines)
    has_acnh_shared = any('import ACNHShared' in line for line in lines)
    
    # 필요한 import가 이미 모두 있으면 스킵
    if has_acnh_core and has_acnh_shared:
        return False
    
    # import 섹션 찾기
    import_end_index = 0
    for i, line in enumerate(lines):
        if line.strip().startswith('import '):
            import_end_index = i + 1
        elif line.strip() == '' and import_end_index > 0:
            break
    
    # import 추가
    new_imports = []
    if not has_acnh_core:
        new_imports.append('import ACNHCore')
    if not has_acnh_shared:
        new_imports.append('import ACNHShared')
    
    # 새로운 라인들 생성
    new_lines = lines[:import_end_index] + new_imports + lines[import_end_index:]
    new_content = '\n'.join(new_lines)
    
    # 변경사항이 있으면 파일 업데이트
    if new_content != original_content:
        with open(file_path, 'w', encoding='utf-8') as file:
            file.write(new_content)
        return True
    return False

def process_app_module():
    """App 모듈의 모든 Swift 파일에 import 추가"""
    app_path = "Animal-Crossing-Wiki/Projects/App/Sources"
    swift_files = glob.glob(os.path.join(app_path, "**/*.swift"), recursive=True)
    updated_files = []
    
    for file_path in swift_files:
        if add_imports_to_swift_file(file_path):
            updated_files.append(file_path)
            print(f"Updated: {file_path}")
    
    print(f"\nProcessed {len(swift_files)} files, updated {len(updated_files)} files")
    return updated_files

def main():
    print("Adding imports to App module...")
    process_app_module()
    print("\nImports added successfully!")

if __name__ == "__main__":
    main()