//  KFEpubParser.m
//  KFEpubKit
//
// Copyright (c) 2013 Rico Becker | KF INTERACTIVE
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "KFEpubParser.h"

@interface KFEpubParser ()
@property (strong) NSXMLParser *parser;
@property (strong) NSString *rootPath;
@property (strong) NSMutableDictionary *items;
@property (strong) NSMutableArray *spinearray;
@end

#define kMimeTypeEpub @"application/epub+zip"
#define kMimeTypeiBooks @"application/x-ibooks+zip"

@implementation KFEpubParser

- (KFEpubKitBookType)bookTypeFromDocument:(DDXMLDocument *)document
{
    KFEpubKitBookType bookType = KFEpubKitBookTypeUnknown;
    
    DDXMLElement *root  = [document rootElement];
    DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
    defaultNamespace.name = @"default";
    
    NSString *ePubVersionString = [[[[root nodesForXPath:@"//default:package[1]" error:nil] firstObject] attributeForName:@"version"] stringValue];
    CGFloat ePubVersion = [ePubVersionString floatValue];

    if (ePubVersion >= 2.0 && ePubVersion < 3.0) {
        bookType = KFEpubKitBookTypeEpub2;
    } else if (ePubVersion >= 3.0 && ePubVersion < 4.0) {
        bookType = KFEpubKitBookTypeEpub3;
    } else {
        bookType = KFEpubKitBookTypeUnknown;
    }
    
    return bookType;
}

- (KFEpubKitBookEncryption)contentEncryptionForBaseURL:(NSURL *)baseURL
{
    NSURL *containerURL = [[baseURL URLByAppendingPathComponent:@"META-INF"] URLByAppendingPathComponent:@"sinf.xml"];
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfURL:containerURL encoding:NSUTF8StringEncoding error:&error];
    DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:content options:kNilOptions error:&error];
    
    if (error)
    {
        return KFEpubKitBookEnryptionNone;
    }
    NSArray *sinfNodes = [document.rootElement nodesForXPath:@"//fairplay:sinf" error:&error];
    if (sinfNodes == nil || sinfNodes.count == 0)
    {
        return KFEpubKitBookEnryptionNone;
    }
    else
    {
        return KFEpubKitBookEnryptionFairplay;
    }
}


- (NSURL *)rootFileForBaseURL:(NSURL *)baseURL
{
    NSError *error = nil;
    NSURL *containerURL = [[baseURL URLByAppendingPathComponent:@"META-INF"] URLByAppendingPathComponent:@"container.xml"];
    
    NSString *content = [NSString stringWithContentsOfURL:containerURL encoding:NSUTF8StringEncoding error:&error];
    DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:content options:kNilOptions error:&error];
    DDXMLElement *root  = [document rootElement];
    
    DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
    defaultNamespace.name = @"default";
    NSArray* objectElements = [root nodesForXPath:@"//default:container/default:rootfiles/default:rootfile" error:&error];
    
    NSUInteger count = 0;
    NSString *value = nil;
    for (DDXMLElement* xmlElement in objectElements)
    {
        value = [[xmlElement attributeForName:@"full-path"] stringValue];
        count++;
    }
    
    if (count == 1 && value)
    {
        return [baseURL URLByAppendingPathComponent:value];
    }
    else if (count == 0)
    {
        NSLog(@"no root file found.");
    }
    else
    {
        NSLog(@"there are more than one root files. this is odd.");
    }
    return nil;
}


- (NSString *)coverPathComponentFromDocument:(DDXMLDocument *)document
{
    NSString *coverPath;
    DDXMLElement *root  = [document rootElement];
    DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
    defaultNamespace.name = @"default";
    NSArray *metaNodes = [root nodesForXPath:@"//default:item[@properties='cover-image']" error:nil];
    
    if (metaNodes)
    {
        coverPath = [[metaNodes.lastObject attributeForName:@"href"] stringValue];
    }
    
    if (!coverPath)
    {
        NSString *coverItemId;
        
        DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
        defaultNamespace.name = @"default";
        metaNodes = [root nodesForXPath:@"//default:meta" error:nil];
        for (DDXMLElement *xmlElement in metaNodes)
        {
            if ([[xmlElement attributeForName:@"name"].stringValue compare:@"cover" options:NSCaseInsensitiveSearch] == NSOrderedSame)
            {
                coverItemId = [xmlElement attributeForName:@"content"].stringValue;
            }
        }
        
        if (!coverItemId)
        {
            return nil;
        }
        else
        {
            DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
            defaultNamespace.name = @"default";
            NSArray *itemNodes = [root nodesForXPath:@"//default:item" error:nil];
            
            for (DDXMLElement *itemElement in itemNodes)
            {
                if ([[itemElement attributeForName:@"id"].stringValue compare:coverItemId options:NSCaseInsensitiveSearch] == NSOrderedSame)
                {
                    coverPath = [itemElement attributeForName:@"href"].stringValue;
                }
            }
            
        }
    }
    return coverPath;
}



