//
//  main.m
//  HQLConvertGifToPng
//
//  Created by 何启亮 on 2018/5/23.
//  Copyright © 2018年 hql_personal_team. All rights reserved.
//

#import <Foundation/Foundation.h>

BOOL CGImageWriteToFile(CGImageRef image, NSString *path);
void GifToLastFramePngAndCreatePlist(NSArray <NSString *>*itemArray, NSString *path, NSMutableDictionary *targetDict);
void GifToFirstFramePngAndCreateDirectory(NSArray <NSString *>*itemArray, NSString *path);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // 获取路径
        char buffer[1000];     //使用一个缓冲区
        NSLog(@"请输入路径:");
        scanf("%s",buffer);
        NSString *path = [NSString stringWithUTF8String:buffer];    //将缓冲区赋给NSString变量
        NSLog(@"目标路径＝%@",path);
        // /Users/heqiliang/Desktop/WorldLandmark
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if (![fileManager fileExistsAtPath:path]) {
            NSLog(@"%@ not exists", path);
            return 0;
        }
        
        // 遍历path 下的所有item
        NSArray *itemArray = [fileManager contentsOfDirectoryAtPath:path error:nil];
        if (itemArray.count <= 0) {
            NSLog(@"Path not exists item");
            return 0;
        }

        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                    @"iconNormalPath" : @"videoEdit_EffectPicker_WorldLandmark_Normal",
                                                                                    @"iconSelectedPath" : @"videoEdit_EffectPicker_WorldLandmark_Selected",
                                                                                    @"iconClickPath" : @"",
                                                                                    }];
        GifToLastFramePngAndCreatePlist(itemArray, path, dict);
    }
    return 0;
}

void GifToLastFramePngAndCreatePlist(NSArray <NSString *>*itemArray, NSString *path, NSMutableDictionary *targetDict) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSMutableArray *targetArray = [NSMutableArray array];
    for (NSString *itemString in itemArray) {
        NSArray *fileNameComponent = [itemString componentsSeparatedByString:@"."];
        if (fileNameComponent.count <= 1) {
            // 属于文件夹
            NSLog(@"%@ is directory", itemString);
            continue;
        }
        NSString *extension = fileNameComponent.lastObject;
        NSString * lowerExtension = [extension lowercaseString];
        if (![lowerExtension isEqualToString:@"png"] &&
            ![lowerExtension isEqualToString:@"gif"] &&
            ![lowerExtension isEqualToString:@"jpg"] &&
            ![lowerExtension isEqualToString:@"jpeg"]) {
            // 不是图片格式
            NSLog(@"%@ is not a image", itemString);
            continue;
        }
        
        NSString *fileName = [itemString stringByDeletingPathExtension];
        
        // 创建缩略图
        NSString *movedItemPath = [path stringByAppendingPathComponent:itemString];
        NSString *thumilName = [fileName stringByAppendingPathExtension:@"png"];
        if (![lowerExtension isEqualToString:@"png"]) {
            NSURL *fileUrl = [NSURL fileURLWithPath:movedItemPath];
            CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)fileUrl, NULL);
            if (source == NULL) {
                NSLog(@"Create thumil error %@", movedItemPath);
                continue;
            }
            
            size_t count = CGImageSourceGetCount(source);
            if (count <= 0) {
                NSLog(@"Create thumil error %@", movedItemPath);
                continue;
            }
            
            CGImageRef image = CGImageSourceCreateImageAtIndex(source, (count - 1), NULL);
            
            CFRelease(source);
            
            if (image == NULL) {
                NSLog(@"Create thumil error %@", movedItemPath);
                continue;
            }
            
            NSString *thumilPath = [path stringByAppendingPathComponent:thumilName];
            BOOL writeYesOrNo = CGImageWriteToFile(image, thumilPath);
            CFRelease(image);
            if (!writeYesOrNo) {
                NSLog(@"Create thumil error %@", movedItemPath);
                continue;
            }
        }
        
        // 到这已经创建了png
        [targetArray addObject:@{
                                 @"gifPath" : itemString,
                                 @"pngPath" : thumilName,
                                 }];
        
    }
    
    [targetDict setObject:targetArray forKey:@"modelArray"];
    
    NSString *name = [path lastPathComponent];
    NSString *namePath = [path stringByAppendingString:[NSString stringWithFormat:@"/%@.plist", name]];
    if ([fileManager fileExistsAtPath:namePath]) {
        [fileManager removeItemAtPath:namePath error:nil];
    }
    
    [targetDict writeToFile:namePath atomically:YES];
}

