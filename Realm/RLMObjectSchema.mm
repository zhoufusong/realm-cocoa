////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

#import "RLMObjectSchema_Private.hpp"

#import "RLMArray.h"
#import "RLMListBase.h"
#import "RLMObject_Private.h"
#import "RLMProperty_Private.hpp"
#import "RLMRealm_Dynamic.h"
#import "RLMRealm_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMSwiftSupport.h"
#import "RLMUtil.hpp"

#import "object_store.hpp"

using namespace realm;

// private properties
@interface RLMObjectSchema ()
@property (nonatomic, readwrite) NSDictionary<id, RLMProperty *> *allPropertiesByName;
@property (nonatomic, readwrite) NSString *className;
@end

@implementation RLMObjectSchema {
    // table accessor optimization
    realm::TableRef _table;
    NSArray *_propertiesInDeclaredOrder;
    NSArray *_swiftGenericProperties;
}

- (instancetype)initWithClassName:(NSString *)objectClassName objectClass:(Class)objectClass properties:(NSArray *)properties {
    self = [super init];
    self.className = objectClassName;
    self.properties = properties;
    self.objectClass = objectClass;
    self.accessorClass = objectClass;
    self.unmanagedClass = objectClass;
    return self;
}

// return properties by name
-(RLMProperty *)objectForKeyedSubscript:(id <NSCopying>)key {
    return _allPropertiesByName[key];
}

// create property map when setting property array
-(void)setProperties:(NSArray *)properties {
    _properties = properties;
    _propertiesInDeclaredOrder = nil;
    [self _propertiesDidChange];
}

- (void)setComputedProperties:(NSArray *)computedProperties {
    _computedProperties = computedProperties;
    [self _propertiesDidChange];
}

- (void)_propertiesDidChange {
    NSMutableDictionary *map = [NSMutableDictionary dictionaryWithCapacity:_properties.count + _computedProperties.count];
    for (RLMProperty *prop in _properties) {
        map[prop.name] = prop;
        if (prop.isPrimary) {
            self.primaryKeyProperty = prop;
        }
    }
    for (RLMProperty *prop in _computedProperties) {
        map[prop.name] = prop;
    }
    _allPropertiesByName = map;
}


- (void)setPrimaryKeyProperty:(RLMProperty *)primaryKeyProperty {
    _primaryKeyProperty.isPrimary = NO;
    primaryKeyProperty.isPrimary = YES;
    _primaryKeyProperty = primaryKeyProperty;
}

+ (instancetype)schemaForObjectClass:(Class)objectClass {
    RLMObjectSchema *schema = [RLMObjectSchema new];

    // determine classname from objectclass as className method has not yet been updated
    NSString *className = NSStringFromClass(objectClass);
    bool isSwift = [RLMSwiftSupport isSwiftClassName:className];
    if (isSwift) {
        className = [RLMSwiftSupport demangleClassName:className];
    }
    schema.className = className;
    schema.objectClass = objectClass;
    schema.accessorClass = RLMDynamicObject.class;
    schema.isSwiftClass = isSwift;

    // create array of RLMProperties, inserting properties of superclasses first
    Class cls = objectClass;
    Class superClass = class_getSuperclass(cls);
    NSArray *allProperties = @[];
    while (superClass && superClass != RLMObjectBase.class) {
        allProperties = [[RLMObjectSchema propertiesForClass:cls isSwift:isSwift] arrayByAddingObjectsFromArray:allProperties];
        cls = superClass;
        superClass = class_getSuperclass(superClass);
    }
    NSArray *persistedProperties = [allProperties filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(RLMProperty *property, NSDictionary *) {
        return !RLMPropertyTypeIsComputed(property.type);
    }]];
    NSUInteger index = 0;
    for (RLMProperty *prop in persistedProperties) {
        prop.declarationIndex = index++;
    }
    schema.properties = persistedProperties;

    NSArray *computedProperties = [allProperties filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(RLMProperty *property, NSDictionary *) {
        return RLMPropertyTypeIsComputed(property.type);
    }]];
    schema.computedProperties = computedProperties;

    // verify that we didn't add any properties twice due to inheritance
    if (allProperties.count != [NSSet setWithArray:[allProperties valueForKey:@"name"]].count) {
        NSCountedSet *countedPropertyNames = [NSCountedSet setWithArray:[allProperties valueForKey:@"name"]];
        NSSet *duplicatePropertyNames = [countedPropertyNames filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *) {
            return [countedPropertyNames countForObject:object] > 1;
        }]];

        if (duplicatePropertyNames.count == 1) {
            @throw RLMException(@"Property '%@' is declared multiple times in the class hierarchy of '%@'", duplicatePropertyNames.allObjects.firstObject, className);
        } else {
            @throw RLMException(@"Object '%@' has properties that are declared multiple times in its class hierarchy: '%@'", className, [duplicatePropertyNames.allObjects componentsJoinedByString:@"', '"]);
        }
    }

    if (NSString *primaryKey = [objectClass primaryKey]) {
        for (RLMProperty *prop in schema.properties) {
            if ([primaryKey isEqualToString:prop.name]) {
                prop.indexed = YES;
                schema.primaryKeyProperty = prop;
                break;
            }
        }

        if (!schema.primaryKeyProperty) {
            @throw RLMException(@"Primary key property '%@' does not exist on object '%@'", primaryKey, className);
        }
        if (schema.primaryKeyProperty.type != RLMPropertyTypeInt && schema.primaryKeyProperty.type != RLMPropertyTypeString) {
            @throw RLMException(@"Only 'string' and 'int' properties can be designated the primary key");
        }
    }

    for (RLMProperty *prop in schema.properties) {
        if (prop.optional && !RLMPropertyTypeIsNullable(prop.type)) {
            @throw RLMException(@"Only 'string', 'binary', and 'object' properties can be made optional, and property '%@' is of type '%@'.",
                                prop.name, RLMTypeToString(prop.type));
        }
    }

    return schema;
}

