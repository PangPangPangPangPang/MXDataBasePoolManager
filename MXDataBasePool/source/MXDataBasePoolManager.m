//
//  MXDataBasePoolManager.m
//  SinaNews
//
//  Created by Max Wang on 16/4/6.
//  Copyright © 2016年 sina. All rights reserved.
//

#import "MXDataBasePoolManager.h"
#import "libkern/OSAtomic.h"

static MXDataBasePoolManager *_manager = nil;
static char* cSNSQLitePoolManager = "SNSQLitePoolManager";
static OSSpinLock lock = OS_SPINLOCK_INIT;

#define check_default_queue \
char* v = dispatch_get_specific(cSNSQLitePoolManager); \
NSAssert(v != cSNSQLitePoolManager, @"can't call this method below 'sn_default_queue()'"); \

BOOL is_valid_queue(dispatch_queue_t q) {
    dispatch_queue_t Q = (__bridge dispatch_queue_t)(dispatch_get_specific(cSNSQLitePoolManager));
    return Q != q;
}

void safe_dispatch_sync(dispatch_queue_t q, dispatch_block_t block) {
    BOOL valid = is_valid_queue(q);
    if (valid) {
        dispatch_sync(q, block);
    }else {
        block();
    }
}

@implementation MXDataBasePoolManager {
    NSMutableDictionary    *_dbDic;
    NSMutableDictionary    *_qDic;
    NSString               *_dbFullPath;
}

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [MXDataBasePoolManager new];
    });
    return _manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dbDic = [NSMutableDictionary new];
        _qDic = [NSMutableDictionary new];
        [self defaultDataPath];
    }
    return self;
}

- (FMDatabase *)getDataBase:(NSString *)dbPath {
    OSSpinLockLock(&lock);
    FMDatabase *db = [_dbDic valueForKey:dbPath];
    if (!db) {
        db = [FMDatabase databaseWithPath:dbPath];
        dispatch_queue_t q = dispatch_queue_create([dbPath cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(q, cSNSQLitePoolManager, (__bridge void *)(q), NULL);
        [_dbDic setValue:db forKey:dbPath];
        [_qDic setValue:q forKey:dbPath];
        [db open];
    }
    OSSpinLockUnlock(&lock);
    return db;
}

- (FMDatabase *)defaultDataBase {
    return [self getDataBase:[self defaultDataPath]];
}

+ (NSString *)generateDBPath:(NSString *)db {
    NSString *result = nil;
    NSArray * names = [db componentsSeparatedByString:@"."];
    NSString * bundlePath = [[NSBundle mainBundle] pathForResource:[names objectAtIndexSafely:0]
                                                            ofType:[names objectAtIndexSafely:1]];
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString * fullPath = [[CoreSinaNews sharedCore].userPath stringByAppendingPathComponent:db];
    result = fullPath;
    
    if (![fileManager fileExistsAtPath:fullPath])
    {
        NSError *error;
        if (![fileManager copyItemAtPath:bundlePath
                                  toPath:fullPath
                                   error:&error])
            NSAssert(NO, error.description);
    }
    return result;
}

- (NSString *)defaultDataPath {
    if (!_dbFullPath) {
        _dbFullPath = [MXDataBasePoolManager generateDBPath:SinaNewsDataBase_Name];
    }
    return _dbFullPath;
}

- (void)excuteQuery:(NSString *)sql
             finish:(void (^)(NSArray *))finishBlock {
    [self excuteQuery:sql
                 args:nil
               finish:finishBlock];
}

- (void)excuteQuery:(NSString *)sql
               args:(NSDictionary *)args
             finish:(void (^)(NSArray *))finishBlock {
    [self excuteQuery:sql
                 args:args
               dbPath:[self defaultDataPath]
               finish:finishBlock];
}

- (void)excuteQuery:(NSString *)sql
               args:(NSDictionary *)args
             dbPath:(NSString *)dbPath
             finish:(void (^)(NSArray *))finishBlock {
    
    FMDatabase *db = [self getDataBase:dbPath];
    dispatch_queue_t q = [_qDic valueForKey:dbPath];
    dispatch_async(q, ^{
        FMResultSet *result;
        if (!args) {
            result = [db executeQuery:sql];
        }else {
            result = [db executeQuery:sql withParameterDictionary:args];
        }
        NSMutableArray *tempArray = [NSMutableArray new];
        while ([result next]) {
            [tempArray addObject:[self clearDictory:[result resultDictionary]]];
        }
        [result close];
        dispatch_async(dispatch_get_main_queue(), ^{
            finishBlock(tempArray);
        });
    });
}

- (BOOL)closeDataBase:(NSString *)dbPath {
    OSSpinLockLock(&lock);
    FMDatabase *db = [_dbDic valueForKey:dbPath];
    if (!db) {
        OSSpinLockUnlock(&lock);
        return NO;
    }
    [db close];
    [_dbDic removeObjectForKey:dbPath];
    OSSpinLockUnlock(&lock);
    return YES;
}

- (void)excuteUpdate:(NSString *)sql
              finish:(void (^)(BOOL))finishBlock {
    [self excuteUpdate:sql
                  args:nil
                finish:finishBlock];
}

- (void)excuteUpdate:(NSString *)sql
                args:(NSDictionary *)args
              finish:(void (^)(BOOL))finishBlock {
    [self excuteUpdate:sql
                  args:args
                dbPath:[self defaultDataPath]
                finish:finishBlock];
}

- (void)excuteUpdate:(NSString *)sql
                args:(NSDictionary *)args
              dbPath:(NSString *)dbPath
              finish:(void (^)(BOOL flag))finishBlock {
    
    FMDatabase *db = [self getDataBase:dbPath];
    dispatch_queue_t q = [_qDic valueForKey:dbPath];
    dispatch_async(q, ^{
        BOOL result;
        if (!args) {
            result = [db executeUpdate:sql];
        }else {
            result = [db executeUpdate:sql
               withParameterDictionary:args];
        }
        if (finishBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                finishBlock(result);
            });
        }
    });
}

