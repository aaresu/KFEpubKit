#import <Foundation/Foundation.h>
#import "XR_DDXML.h"

// These methods are not part of the standard NSXML API.
// But any developer working extensively with XML will likely appreciate them.

@interface XR_DDXMLElement (DDAdditions)

+ (XR_DDXMLElement *)elementWithName:(NSString *)name xmlns:(NSString *)ns;

- (XR_DDXMLElement *)elementForName:(NSString *)name;
- (XR_DDXMLElement *)elementForName:(NSString *)name xmlns:(NSString *)xmlns;

- (NSString *)xmlns;
- (void)setXmlns:(NSString *)ns;

- (NSString *)prettyXMLString;
- (NSString *)compactXMLString;

- (void)addAttributeWithName:(NSString *)name stringValue:(NSString *)string;

- (NSDictionary *)attributesAsDictionary;

@end
