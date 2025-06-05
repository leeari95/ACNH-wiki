#!/usr/bin/env python3
"""
Response DTO 파일들에만 ACNHCore import를 추가하는 스크립트
"""

import os
import glob

def add_acnh_core_to_response_files():
    """Response 폴더의 파일들에만 ACNHCore import 추가"""
    response_path = "Animal-Crossing-Wiki/Projects/App/Sources/Networking/Response"
    swift_files = glob.glob(os.path.join(response_path, "**/*.swift"), recursive=True)
    
    updated_files = []
    
    for file_path in swift_files:
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()
        
        original_content = content
        lines = content.split('\n')
        
        # 이미 ACNHCore import가 있는지 확인
        has_acnh_core = any('import ACNHCore' in line for line in lines)
        
        if has_acnh_core:
            continue
            
        # import 섹션 찾기
        import_end_index = 0
        for i, line in enumerate(lines):
            if line.strip().startswith('import '):
                import_end_index = i + 1
            elif line.strip() == '' and import_end_index > 0:
                break
        
        # ACNHCore import 추가
        new_lines = lines[:import_end_index] + ['import ACNHCore'] + lines[import_end_index:]
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
    print("Adding ACNHCore imports to Response files...")
    add_acnh_core_to_response_files()
    print("\nACNHCore imports added successfully!")