+ (nullable NSString *)baseNameForLazySwiftProperty:(NSString *)propertyName {
    // A Swift lazy var shows up as two separate children on the reflection tree: one named 'x', and another that is
    // optional and is named 'x.storage'. Note that '.' is illegal in either a Swift or Objective-C property name.
    NSString *const storageSuffix = @".storage";
    if ([propertyName hasSuffix:storageSuffix]) {
        return [propertyName substringToIndex:propertyName.length - storageSuffix.length];
    }
    return nil;
}

+ (NSArray *)propertiesForClass:(Class)objectClass isSwift:(bool)isSwiftClass {
    Class objectUtil = [objectClass objectUtilClass:isSwiftClass];
    NSArray *indexed = [objectUtil indexedPropertiesForClass:objectClass];

    RLMObjcRuntimeArray<objc_property_t> props(class_copyPropertyList, objectClass);
    NSMutableArray *propArray = [NSMutableArray arrayWithCapacity:props.size()];
    auto addProperty = [propArray](RLMProperty *prop) {
        if (prop) {
            [propArray addObject:prop];
        }
    };

    if (!isSwiftClass || RLMIsKindOfClass(objectClass, RLMObject.class)) {
        if (props.size() == 0) {
            return @[];
        }

        NSArray *ignoredProperties = [objectClass ignoredProperties];
        auto requiredProperties = [objectClass requiredProperties];
        NSDictionary *linkingObjectsProperties = [objectClass linkingObjectsProperties];

        // For Swift classes we need an instance of the object when parsing properties
        id swiftObjectInstance = isSwiftClass ? [[objectClass alloc] init] : nil;

        for (auto prop : props) {
            NSString *propertyName = @(property_getName(prop));
            if ([ignoredProperties containsObject:propertyName]) {
                continue;
            }

            addProperty([[RLMProperty alloc] initWithName:propertyName
                                          containingClass:objectClass
                                                  indexed:[indexed containsObject:propertyName]
                                                 required:[requiredProperties containsObject:propertyName]
                                   linkPropertyDescriptor:linkingObjectsProperties[propertyName]
                                                 property:prop
                                            swiftInstance:swiftObjectInstance]);
        }
        return propArray;
    }
    // Otherwise RealmSwift.Object subclass

    id objectInstance = [[objectClass alloc] init];

    // Generic properties aren't registered with the obj-c runtime and we can't
    // tell if string/data/date properties are optioanl from obj-c, so we need
    // to get that information from Swift's reflection
    // Note that the Swift functionality takes care of filtering out ignored
    // properties and things like the backing properties for Lazy properties
    auto propertyNames = [NSMutableArray new];
    auto optionalProperties = [NSMutableSet new];
    auto numericPropertyTypes = [NSMutableDictionary new];
    [objectUtil getProperties:objectInstance
                        names:propertyNames
                     optional:optionalProperties
                  numberTypes:numericPropertyTypes];

    for (NSString *propertyName in propertyNames) {
        // First check for a matching obj-c property for non-generics so that
        // we can reuse as much of the handling for those as possible.
        const char *name = propertyName.UTF8String;
        auto objcProp = std::find_if(props.begin(), props.end(),
                                     [&](auto prop) { return !strcmp(property_getName(prop), name); });
        if (objcProp != props.end()) {
            addProperty([[RLMProperty alloc] initSwiftPropertyWithName:propertyName
                                                               indexed:[indexed containsObject:propertyName]
                                                              optional:[optionalProperties containsObject:propertyName]
                                                              property:*objcProp
                                                              instance:objectInstance]);
            continue;
        }

        // All of our supported Swift optional types produce obj-c properties,
        // so any others must be of an unsupported type
        if ([optionalProperties containsObject:propertyName]) {
            continue;
        }

        // Everything involving a generic managed process is done by reading the
        // ivar directly, so it needs to exist and needs to be an object
        Ivar ivar = class_getInstanceVariable(objectClass, propertyName.UTF8String);
        if (!ivar) {
            continue;
        }

        // If we have a number type then this is a RealmOptional<T> where T
        // is one of Int, Float, etc.
        if (NSNumber *boxedType = numericPropertyTypes[propertyName]) {
            addProperty([[RLMProperty alloc] initSwiftOptionalPropertyWithName:propertyName
                                                                       indexed:[indexed containsObject:propertyName]
                                                                          ivar:ivar
                                                                  propertyType:static_cast<RLMPropertyType>(boxedType.intValue)]);
            continue;
        }

        // If we got here it's either a List<> or LinkingObjects<>
        // Both of these we need to introspect the property value
        id value = object_getIvar(objectInstance, ivar);
        if (auto listBase = RLMDynamicCast<RLMListBase>(value)) {
            addProperty([[RLMProperty alloc] initSwiftListPropertyWithName:propertyName
                                                                      ivar:ivar
                                                           objectClassName:listBase._rlmArray.objectClassName]);
            continue;
        }

        if ([value respondsToSelector:@selector(objectClassName)] && [value respondsToSelector:@selector(propertyName)]) {
            addProperty([[RLMProperty alloc] initSwiftLinkingObjectsPropertyWithName:propertyName
                                                                                ivar:ivar
                                                                     objectClassName:[value objectClassName]
                                                              linkOriginPropertyName:[value propertyName]]);
            continue;
        }

        // Otherwise it's an unrecongized property of a type not reported to the
        // obj-c runtime. For now we ignore these rather than producing an error
        // as it would be a breaking change to reject them.
    }
    return propArray;
}

