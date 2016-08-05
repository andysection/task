//
//  ViewController.m
//  TableView-loadImageView
//
//  Created by 王璋杰 on 16/7/29.
//  Copyright © 2016年 itcast. All rights reserved.
//

#import "AFNetworking.h"
#import "NSString+path.h"
#import "ViewController.h"
#import "WASApplication.h"

static NSString* cellid = @"cellid";

@interface ViewController ()
/**
 *  数据源
 */
@property (nonatomic, strong) NSMutableArray* appDataInfos;
/**
 *  自定义队列
 */
@property (nonatomic, strong) NSOperationQueue* queue;
/**
 *  图片缓存
 */
@property (nonatomic, strong) NSMutableDictionary* imageCache;
/**
 *  操作缓存
 */
@property (nonatomic, strong) NSMutableDictionary* operationCache;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self loadDataFromNet];
}

- (void)loadDataFromNet
{
    NSString* urlString = @"https://raw.githubusercontent.com/yinqiaoyin/Demo/master/apps.json";

    AFHTTPSessionManager* manager = [AFHTTPSessionManager manager];
    [manager GET:urlString parameters:nil progress:nil success:^(NSURLSessionDataTask* _Nonnull task, id _Nullable responseObject) {
        //success
        NSLog(@"load sucess!");
        NSArray* tempArr = responseObject;
        //        NSLog(@"%@", tempArr);
        for (NSDictionary* dict in tempArr) {
            WASApplication* app = [[WASApplication alloc] init];
            [app setValuesForKeysWithDictionary:dict];
            [self.appDataInfos addObject:app];
        }

        [self.tableView reloadData];
    }
        failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
            //
            NSLog(@"failed! %@", error);
        }];
}
#pragma mark - TableView set
- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.appDataInfos.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellid forIndexPath:indexPath];
    WASApplication* app = self.appDataInfos[indexPath.row];
    cell.textLabel.text = app.name;
    cell.imageView.image = [UIImage imageNamed:@"user_default"];

    //在缓存中寻找是否有需要的图片
    if ([self.imageCache valueForKey:app.icon]) {
        NSLog(@"get from momery");
        cell.imageView.image = self.imageCache[app.icon];
        return cell;
    }

    //在沙盒中寻找是否存在需要的图片
    UIImage* cacheImage = [UIImage imageWithContentsOfFile:[app.icon appendCachePath]];
    if (cacheImage) {
        NSLog(@"get from sandbox");
        [self.imageCache setObject:cacheImage forKey:app.icon];
        cell.imageView.image = cacheImage;
        return cell;
    }

    //在缓存中寻找是否已经在下载图片
    if ([self.operationCache valueForKey:app.icon]) {
        NSLog(@"downloading ,plz wait!");
        return cell;
    }

    //下载图片
    NSBlockOperation* op = [NSBlockOperation blockOperationWithBlock:^{
        [NSThread sleepForTimeInterval:arc4random_uniform(6)];
        NSLog(@"begin downloading !!!!oh yeah");
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:app.icon]];
        UIImage* image = [UIImage imageWithData:data];
        //这里容易chument
        if (image != nil) {
            //添加至缓存
            [self.imageCache setObject:image forKey:app.icon];
        }
        //保存到沙盒 atomically是否以原子特性去写入文件
        [data writeToFile:[app.icon appendCachePath] atomically:YES];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            //下载完毕 重新加载图片
            [tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationLeft];
        }];
        //下载完毕从缓存中删除 该操作
        [self.operationCache removeObjectForKey:app.icon];
    }];

    [self.queue addOperation:op];
    //添加到缓存操作 避免重复下载
    [self.operationCache setObject:op forKey:app.icon];

    return cell;
}

#pragma mark - lazyLoad
- (NSMutableArray*)appDataInfos
{
    if (_appDataInfos == nil) {
        _appDataInfos = [NSMutableArray array];
    }
    return _appDataInfos;
}

- (NSOperationQueue*)queue
{
    if (_queue == nil) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return _queue;
}
//图片缓存
- (NSMutableDictionary*)imageCache
{
    if (!_imageCache) {
        _imageCache = [NSMutableDictionary dictionary];
    }
    return _imageCache;
}
//操作缓存
- (NSMutableDictionary*)operationCache
{
    if (!_operationCache) {
        _operationCache = [NSMutableDictionary dictionary];
    }
    return _operationCache;
}

#pragma mark - momeryWarninig
- (void)didReceiveMemoryWarning
{
    //清空缓存
    [self.imageCache removeAllObjects];
    [self.operationCache removeAllObjects];
}
@end
