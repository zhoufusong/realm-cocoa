////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Foundation
import Realm
import Realm.Private

public struct RealmConfiguration {
    static var defaultConfiguration: RealmConfiguration = RealmConfiguration()

    var path: String? = RLMConfiguration.defaultRealmPath()
    var inMemoryIdentifier: String? = nil
    var encryptionKey: NSData? = nil
    var readOnly = false
    var fileProtection: String? = nil
    var schemaVersion = 0
    var migrationBlock: MigrationBlock? = nil
    var deleteIfMigrationNeeded = false

    internal var rlmConfiguration: RLMConfiguration {
        return RLMConfiguration() { configurator in
            configurator.path = self.path
            configurator.inMemoryIdentifier = self.inMemoryIdentifier
            configurator.encryptionKey = self.encryptionKey
            configurator.readonly = self.readOnly
            configurator.fileProtectionAttributes = self.fileProtection
            configurator.schemaVersion = UInt(self.schemaVersion)
            configurator.migrationBlock = self.migrationBlock.map { accessorMigrationBlock($0) }
            configurator.deleteIfMigrationNeeded = self.deleteIfMigrationNeeded
        }
    }
}
