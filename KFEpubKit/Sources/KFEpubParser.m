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

- (KFEpubKitBookType)bookTypeFromDocument:(XR_DDXMLDocument *)document
{
    KFEpubKitBookType bookType = KFEpubKitBookTypeUnknown;
    
    XR_DDXMLElement *root  = [document rootElement];
    XR_DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
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
    XR_DDXMLDocument *document = [[XR_DDXMLDocument alloc] initWithXMLString:content options:kNilOptions error:&error];
    
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
    XR_DDXMLDocument *document = [[XR_DDXMLDocument alloc] initWithXMLString:content options:kNilOptions error:&error];
    XR_DDXMLElement *root  = [document rootElement];
    
    XR_DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
    defaultNamespace.name = @"default";
    NSArray* objectElements = [root nodesForXPath:@"//default:container/default:rootfiles/default:rootfile" error:&error];
    
    NSUInteger count = 0;
    NSString *value = nil;
    for (XR_DDXMLElement* xmlElement in objectElements)
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


- (NSString *)coverPathComponentFromDocument:(XR_DDXMLDocument *)document
{
    NSString *coverPath;
    XR_DDXMLElement *root  = [document rootElement];
    XR_DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
    defaultNamespace.name = @"default";
    NSArray *metaNodes = [root nodesForXPath:@"//default:item[@properties='cover-image']" error:nil];
    
    if (metaNodes)
    {
        coverPath = [[metaNodes.lastObject attributeForName:@"href"] stringValue];
    }
    
    if (!coverPath)
    {
        NSString *coverItemId;
        
        XR_DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
        defaultNamespace.name = @"default";
        metaNodes = [root nodesForXPath:@"//default:meta" error:nil];
        for (XR_DDXMLElement *xmlElement in metaNodes)
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
            XR_DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
            defaultNamespace.name = @"default";
            NSArray *itemNodes = [root nodesForXPath:@"//default:item" error:nil];
            
            for (XR_DDXMLElement *itemElement in itemNodes)
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



- (NSDictionary *)metaDataFromDocument:(XR_DDXMLDocument *)document
{
    NSMutableDictionary *metaData = [NSMutableDictionary new];
    XR_DDXMLElement *root  = [document rootElement];
    XR_DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
    defaultNamespace.name = @"default";
    NSArray *metaNodes = [root nodesForXPath:@"//default:package/default:metadata" error:nil];
    
    if (metaNodes.count == 1)
    {
        XR_DDXMLElement *metaNode = metaNodes[0];
        NSArray *metaElements = metaNode.children;

        for (XR_DDXMLElement* xmlElement in metaElements)
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


- (NSArray *)spineFromDocument:(XR_DDXMLDocument *)document
{
    NSMutableArray *spine = [NSMutableArray new];
    XR_DDXMLElement *root  = [document rootElement];
    XR_DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
    defaultNamespace.name = @"default";
    NSArray *spineNodes = [root nodesForXPath:@"//default:package/default:spine" error:nil];
    
    if (spineNodes.count == 1)
    {
        XR_DDXMLElement *spineElement = spineNodes[0];
        
        NSArray *spineElements = spineElement.children;
        for (XR_DDXMLElement* xmlElement in spineElements)
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

- (NSDictionary *)manifestFromDocument:(XR_DDXMLDocument *)document
{
    NSMutableDictionary *manifest = [NSMutableDictionary new];
    XR_DDXMLElement *root  = [document rootElement];
    XR_DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
    defaultNamespace.name = @"default";
    NSArray *manifestNodes = [root nodesForXPath:@"//default:package/default:manifest" error:nil];
    
    if (manifestNodes.count == 1)
    {
        NSArray *itemElements = ((XR_DDXMLElement *)manifestNodes[0]).children;
        for (XR_DDXMLElement* xmlElement in itemElements)
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


- (NSArray *)guideFromDocument:(XR_DDXMLDocument *)document
{
    NSMutableArray *guide = [NSMutableArray new];
    XR_DDXMLElement *root  = [document rootElement];
    
    XR_DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
    defaultNamespace.name = @"default";
    NSArray *guideNodes = [root nodesForXPath:@"//default:package/default:guide" error:nil];
    
    if (guideNodes.count == 1)
    {
        XR_DDXMLElement *guideElement = guideNodes[0];
        NSArray *referenceElements = guideElement.children;
        
        for (XR_DDXMLElement* xmlElement in referenceElements)
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

- (NSArray*)ePub2ChaptersFromDocument:(XR_DDXMLDocument *)document
{
    NSArray *chapters = [NSMutableArray new];
    XR_DDXMLElement *root  = [document rootElement];
    
    NSError *error;
    XR_DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
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

- (NSArray*)ePub2ChaptersFromNode:(XR_DDXMLNode*)navNapMode level:(NSInteger)level
{
    NSMutableArray *chapters = [NSMutableArray array];
    NSArray *nodes = [navNapMode nodesForXPath:@"default:navPoint" error:nil];
    if (nodes.count == 0) return nil;
    
    for (XR_DDXMLElement *node in nodes) {
        if (![self isValidNode:node]) continue;
        
        NSString *identifier = [[node attributeForName:@"id"] stringValue];
        NSInteger playOrder = [[[node attributeForName:@"playOrder"] stringValue] integerValue];
        
        XR_DDXMLElement *navLabel = [[node nodesForXPath:@"default:navLabel/default:text" error:nil] firstObject];
        NSString *label = [[[navLabel elementsForName:@"text"] firstObject] stringValue];
        
        XR_DDXMLElement *contents = [[node nodesForXPath:@"default:content" error:nil] firstObject];
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

- (NSArray*)ePub3ChaptersFromDocument:(XR_DDXMLDocument *)document
{
    NSArray *chapters = [NSMutableArray new];
    XR_DDXMLElement *root  = [document rootElement];
    
    NSError *error;
    XR_DDXMLNode *defaultNamespace = [root namespaceForPrefix:@""];
    defaultNamespace.name = @"default";
    
    XR_DDXMLElement *navNode = [[root nodesForXPath:@"//default:nav" error:&error] firstObject];
    
    if ([self isValidNode:navNode])
    {
        XR_DDXMLElement *chapterContainerNode = [[navNode nodesForXPath:@"default:ol" error:&error] firstObject];
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

- (NSArray*)ePub3ChaptersFromNode:(XR_DDXMLNode*)navNapMode level:(NSInteger)level
{
    NSMutableArray *chapters = [NSMutableArray array];
    NSArray *nodes = [navNapMode nodesForXPath:@"default:li" error:nil];
    if (nodes.count == 0) return nil;
    
    for (XR_DDXMLElement *node in nodes) {
        if (![self isValidNode:node]) continue;
        
        XR_DDXMLElement *contents = [[node nodesForXPath:@"default:a" error:nil] firstObject];
        
        NSString *label = [contents stringValue];
        NSString *src = [[contents attributeForName:@"href"] stringValue];
        
        NSDictionary *chapter = @{@"label" : label,
                                  @"scr" : src,
                                  @"level" : @(level)};
        [chapters addObject:chapter];
        
        XR_DDXMLElement *subChaptersContainerNode = [[node nodesForXPath:@"default:ol" error:nil] firstObject];
        NSArray *subChapters = [self ePub3ChaptersFromNode:subChaptersContainerNode level:level+1];
        if (subChapters.count) [chapters addObjectsFromArray:subChapters];
    }
    
    return chapters;
}

- (BOOL)isValidNode:(XR_DDXMLElement *)node
{
    return node.kind != XR_DDXMLCommentKind;
}


@end
