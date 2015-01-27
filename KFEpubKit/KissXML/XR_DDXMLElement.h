#import <Foundation/Foundation.h>
#import "XR_DDXMLNode.h"

/**
 * Welcome to KissXML.
 * 
 * The project page has documentation if you have questions.
 * https://github.com/robbiehanson/KissXML
 * 
 * If you're new to the project you may wish to read the "Getting Started" wiki.
 * https://github.com/robbiehanson/KissXML/wiki/GettingStarted
 * 
 * KissXML provides a drop-in replacement for Apple's NSXML class cluster.
 * The goal is to get the exact same behavior as the NSXML classes.
 * 
 * For API Reference, see Apple's excellent documentation,
 * either via Xcode's Mac OS X documentation, or via the web:
 * 
 * https://github.com/robbiehanson/KissXML/wiki/Reference
**/

@interface XR_DDXMLElement : XR_DDXMLNode
{
}

- (id)initWithName:(NSString *)name;
- (id)initWithName:(NSString *)name URI:(NSString *)URI;
- (id)initWithName:(NSString *)name stringValue:(NSString *)string;
- (id)initWithXMLString:(NSString *)string error:(NSError **)error;

#pragma mark --- Elements by name ---

- (NSArray *)elementsForName:(NSString *)name;
- (NSArray *)elementsForLocalName:(NSString *)localName URI:(NSString *)URI;

#pragma mark --- Attributes ---

- (void)addAttribute:(XR_DDXMLNode *)attribute;
- (void)removeAttributeForName:(NSString *)name;
- (void)setAttributes:(NSArray *)attributes;
//- (void)setAttributesAsDictionary:(NSDictionary *)attributes;
- (NSArray *)attributes;
- (XR_DDXMLNode *)attributeForName:(NSString *)name;
//- (XR_DDXMLNode *)attributeForLocalName:(NSString *)localName URI:(NSString *)URI;

#pragma mark --- Namespaces ---

- (void)addNamespace:(XR_DDXMLNode *)aNamespace;
- (void)removeNamespaceForPrefix:(NSString *)name;
- (void)setNamespaces:(NSArray *)namespaces;
- (NSArray *)namespaces;
- (XR_DDXMLNode *)namespaceForPrefix:(NSString *)prefix;
- (XR_DDXMLNode *)resolveNamespaceForName:(NSString *)name;
- (NSString *)resolvePrefixForNamespaceURI:(NSString *)namespaceURI;

#pragma mark --- Children ---

- (void)insertChild:(XR_DDXMLNode *)child atIndex:(NSUInteger)index;
//- (void)insertChildren:(NSArray *)children atIndex:(NSUInteger)index;
- (void)removeChildAtIndex:(NSUInteger)index;
- (void)setChildren:(NSArray *)children;
- (void)addChild:(XR_DDXMLNode *)child;
//- (void)replaceChildAtIndex:(NSUInteger)index withNode:(XR_DDXMLNode *)node;
//- (void)normalizeAdjacentTextNodesPreservingCDATA:(BOOL)preserve;

@end
