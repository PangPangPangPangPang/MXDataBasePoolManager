//
//  MXDataBasePoolManager.h
//  SinaNews
//
//  Created by Max Wang on 16/4/6.
//  Copyright © 2016年 sina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"

/*
 @param sql
 @param finishBlock sql执行完毕回调（main thread）
 @param dbPath 数据库路径 方法中无dbPath则为默认路径'SinaNewsDataBase.sqlite'
 @param args sql参
 */

/* 进行替换时，可使用同步相关方法 */

#define Default_DataBase_Path @"MX_Default_DataBase_Path.sqlite"

static char* cMXSQLitePoolManager;

@interface MXDataBasePoolManager : NSObject

+ (instancetype)shareInstance;
+ (NSString *)generateDBPath:(NSString *)db;
- (FMDatabase *)defaultDataBase;
- (NSString *)defaultDataPath;
+ (void)setDefaultPath:(NSString *)dbPath;

- (FMDatabase *)getDataBase:(NSString *)dbPath;
- (BOOL)closeDataBase:(NSString *)dbPath;

//异步
- (void)excuteQuery:(NSString *)sql
             finish:(void (^)(NSArray *result))finishBlock;

- (void)excuteQuery:(NSString *)sql
               args:(NSDictionary *)args
             finish:(void (^)(NSArray *result))finishBlock;

- (void)excuteQuery:(NSString *)sql
               args:(NSDictionary *)args
             dbPath:(NSString *)dbPath
             finish:(void (^)(NSArray *result))finishBlock;

- (void)excuteUpdate:(NSString *)sql
              finish:(void (^)(BOOL flag))finishBlock;

- (void)excuteUpdate:(NSString *)sql
                args:(NSDictionary *)args
              finish:(void (^)(BOOL flag))finishBlock;

- (void)excuteUpdate:(NSString *)sql
                args:(NSDictionary *)args
              dbPath:(NSString *)dbPath
              finish:(void (^)(BOOL flag))finishBlock;

- (void)excuteTransation:(void (^)(FMDatabase *db, BOOL* rollback))transationBlock
             finishBlock:(void (^)(BOOL flag))finishBlock;

- (void)excuteTransation:(void (^)(FMDatabase *db, BOOL* rollback))transationBlock
                  dbPath:(NSString *)dbPath
             finishBlock:(void (^)(BOOL flag))finishBlock;

//同步
- (NSArray *)sync_excuteQuery:(NSString *)sql, ...;

- (NSArray *)sync_excuteQuery:(NSString *)sql
                         args:(NSDictionary *)args;

- (NSArray *)sync_excuteQuery:(NSString *)sql
                         args:(NSDictionary *)args
                       dbPath:(NSString *)dbPath;

- (NSArray *)sync_excuteQuery:(NSString *)sql
                         args:(NSDictionary *)args
                      varList:(va_list)list
                       dbPath:(NSString *)dbPath;

- (BOOL)sync_excuteUpdate:(NSString *)sql, ...;

- (BOOL)sync_excuteUpdate:(NSString *)sql
                     args:(NSDictionary *)args;

- (BOOL)sync_excuteUpdate:(NSString *)sql
                     args:(NSDictionary *)args
                   dbPath:(NSString *)dbPath;

- (BOOL)sync_excuteUpdate:(NSString *)sql
                     args:(NSDictionary *)args
                  varList:(va_list)list
                   dbPath:(NSString *)dbPath;

- (BOOL)sync_excuteTransation:(void (^)(FMDatabase *db))transationBlock;

- (BOOL)sync_excuteTransation:(void (^)(FMDatabase *db))transationBlock
                       dbPath:(NSString *)dbPath;

@end