- (id)copyWithZone:(NSZone *)zone {
    RLMObjectSchema *schema = [[RLMObjectSchema allocWithZone:zone] init];
    schema->_objectClass = _objectClass;
    schema->_className = _className;
    schema->_objectClass = _objectClass;
    schema->_accessorClass = _accessorClass;
    schema->_unmanagedClass = _unmanagedClass;
    schema->_isSwiftClass = _isSwiftClass;

    // call property setter to reset map and primary key
    schema.properties = [[NSArray allocWithZone:zone] initWithArray:_properties copyItems:YES];
    schema.computedProperties = [[NSArray allocWithZone:zone] initWithArray:_computedProperties copyItems:YES];

    // _table not copied as it's realm::Group-specific
    return schema;
}

- (instancetype)shallowCopy {
    RLMObjectSchema *schema = [[RLMObjectSchema alloc] init];
    schema->_objectClass = _objectClass;
    schema->_className = _className;
    schema->_objectClass = _objectClass;
    schema->_accessorClass = _accessorClass;
    schema->_unmanagedClass = _unmanagedClass;
    schema->_isSwiftClass = _isSwiftClass;

    // reuse property array, map, and primary key instnaces
    schema->_properties = _properties;
    schema->_computedProperties = _computedProperties;
    schema->_allPropertiesByName = _allPropertiesByName;
    schema->_primaryKeyProperty = _primaryKeyProperty;
    schema->_swiftGenericProperties = _swiftGenericProperties;

    // _table not copied as it's realm::Group-specific
    return schema;
}

- (BOOL)isEqualToObjectSchema:(RLMObjectSchema *)objectSchema {
    if (objectSchema.properties.count != _properties.count) {
        return NO;
    }

    if (![_properties isEqualToArray:objectSchema.properties]) {
        return NO;
    }
    if (![_computedProperties isEqualToArray:objectSchema.computedProperties]) {
        return NO;
    }

    return YES;
}

