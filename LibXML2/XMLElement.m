//
//  HTMLElement.m
//  FavIcon
//
//  Created by Leon Breedt on 28/10/15.
//  Copyright © 2015 Leon Breedt. All rights reserved.
//

#import "XMLElement.h"
#import "XMLElement_Private.h"

@implementation XMLElement {
    xmlNodePtr _xmlNode;
    NSString *_name;
    NSDictionary *_attributes;
    NSArray *_children;
}

- (instancetype)initWithDocument:(LBXMLDocument *)document node:(xmlNodePtr)node {
    if (self = [super init]) {
        self.document = document;
        _xmlNode = node;
    }
    return self;
}

- (NSString *)name {
    if (!_name) {
        _name = [NSString stringWithUTF8String:(const char *)_xmlNode->name];
    }
    return _name;
}

- (NSDictionary<NSString *,NSString *> *)attributes {
    if (!_attributes) {
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        
        struct _xmlAttr *currentAttr = _xmlNode->properties;
        while (currentAttr) {
            NSString *name = [[NSString stringWithUTF8String:(const char *)currentAttr->name] lowercaseString];
            char *nodeContent = (char *)xmlNodeGetContent(currentAttr->children);
            NSString *value = @"";
            if (nodeContent) {
                value = [NSString stringWithUTF8String:nodeContent];
                xmlFree(nodeContent);
            }
            [attributes setObject:value forKey:name];
            currentAttr = currentAttr->next;
        }
        
        _attributes = attributes;
    }
    return _attributes;
}

- (NSArray<XMLElement *> *)children {
    if (!_children) {
        NSMutableArray *children = [NSMutableArray array];
        
        xmlNodePtr currentChild = _xmlNode->children;
        while (currentChild) {
            if (currentChild->type == XML_ELEMENT_NODE) {
                [children addObject:[[XMLElement alloc] initWithDocument:_document node:currentChild]];
            }
            currentChild = currentChild->next;
        }
        
        _children = children;
    }
    return _children;
}

- (void)dealloc {
    self.document = nil; // OK for xmlDocPtr to go away now.
    _xmlNode = nil;
}

@end