- (void)excuteTransation:(void (^)(FMDatabase *,BOOL* rollback))transationBlock
             finishBlock:(void (^)(BOOL))finishBlock {
    [self excuteTransation:transationBlock
                    dbPath:[self defaultDataPath]
               finishBlock:finishBlock];
}

- (void)excuteTransation:(void (^)(FMDatabase *db,BOOL* rollback))transationBlock
                  dbPath:(NSString *)dbPath
             finishBlock:(void (^)(BOOL))finishBlock {
    
    FMDatabase *db = [self getDataBase:dbPath];
    dispatch_queue_t q = [_qDic valueForKey:dbPath];
    dispatch_async(q, ^{
        BOOL rollback = NO;
        [db beginTransaction];
        transationBlock(db,&rollback);
        if (rollback) {
            [db rollback];
        }else {
            [db commit];
        }
        
        NSAssert(!rollback, [db lastError].description);
        
        if (finishBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                finishBlock(rollback);
            });
        }
        
    });
}

- (NSArray *)sync_excuteQuery:(NSString *)sql, ... {
    va_list args;
    va_start(args, sql);
    NSArray *result = [self sync_excuteQuery:sql
                                        args:nil
                                     varList:args
                                      dbPath:[self defaultDataPath]];
    va_end(args);
    return result;
    
}

- (NSArray *)sync_excuteQuery:(NSString *)sql
                         args:(NSDictionary *)args {
    return [self sync_excuteQuery:sql
                             args:args
                           dbPath:[self defaultDataPath]];
}

- (NSArray *)sync_excuteQuery:(NSString *)sql
                         args:(NSDictionary *)args
                       dbPath:(NSString *)dbPath {
    return [self sync_excuteQuery:sql
                             args:args
                          varList:nil
                           dbPath:dbPath];
}