- (NSDictionary *)metaDataFromDocument:(DDXMLDocument *)document
{
    NSMutableDictionary *metaData = [NSMutableDictionary new];
    DDXMLElement *root  = [document rootElement];
    DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
    defaultNamespace.name = @"default";
    NSArray *metaNodes = [root nodesForXPath:@"//default:package/default:metadata" error:nil];
    
    if (metaNodes.count == 1)
    {
        DDXMLElement *metaNode = metaNodes[0];
        NSArray *metaElements = metaNode.children;

        for (DDXMLElement* xmlElement in metaElements)
        {
            if ([self isValidNode:xmlElement])
            {
                metaData[xmlElement.localName] = xmlElement.stringValue;
            }
        }
    }
    else
    {
        NSLog(@"meta data invalid");
        return nil;
    }
    return metaData;
}


- (NSArray *)spineFromDocument:(DDXMLDocument *)document
{
    NSMutableArray *spine = [NSMutableArray new];
    DDXMLElement *root  = [document rootElement];
    DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
    defaultNamespace.name = @"default";
    NSArray *spineNodes = [root nodesForXPath:@"//default:package/default:spine" error:nil];
    
    if (spineNodes.count == 1)
    {
        DDXMLElement *spineElement = spineNodes[0];
        
        NSArray *spineElements = spineElement.children;
        for (DDXMLElement* xmlElement in spineElements)
        {
            if ([self isValidNode:xmlElement])
            {
                [spine addObject:[[xmlElement attributeForName:@"idref"] stringValue]];
            }
        }
    }
    else
    {
        NSLog(@"spine data invalid");
        return nil;
    }
    return spine;
}

- (NSDictionary *)manifestFromDocument:(DDXMLDocument *)document
{
    NSMutableDictionary *manifest = [NSMutableDictionary new];
    DDXMLElement *root  = [document rootElement];
    DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
    defaultNamespace.name = @"default";
    NSArray *manifestNodes = [root nodesForXPath:@"//default:package/default:manifest" error:nil];
    
    if (manifestNodes.count == 1)
    {
        NSArray *itemElements = ((DDXMLElement *)manifestNodes[0]).children;
        for (DDXMLElement* xmlElement in itemElements)
        {
            if ([self isValidNode:xmlElement] && xmlElement.attributes)
            {
                NSString *href = [[xmlElement attributeForName:@"href"] stringValue];
                NSString *itemId = [[xmlElement attributeForName:@"id"] stringValue];
                NSString *mediaType = [[xmlElement attributeForName:@"media-type"] stringValue];
                
                if (itemId)
                {
                    NSMutableDictionary *items = [NSMutableDictionary new];
                    if (href)
                    {
                        items[@"href"] = href;
                    }
                    if (mediaType)
                    {
                        items[@"media"] = mediaType;
                    }
                    manifest[itemId] = items;
                }
            }
        }
    }
    else
    {
        NSLog(@"manifest data invalid");
        return nil;
    }
    return manifest;
}


- (NSArray *)guideFromDocument:(DDXMLDocument *)document
{
    NSMutableArray *guide = [NSMutableArray new];
    DDXMLElement *root  = [document rootElement];
    
    DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
    defaultNamespace.name = @"default";
    NSArray *guideNodes = [root nodesForXPath:@"//default:package/default:guide" error:nil];
    
    if (guideNodes.count == 1)
    {
        DDXMLElement *guideElement = guideNodes[0];
        NSArray *referenceElements = guideElement.children;
        
        for (DDXMLElement* xmlElement in referenceElements)
        {
            if ([self isValidNode:xmlElement])
            {
                NSString *type = [[xmlElement attributeForName:@"type"] stringValue];
                NSString *href = [[xmlElement attributeForName:@"href"] stringValue];
                NSString *title = [[xmlElement attributeForName:@"title"] stringValue];
                
                NSMutableDictionary *reference = [NSMutableDictionary new];
                if (type)
                {
                    reference[type] = type;
                }
                if (href)
                {
                    reference[@"href"] = href;
                }
                if (title)
                {
                    reference[@"title"] = title;
                }
                [guide addObject:reference];
            }
        }
    }
    else
    {
        NSLog(@"guide data invalid");
        return nil;
    }
    
    return guide;
}

