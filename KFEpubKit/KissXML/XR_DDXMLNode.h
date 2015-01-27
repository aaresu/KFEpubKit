#import <Foundation/Foundation.h>
#import <libxml/tree.h>

@class XR_DDXMLDocument;

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

enum {
	XR_DDXMLInvalidKind                = 0,
	XR_DDXMLDocumentKind               = XML_DOCUMENT_NODE,
	XR_DDXMLElementKind                = XML_ELEMENT_NODE,
	XR_DDXMLAttributeKind              = XML_ATTRIBUTE_NODE,
	XR_DDXMLNamespaceKind              = XML_NAMESPACE_DECL,
	XR_DDXMLProcessingInstructionKind  = XML_PI_NODE,
	XR_DDXMLCommentKind                = XML_COMMENT_NODE,
	XR_DDXMLTextKind                   = XML_TEXT_NODE,
	XR_DDXMLDTDKind                    = XML_DTD_NODE,
	XR_DDXMLEntityDeclarationKind      = XML_ENTITY_DECL,
	XR_DDXMLAttributeDeclarationKind   = XML_ATTRIBUTE_DECL,
	XR_DDXMLElementDeclarationKind     = XML_ELEMENT_DECL,
	XR_DDXMLNotationDeclarationKind    = XML_NOTATION_NODE
};
typedef NSUInteger XR_DDXMLNodeKind;

enum {
	XR_DDXMLNodeOptionsNone            = 0,
	XR_DDXMLNodeExpandEmptyElement     = 1 << 1,
	XR_DDXMLNodeCompactEmptyElement    = 1 << 2,
	XR_DDXMLNodePrettyPrint            = 1 << 17,
};


//extern struct _xmlKind;


@interface XR_DDXMLNode : NSObject <NSCopying>
{
	// Every XR_DDXML object is simply a wrapper around an underlying libxml node
	struct _xmlKind *genericPtr;
	
	// Every libxml node resides somewhere within an xml tree heirarchy.
	// We cannot free the tree heirarchy until all referencing nodes have been released.
	// So all nodes retain a reference to the node that created them,
	// and when the last reference is released the tree gets freed.
	XR_DDXMLNode *owner;
}

//- (id)initWithKind:(XR_DDXMLNodeKind)kind;

//- (id)initWithKind:(XR_DDXMLNodeKind)kind options:(NSUInteger)options;

//+ (id)document;

//+ (id)documentWithRootElement:(XR_DDXMLElement *)element;

+ (id)elementWithName:(NSString *)name;

+ (id)elementWithName:(NSString *)name URI:(NSString *)URI;

+ (id)elementWithName:(NSString *)name stringValue:(NSString *)string;

+ (id)elementWithName:(NSString *)name children:(NSArray *)children attributes:(NSArray *)attributes;

+ (id)attributeWithName:(NSString *)name stringValue:(NSString *)stringValue;

+ (id)attributeWithName:(NSString *)name URI:(NSString *)URI stringValue:(NSString *)stringValue;

+ (id)namespaceWithName:(NSString *)name stringValue:(NSString *)stringValue;

+ (id)processingInstructionWithName:(NSString *)name stringValue:(NSString *)stringValue;

+ (id)commentWithStringValue:(NSString *)stringValue;

+ (id)textWithStringValue:(NSString *)stringValue;

//+ (id)DTDNodeWithXMLString:(NSString *)string;

#pragma mark --- Properties ---

- (XR_DDXMLNodeKind)kind;

- (void)setName:(NSString *)name;
- (NSString *)name;

//- (void)setObjectValue:(id)value;
//- (id)objectValue;

- (void)setStringValue:(NSString *)string;
//- (void)setStringValue:(NSString *)string resolvingEntities:(BOOL)resolve;
- (NSString *)stringValue;

#pragma mark --- Tree Navigation ---

- (NSUInteger)index;

- (NSUInteger)level;

- (XR_DDXMLDocument *)rootDocument;

- (XR_DDXMLNode *)parent;
- (NSUInteger)childCount;
- (NSArray *)children;
- (XR_DDXMLNode *)childAtIndex:(NSUInteger)index;

- (XR_DDXMLNode *)previousSibling;
- (XR_DDXMLNode *)nextSibling;

- (XR_DDXMLNode *)previousNode;
- (XR_DDXMLNode *)nextNode;

- (void)detach;

- (NSString *)XPath;

#pragma mark --- QNames ---

- (NSString *)localName;
- (NSString *)prefix;

- (void)setURI:(NSString *)URI;
- (NSString *)URI;

+ (NSString *)localNameForName:(NSString *)name;
+ (NSString *)prefixForName:(NSString *)name;
//+ (XR_DDXMLNode *)predefinedNamespaceForPrefix:(NSString *)name;

#pragma mark --- Output ---

- (NSString *)description;
- (NSString *)XMLString;
- (NSString *)XMLStringWithOptions:(NSUInteger)options;
//- (NSString *)canonicalXMLStringPreservingComments:(BOOL)comments;

#pragma mark --- XPath/XQuery ---

- (NSArray *)nodesForXPath:(NSString *)xpath error:(NSError **)error;

// This is an extension over NSXMLNode.
// It is required if you are using XPath with documents with default namespaces.
- (NSArray *)nodesForXPath:(NSString *)xpath namespaceMappings:(NSDictionary*)namespaceMappings error:(NSError **)error;

//- (NSArray *)objectsForXQuery:(NSString *)xquery constants:(NSDictionary *)constants error:(NSError **)error;
//- (NSArray *)objectsForXQuery:(NSString *)xquery error:(NSError **)error;

+ (void)installErrorHandlersInThread;

@end
