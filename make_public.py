#!/usr/bin/env python3
"""
모듈의 Swift 파일들에 public 접근 제어자를 추가하는 스크립트
"""

import os
import re
import glob

def update_swift_file_for_public_access(file_path):
    """Swift 파일에 public 접근 제어자를 추가"""
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()
    
    original_content = content
    
    # struct, class, enum, protocol에 public 추가 (이미 public이 아닌 경우만)
    patterns = [
        (r'^(\s*)(struct\s+)', r'\1public \2'),
        (r'^(\s*)(class\s+)', r'\1public \2'),
        (r'^(\s*)(enum\s+)', r'\1public \2'),
        (r'^(\s*)(protocol\s+)', r'\1public \2'),
        (r'^(\s*)(extension\s+)', r'\1public \2'),
        (r'^(\s*)(func\s+)', r'\1public \2'),
        (r'^(\s*)(var\s+)', r'\1public \2'),
        (r'^(\s*)(let\s+)', r'\1public \2'),
        (r'^(\s*)(init\()', r'\1public \2'),
    ]
    
    lines = content.split('\n')
    updated_lines = []
    
    for line in lines:
        updated_line = line
        
        # 이미 public이거나 private/internal이 있으면 건너뛰기
        if 'public ' in line or 'private ' in line or 'internal ' in line or 'fileprivate ' in line:
            updated_lines.append(updated_line)
            continue
            
        # 주석이나 import 문은 건너뛰기
        if line.strip().startswith('//') or line.strip().startswith('import') or line.strip().startswith('*'):
            updated_lines.append(updated_line)
            continue
            
        # 빈 줄이나 닫는 괄호는 건너뛰기
        if not line.strip() or line.strip() in ['{', '}', ')', '})', '})', '])']:
            updated_lines.append(updated_line)
            continue
        
        # 각 패턴 적용
        for pattern, replacement in patterns:
            if re.match(pattern, line):
                updated_line = re.sub(pattern, replacement, line)
                break
                
        updated_lines.append(updated_line)
    
    updated_content = '\n'.join(updated_lines)
    
    # 변경사항이 있으면 파일 업데이트
    if updated_content != original_content:
        with open(file_path, 'w', encoding='utf-8') as file:
            file.write(updated_content)
        return True
    return False

def process_module(module_path):
    """모듈의 모든 Swift 파일 처리"""
    swift_files = glob.glob(os.path.join(module_path, "**/*.swift"), recursive=True)
    updated_files = []
    
    for file_path in swift_files:
        if update_swift_file_for_public_access(file_path):
            updated_files.append(file_path)
            print(f"Updated: {file_path}")
    
    print(f"\nProcessed {len(swift_files)} files, updated {len(updated_files)} files")
    return updated_files

def main():
    # ACNHCore 모듈 처리
    print("Processing ACNHCore module...")
    acnh_core_path = "Animal-Crossing-Wiki/Projects/ACNHCore/Sources"
    process_module(acnh_core_path)
    
    print("\n" + "="*50 + "\n")
    
    # ACNHShared 모듈 처리  
    print("Processing ACNHShared module...")
    acnh_shared_path = "Animal-Crossing-Wiki/Projects/ACNHShared/Sources"
    process_module(acnh_shared_path)
    
    print("\nPublic access modifiers added successfully!")

if __name__ == "__main__":
    main()