- (NSArray *)sync_excuteQuery:(NSString *)sql
                         args:(NSDictionary *)args
                      varList:(va_list)list
                       dbPath:(NSString *)dbPath {
    
    FMDatabase *db = [self getDataBase:dbPath];
    dispatch_queue_t q = [_qDic valueForKey:dbPath];
    NSMutableArray *tempArray = [NSMutableArray new];
    safe_dispatch_sync(q,^{
        FMResultSet *result;
        if (args) {
            result = [db executeQuery:sql withParameterDictionary:args];
        }else if(list){
            result = [db executeQuery:sql withVAList:list];
        }else {
            result = [db executeQuery:sql];
        }
        while ([result next]) {
            [tempArray addObject:[self clearDictory:[result resultDictionary]]];
        }
        [result close];
    });
    return tempArray;
}


- (BOOL)sync_excuteUpdate:(NSString *)sql, ...{
    va_list args;
    va_start(args, sql);
    BOOL result = [self sync_excuteUpdate:sql
                                     args:nil
                                  varList:args
                                   dbPath:[self defaultDataPath]];
    va_end(args);
    return result;
}

- (BOOL)sync_excuteUpdate:(NSString *)sql args:(NSDictionary *)args {
    return  [self sync_excuteUpdate:sql
                               args:args
                             dbPath:[self defaultDataPath]];
}

- (BOOL)sync_excuteUpdate:(NSString *)sql
                     args:(NSDictionary *)args
                   dbPath:(NSString *)dbPath {
    
    FMDatabase *db = [self getDataBase:dbPath];
    dispatch_queue_t q = [_qDic valueForKey:dbPath];
    __block BOOL result;
    safe_dispatch_sync(q, ^{
        if (!args) {
            result = [db executeUpdate:sql];
        }else {
            result = [db executeUpdate:sql
               withParameterDictionary:args];
        }
    });
    return result;
}

- (BOOL)sync_excuteUpdate:(NSString *)sql
                     args:(NSDictionary *)args
                  varList:(va_list)list
                   dbPath:(NSString *)dbPath {
    
    FMDatabase *db = [self getDataBase:dbPath];
    dispatch_queue_t q = [_qDic valueForKey:dbPath];
    __block BOOL result;
    safe_dispatch_sync(q, ^{
        if (args) {
            result = [db executeUpdate:sql
               withParameterDictionary:args];
        }else if(list){
            result = [db executeUpdate:sql
                            withVAList:list];
        }else {
            result = [db executeUpdate:sql];
        }
    });
    return result;
}

- (BOOL)sync_excuteTransation:(void (^)(FMDatabase *))transationBlock {
    return [self sync_excuteTransation:transationBlock
                                dbPath:[self defaultDataPath]];
}

- (BOOL)sync_excuteTransation:(void (^)(FMDatabase *))transationBlock
                       dbPath:(NSString *)dbPath {
    
    FMDatabase *db = [self getDataBase:dbPath];
    dispatch_queue_t q = [_qDic valueForKey:dbPath];
    __block BOOL rollback = NO;
    safe_dispatch_sync(q, ^{
        [db beginTransaction];
        transationBlock(db);
        if (rollback) {
            [db rollback];
        }else {
            [db commit];
        }
        NSAssert(!rollback, [db lastError].description);
    });
    return !rollback;
}

- (void)dealloc {
    [[_dbDic allValues] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [(FMDatabase *)obj close];
    }];
}

- (NSDictionary *)clearDictory:(NSDictionary *)originDictory {
    if (!originDictory) {
        return nil;
    }
    
    NSMutableDictionary *result = [NSMutableDictionary new];
    for (NSString *key in originDictory.allKeys) {
        if (![[originDictory valueForKey:key] isKindOfClass:[NSNull class]]) {
            [result setValue:[originDictory valueForKey:key] forKey:key];
        }
    }
    return result;
}

@end