- (NSString *)description {
    NSMutableString *propertiesString = [NSMutableString string];
    for (RLMProperty *property in self.properties) {
        [propertiesString appendFormat:@"\t%@\n", [property.description stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"]];
    }
    for (RLMProperty *property in self.computedProperties) {
        [propertiesString appendFormat:@"\t%@\n", [property.description stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"]];
    }
    return [NSString stringWithFormat:@"%@ {\n%@}", self.className, propertiesString];
}

- (realm::Table *)table {
    if (!_table) {
        _table = ObjectStore::table_for_object_type(_realm.group, _className.UTF8String);
    }
    return _table.get();
}

- (void)setTable:(realm::Table *)table {
    _table.reset(table);
}

- (realm::ObjectSchema)objectStoreCopy {
    ObjectSchema objectSchema;
    objectSchema.name = _className.UTF8String;
    objectSchema.primary_key = _primaryKeyProperty ? _primaryKeyProperty.name.UTF8String : "";
    for (RLMProperty *prop in _properties) {
        Property p = [prop objectStoreCopy];
        p.is_primary = (prop == _primaryKeyProperty);
        objectSchema.persisted_properties.push_back(std::move(p));
    }
    for (RLMProperty *prop in _computedProperties) {
        objectSchema.computed_properties.push_back([prop objectStoreCopy]);
    }
    return objectSchema;
}

+ (instancetype)objectSchemaForObjectStoreSchema:(realm::ObjectSchema &)objectSchema {
    RLMObjectSchema *schema = [RLMObjectSchema new];
    schema.className = @(objectSchema.name.c_str());

    // create array of RLMProperties
    NSMutableArray *properties = [NSMutableArray arrayWithCapacity:objectSchema.persisted_properties.size()];
    for (const Property &prop : objectSchema.persisted_properties) {
        RLMProperty *property = [RLMProperty propertyForObjectStoreProperty:prop];
        property.isPrimary = (prop.name == objectSchema.primary_key);
        [properties addObject:property];
    }
    schema.properties = properties;

    NSMutableArray *computedProperties = [NSMutableArray arrayWithCapacity:objectSchema.computed_properties.size()];
    for (const Property &prop : objectSchema.computed_properties) {
        [computedProperties addObject:[RLMProperty propertyForObjectStoreProperty:prop]];
    }
    schema.computedProperties = computedProperties;

    // get primary key from realm metadata
    if (objectSchema.primary_key.length()) {
        NSString *primaryKeyString = [NSString stringWithUTF8String:objectSchema.primary_key.c_str()];
        schema.primaryKeyProperty = schema[primaryKeyString];
        if (!schema.primaryKeyProperty) {
            @throw RLMException(@"No property matching primary key '%@'", primaryKeyString);
        }
    }

    // for dynamic schema use vanilla RLMDynamicObject accessor classes
    schema.objectClass = RLMObject.class;
    schema.accessorClass = RLMDynamicObject.class;
    schema.unmanagedClass = RLMObject.class;
    
    return schema;
}

- (void)sortPropertiesByColumn {
    _properties = [_properties sortedArrayUsingComparator:^NSComparisonResult(RLMProperty *p1, RLMProperty *p2) {
        if (p1.column < p2.column) return NSOrderedAscending;
        if (p1.column > p2.column) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    // No need to update the dictionary
}

- (NSArray *)propertiesInDeclaredOrder {
    if (!_propertiesInDeclaredOrder) {
        _propertiesInDeclaredOrder = [_properties sortedArrayUsingComparator:^NSComparisonResult(RLMProperty *p1, RLMProperty *p2) {
            if (p1.declarationIndex < p2.declarationIndex) return NSOrderedAscending;
            if (p1.declarationIndex > p2.declarationIndex) return NSOrderedDescending;
            return NSOrderedSame;
        }];
    }
    return _propertiesInDeclaredOrder;
}

- (NSArray *)swiftGenericProperties {
    if (_swiftGenericProperties) {
        return _swiftGenericProperties;
    }

    // This check isn't semantically required, but avoiding accessing the local
    // static helps perf in the obj-c case
    if (!_isSwiftClass) {
        return _swiftGenericProperties = @[];
    }

    // Check if it's a swift class using the obj-c API
    static Class s_swiftObjectClass = NSClassFromString(@"RealmSwiftObject");
    if (![_accessorClass isSubclassOfClass:s_swiftObjectClass]) {
        return _swiftGenericProperties = @[];
    }

    NSMutableArray *genericProperties = [NSMutableArray new];
    for (RLMProperty *prop in _properties) {
        if (prop->_swiftIvar || prop->_type == RLMPropertyTypeArray) {
            [genericProperties addObject:prop];
        }
    }
    // Currently all computed properties are Swift generics
    [genericProperties addObjectsFromArray:_computedProperties];

    return _swiftGenericProperties = genericProperties;
}

@end