void GifToFirstFramePngAndCreateDirectory(NSArray <NSString *>*itemArray, NSString *path) {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    for (NSString *itemString in itemArray) {
        
        NSArray *fileNameComponent = [itemString componentsSeparatedByString:@"."];
        if (fileNameComponent.count <= 1) {
            // 属于文件夹
            NSLog(@"%@ is directory", itemString);
            continue;
        }
        NSString *extension = fileNameComponent.lastObject;
        NSString * lowerExtension = [extension lowercaseString];
        if (![lowerExtension isEqualToString:@"png"] &&
            ![lowerExtension isEqualToString:@"gif"] &&
            ![lowerExtension isEqualToString:@"jpg"] &&
            ![lowerExtension isEqualToString:@"jpeg"]) {
            // 不是图片格式
            NSLog(@"%@ is not a image", itemString);
            continue;
        }
        
        NSString *fileName = fileNameComponent.firstObject;
        // 将 git 和 png 遍历
        // 1.创建一个文件夹
        NSString *directoryPath = [path stringByAppendingPathComponent:fileName];
        NSError *createDirectoryError;
        BOOL yesOrNo = [fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&createDirectoryError];
        if (!yesOrNo) {
            // 创建失败
            NSLog(@"Create %@ failed, error : %@", directoryPath, createDirectoryError);
            continue;
        }
        
        // 将文件移动到文件夹里面
        NSError *moveError;
        NSString *itemPath = [path stringByAppendingPathComponent:itemString];
        NSString *itemMovePath = [directoryPath stringByAppendingPathComponent:itemString];
        yesOrNo = [fileManager moveItemAtPath:itemPath toPath:itemMovePath error:&moveError];
        if (!yesOrNo) {
            // 移动失败
            NSLog(@"Move item %@ failed, error : %@", itemPath, moveError);
            continue;
        }
        
        // 创建缩略图
        NSString *movedItemPath = [directoryPath stringByAppendingPathComponent:itemString];
        NSString *thumilName = [fileName stringByAppendingPathExtension:@"png"];
        if (![lowerExtension isEqualToString:@"png"]) {
            NSURL *fileUrl = [NSURL fileURLWithPath:movedItemPath];
            CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)fileUrl, NULL);
            if (source == NULL) {
                NSLog(@"Create thumil error %@", movedItemPath);
                continue;
            }
            
            CGImageRef image = CGImageSourceCreateImageAtIndex(source, 0, NULL);
            
            CFRelease(source);
            
            if (image == NULL) {
                NSLog(@"Create thumil error %@", movedItemPath);
                continue;
            }
            
            NSString *thumilPath = [directoryPath stringByAppendingPathComponent:thumilName];
            BOOL writeYesOrNo = CGImageWriteToFile(image, thumilPath);
            CFRelease(image);
            if (!writeYesOrNo) {
                NSLog(@"Create thumil error %@", movedItemPath);
                continue;
            }
        }
        
        //             到这里已经创建缩略图成功
        //             创建info.json
        NSString *infoJson = [NSString stringWithFormat:@"{\"name\" : \"%@\", \"gifPath\" : \"%@\", \"thumb\" : \"%@\"}", fileName, itemString, thumilName];
        NSString *jsonPath = [directoryPath stringByAppendingPathComponent:@"info.json"];
        [infoJson writeToFile:jsonPath atomically:yesOrNo encoding:NSUTF8StringEncoding error:nil];
        
        // 成功
        NSLog(@"Create Success : %@", itemString);
    }
}

BOOL CGImageWriteToFile(CGImageRef image, NSString *path) {
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    if (!destination) {
        NSLog(@"Failed to create CGImageDestination for %@", path);
        return NO;
    }
    
    CGImageDestinationAddImage(destination, image, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", path);
        CFRelease(destination);
        return NO;
    }
    
    CFRelease(destination);
    return YES;
}

