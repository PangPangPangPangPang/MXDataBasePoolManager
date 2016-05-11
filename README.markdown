
## CocoaPods

MXDataBasePoolManager can be installed using [CocoaPods](https://cocoapods.org/).

```
pod 'MXDataBasePoolManager'

```

## Introduce

MXDataBasePoolManager is a wrapper of FMDB that help you dispatch the queue.Users need not care about dead lock or other queue's problems.

## Usage

###DefaultPath

```objc
[MXDataBasePoolManager setDefaultPath:@"MX_Example.sqlite"];
```

### async method

```objc
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
```

### sync method

```objc
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
```

## About me

[Weibo](http://weibo.com/mmmmmmaxx)

[Blog](http://mmmmmax.wang)