- (NSArray*)ePub2ChaptersFromDocument:(DDXMLDocument *)document
{
    NSArray *chapters = [NSMutableArray new];
    DDXMLElement *root  = [document rootElement];
    
    NSError *error;
    DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
    defaultNamespace.name = @"default";
    NSArray *chaptersNodes = [root nodesForXPath:@"//default:navMap" error:&error];
    
    if (chaptersNodes.count == 1)
    {
        chapters = [self ePub2ChaptersFromNode:[chaptersNodes firstObject] level:0];
    }
    else
    {
        NSLog(@"chapter data invalid");
        return nil;
    }
    
    chapters = [chapters sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"playOrder" ascending:YES]]];
    
    return chapters;
}

- (NSArray*)ePub2ChaptersFromNode:(DDXMLNode*)navNapMode level:(NSInteger)level
{
    NSMutableArray *chapters = [NSMutableArray array];
    NSArray *nodes = [navNapMode nodesForXPath:@"default:navPoint" error:nil];
    if (nodes.count == 0) return nil;
    
    for (DDXMLElement *node in nodes) {
        if (![self isValidNode:node]) continue;
        
        NSString *identifier = [[node attributeForName:@"id"] stringValue];
        NSInteger playOrder = [[[node attributeForName:@"playOrder"] stringValue] integerValue];
        
        DDXMLElement *navLabel = [[node nodesForXPath:@"default:navLabel/default:text" error:nil] firstObject];
        NSString *label = [[[navLabel elementsForName:@"text"] firstObject] stringValue];
        
        DDXMLElement *contents = [[node nodesForXPath:@"default:content" error:nil] firstObject];
        NSString *src = [[contents attributeForName:@"src"] stringValue];
        
        NSDictionary *chapter = @{@"id" : identifier,
                                  @"playOrder" : @(playOrder),
                                  @"label" : label,
                                  @"scr" : src,
                                  @"level" : @(level)};
        [chapters addObject:chapter];
        
        NSArray *subChapters = [self ePub2ChaptersFromNode:node level:level+1];
        if (subChapters.count) [chapters addObjectsFromArray:subChapters];
    }
    return chapters;
}

- (NSArray*)ePub3ChaptersFromDocument:(DDXMLDocument *)document
{
    NSArray *chapters = [NSMutableArray new];
    DDXMLElement *root  = [document rootElement];
    
    NSError *error;
    DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
    defaultNamespace.name = @"default";
    
    DDXMLElement *navNode = [[root nodesForXPath:@"//default:nav" error:&error] firstObject];
    
    if ([self isValidNode:navNode])
    {
        DDXMLElement *chapterContainerNode = [[navNode nodesForXPath:@"default:ol" error:&error] firstObject];
        chapters = [self ePub3ChaptersFromNode:chapterContainerNode level:0];
    }
    else
    {
        NSLog(@"chapter data invalid");
        return nil;
    }
    
    chapters = [chapters sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"playOrder" ascending:YES]]];
    
    return chapters;
}

- (NSArray*)ePub3ChaptersFromNode:(DDXMLNode*)navNapMode level:(NSInteger)level
{
    NSMutableArray *chapters = [NSMutableArray array];
    NSArray *nodes = [navNapMode nodesForXPath:@"default:li" error:nil];
    if (nodes.count == 0) return nil;
    
    for (DDXMLElement *node in nodes) {
        if (![self isValidNode:node]) continue;
        
        DDXMLElement *contents = [[node nodesForXPath:@"default:a" error:nil] firstObject];
        
        NSString *label = [contents stringValue];
        NSString *src = [[contents attributeForName:@"href"] stringValue];
        
        NSDictionary *chapter = @{@"label" : label,
                                  @"scr" : src,
                                  @"level" : @(level)};
        [chapters addObject:chapter];
        
        DDXMLElement *subChaptersContainerNode = [[node nodesForXPath:@"default:ol" error:nil] firstObject];
        NSArray *subChapters = [self ePub3ChaptersFromNode:subChaptersContainerNode level:level+1];
        if (subChapters.count) [chapters addObjectsFromArray:subChapters];
    }
    
    return chapters;
}

- (BOOL)isValidNode:(DDXMLElement *)node
{
    return node.kind != DDXMLCommentKind;
}


@end
