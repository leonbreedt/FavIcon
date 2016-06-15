//
// FavIcon
// Copyright © 2016 Leon Breedt
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "XMLDocument.h"
#import "XMLElement.h"
#import "XMLElement_Private.h"
#import "libxml/tree.h"
#import "libxml/xpath.h"
#import "libxml/xpathInternals.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LBXMLDocument {
    xmlDocPtr _xmlDocument;
    NSArray *_children;
}

- (instancetype)initWithData:(NSData *)data {
    if (self = [super init]) {
        _xmlDocument = xmlReadMemory(
            data.bytes,
            (int)data.length,
            "",
            NULL,
            0);
    }
    return self;
}

- (void)dealloc {
    if (_xmlDocument) {
        xmlFreeDoc(_xmlDocument);
    }
}

- (instancetype)initWithString:(NSString *)string {
    self = [self initWithData:[string dataUsingEncoding:NSUTF8StringEncoding]];
    return self;
}

- (NSArray<XMLElement *> *)children {
    if (!_children) {
        NSMutableArray *children = [NSMutableArray array];
        
        xmlNodePtr currentChild = _xmlDocument->children;
        while (currentChild) {
            if (currentChild->type == XML_ELEMENT_NODE) {
                [children addObject:[[XMLElement alloc] initWithDocument:self node:currentChild]];
            }
            currentChild = currentChild->next;
        }
        
        _children = children;
    }
    
    return _children;
}

- (NSArray<XMLElement *> *)query:(NSString *)xpath {
    NSMutableArray *results = [NSMutableArray array];
    
    xmlXPathContextPtr context = xmlXPathNewContext(_xmlDocument);
    if (!context) {
        return results;
    }
    
    xmlXPathObjectPtr object = xmlXPathEvalExpression((const xmlChar *)[xpath UTF8String], context);
    if (!object) {
        xmlXPathFreeContext(context);
        return results;
    }
    
    if (!object->nodesetval) {
        xmlXPathFreeObject(object);
        xmlXPathFreeContext(context);
        return results;
    }
    
    for (int i = 0; i < object->nodesetval->nodeNr; i++) {
        xmlNodePtr node = object->nodesetval->nodeTab[i];
        [results addObject:[[XMLElement alloc] initWithDocument:self node:node]];
    }
    
    xmlXPathFreeObject(object);
    xmlXPathFreeContext(context);
    
    return results;
}

@end

NS_ASSUME_NONNULL_END
