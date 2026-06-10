//
//  CoreDataStorage+Recovery.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2026/06/11.
//

import Foundation
import CoreData
import os

// MARK: - Data Recovery

extension CoreDataStorage {

    /// 사용자가 설정에서 "iCloud에서 복원"을 명시적으로 눌렀을 때만 실행되는 복원 플로우.
    /// 로컬 store를 삭제하고 앱 재시작 시 CloudKit에서 전체 re-import 유도.
    /// 로컬 데이터가 iCloud 백업으로 완전히 대체되므로 파괴적 동작 — 2단 확인 alert 후에만 호출.
    enum RecoveryError: LocalizedError {
        case iCloudNotAvailable
        case storeNotFound

        var errorDescription: String? {
            switch self {
            case .iCloudNotAvailable: return "iCloud is not available"
            case .storeNotFound: return "CoreData store not found"
            }
        }
    }

    /// 로컬 store 파일을 삭제하고 앱 재시작 시 CloudKit에서 전체 re-import 유도.
    /// store를 런타임에 재등록하면 CloudKit 옵션이 누락되므로, 파일만 삭제하고 재시작을 안내한다.
    func performCloudKitRecovery(completion: @escaping (Result<Void, Error>) -> Void) {
        checkiCloudAccountStatus { [weak self] status in
            guard status == .available else {
                completion(.failure(RecoveryError.iCloudNotAvailable))
                return
            }
            guard let self else {
                return
            }

            guard let storeDescription = self.persistentContainer.persistentStoreDescriptions.first,
                  let storeURL = storeDescription.url else {
                completion(.failure(RecoveryError.storeNotFound))
                return
            }

            do {
                // 기존 store 분리
                let coordinator = self.persistentContainer.persistentStoreCoordinator
                if let store = coordinator.persistentStore(for: storeURL) {
                    try coordinator.remove(store)
                }

                // Store 파일 삭제 — fileExists 대신 직접 시도 + 부재 에러 무시 (TOCTOU 방지)
                let fileManager = FileManager.default
                let storePath = storeURL.path
                for suffix in ["", "-shm", "-wal"] {
                    do {
                        try fileManager.removeItem(atPath: storePath + suffix)
                    } catch let error as NSError where error.code == NSFileNoSuchFileError {
                        // 파일이 이미 없음 — 정상
                    }
                }

                // ckAssets 폴더 삭제
                let ckAssetsURL = storeURL.deletingLastPathComponent()
                    .appendingPathComponent("ckAssets")
                do {
                    try fileManager.removeItem(at: ckAssetsURL)
                } catch let error as NSError where error.code == NSFileNoSuchFileError {
                    // 폴더가 이미 없음 — 정상
                }

                // migration flag 유지 — 재시작 시 re-export 중복 방지
                UserDefaults.standard.set(true, forKey: "didMigrateExistingDataToCloudKit_v2")

                // 기존 유저 플래그 유지 — 재시작 후 CloudKit re-import 전까지 빈 UC 생성 방지
                // (복구 = 기존 유저이므로 true 유지가 올바름)

                // Recovery grace period 시작 — 재시작 후 import 지연/실패 상태를 UI와 진단 로그에서
                // 구분하기 위한 표시용 플래그. 빈 UC 생성을 허용하지는 않는다.
                self.markRecoveryInitiated()

                Log.warning("recovery: local store wiped, awaiting restart + CloudKit re-import")
                Log.event(.recoveryTriggered)
                completion(.success(()))
            } catch {
                os_log(.error, log: .default, "🔄 Recovery failed: %{public}@", error.localizedDescription)
                completion(.failure(error))
            }
        }
    }
}
