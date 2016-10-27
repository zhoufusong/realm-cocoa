//
//  SyncPermission.swift
//  Realm
//
//  Created by kishikawakatsumi on 10/27/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

#if swift(>=3.0)

/**
 * This is the base class managing the meta info. The inheritance from the other
 * classes is assumed to be flattened out in the schema.
 */
public class PermissionBaseObject: Object {
    public dynamic var id = UUID().uuidString
    public dynamic var createdAt = Date()
    public dynamic var updatedAt = Date()

    public let statusCode = RealmOptional<Int>()
    public dynamic var statusMessage: String?

    public var status: SyncManagementObjectStatus {
        guard let statusCode = statusCode.value else {
            return .notProcessed
        }
        if statusCode == 0 {
            return .success
        }
        return .error
    }

    override public class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
}

public final class PermissionChange: PermissionBaseObject {
    public dynamic var realmUrl = "*"
    public dynamic var userId = "*"

    public let mayRead = RealmOptional<Bool>()
    public let mayWrite = RealmOptional<Bool>()
    public let mayManage = RealmOptional<Bool>()

    public convenience init(forRealm realm: Realm, forUser user: SyncUser?, read mayRead: Bool?, write mayWrite: Bool?, manage mayManage: Bool?) {
        self.init()

        if let realmUrl = realm.configuration.syncConfiguration?.realmURL.absoluteString {
            self.realmUrl = realmUrl
        }

        if let userId = user?.identity {
            self.userId = userId
        }

        self.mayRead.value = mayRead;
        self.mayWrite.value = mayWrite;
        self.mayManage.value = mayManage;
    }
}

public final class PermissionOffer: PermissionBaseObject {
    public dynamic var token = ""
    public dynamic var realmUrl = ""

    public dynamic var mayRead = true
    public dynamic var mayWrite = false
    public dynamic var mayManage = false

    public dynamic var expiresAt: Date? = nil

    public convenience init(forRealm realm: Realm, expiresAt: Date?, read mayRead: Bool, write mayWrite: Bool, manage mayManage: Bool) {
        self.init()

        if let realmURL = realm.configuration.syncConfiguration?.realmURL {
            realmUrl = realmURL.absoluteString
        }

        self.mayRead = mayRead;
        self.mayWrite = mayWrite;
        self.mayManage = mayManage;

        self.expiresAt = expiresAt;
    }

    override public class func indexedProperties() -> [String] {
        return ["token"]
    }
}

public final class PermissionRequest: PermissionBaseObject {
    public dynamic var token: String?

    public convenience init(token: String) {
        self.init()
        self.token = token
    }

    override public class func primaryKey() -> String? {
        return "token"
    }
}

#else

/**
 * This is the base class managing the meta info. The inheritance from the other
 * classes is assumed to be flattened out in the schema.
 */
public class PermissionBaseObject: Object {
    public dynamic var id = NSUUID().UUIDString
    public dynamic var createdAt = NSDate()
    public dynamic var updatedAt = NSDate()

    public let statusCode = RealmOptional<Int>()
    public dynamic var statusMessage: String?

    public var status: SyncManagementObjectStatus {
        guard let statusCode = statusCode.value else {
            return .NotProcessed
        }
        if statusCode == 0 {
            return .Success
        }
        return .Error
    }

    override public class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }
}

public final class PermissionChange: PermissionBaseObject {
    public dynamic var realmUrl = "*"
    public dynamic var userId = "*"

    public let mayRead = RealmOptional<Bool>()
    public let mayWrite = RealmOptional<Bool>()
    public let mayManage = RealmOptional<Bool>()

    public convenience init(forRealm realm: Realm, forUser user: SyncUser?, read mayRead: Bool?, write mayWrite: Bool?, manage mayManage: Bool?) {
        self.init()

        if let realmUrl = realm.configuration.syncConfiguration?.realmURL.absoluteString {
            self.realmUrl = realmUrl
        }

        if let userId = user?.identity {
            self.userId = userId
        }

        self.mayRead.value = mayRead;
        self.mayWrite.value = mayWrite;
        self.mayManage.value = mayManage;
    }
}

public final class PermissionOffer: PermissionBaseObject {
    public dynamic var token = ""
    public dynamic var realmUrl = ""

    public dynamic var mayRead = true
    public dynamic var mayWrite = false
    public dynamic var mayManage = false

    public dynamic var expiresAt: NSDate? = nil

    public convenience init(forRealm realm: Realm, expiresAt: NSDate?, read mayRead: Bool, write mayWrite: Bool, manage mayManage: Bool) {
        self.init()

        if let realmURL = realm.configuration.syncConfiguration?.realmURL.absoluteString {
            realmUrl = realmURL
        }

        self.mayRead = mayRead;
        self.mayWrite = mayWrite;
        self.mayManage = mayManage;

        self.expiresAt = expiresAt;
    }

    override public class func indexedProperties() -> [String] {
        return ["token"]
    }
}

public final class PermissionRequest: PermissionBaseObject {
    public dynamic var token: String?

    public convenience init(token: String) {
        self.init()
        self.token = token
    }
    
    override public class func primaryKey() -> String? {
        return "token"
    }
}

#endif
