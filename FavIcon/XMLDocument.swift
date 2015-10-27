//
// FavIcon
// Copyright (C) 2015 Leon Breedt
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

import Foundation
import LibXML2

class XMLDocument {
    var xmlDocument: xmlDocPtr
    
    private init(xmlDocument: xmlDocPtr) {
        self.xmlDocument = xmlDocument
    }
    
    init(data: NSData) {
        self.xmlDocument =
            xmlReadMemory(
                UnsafePointer(data.bytes),
                Int32(data.length),
                "",
                nil,
                0)
    }
    
    convenience init(string: String) {
        self.init(data: string.dataUsingEncoding(NSUTF8StringEncoding)!)
    }
    
    lazy var children: [XMLElement] = {
        return makeXMLElementArray(self, startingNode: self.xmlDocument.memory.children)
    }()
    
    func query(xpath: String) -> [XMLElement] {
        var context = xmlXPathNewContext(xmlDocument)
        if context == nil { return [] }
        defer { xmlXPathFreeContext(context) }
        
        var object = xmlXPathEvalExpression(xpath, context)
        if object == nil { return [] }
        defer { xmlXPathFreeObject(object) }
        
        var elements: [XMLElement] = []
        
        let nodes = object.memory.nodesetval
        if nodes == nil { return [] }
        for i in 0..<(nodes.memory.nodeNr) {
            let node = nodes.memory.nodeTab[Int(i)]
            elements.append(XMLElement(document: self, xmlNode: node))
        }
        
        return elements
    }
    
    deinit {
        xmlFreeDoc(xmlDocument)
    }
}

class XMLElement {
    var document: XMLDocument?
    var xmlNode: xmlNodePtr
    
    private init(document: XMLDocument, xmlNode: xmlNodePtr) {
        self.document = document
        self.xmlNode = xmlNode
    }
    
    deinit {
        self.xmlNode = nil
        self.document = nil
    }
    
    lazy var name: String = {
        return String.fromCString(UnsafePointer(self.xmlNode.memory.name))?.lowercaseString ?? ""
    }()
    
    lazy var attributes: [String: String] = {
        var currentAttr = self.xmlNode.memory.properties
        var attrs: [String: String] = [:]
        if currentAttr != nil {
            repeat {
                let namePtr = currentAttr.memory.name
                let name = String.fromCString(UnsafePointer(namePtr))?.lowercaseString
                let valuePtr = xmlNodeGetContent(UnsafePointer(currentAttr))
                var value: String? = nil
                if valuePtr != nil {
                    value = String.fromCString(UnsafePointer(valuePtr))
                    xmlFree(valuePtr)
                }
                if let name = name {
                    attrs[name] = value
                }
                currentAttr = currentAttr.memory.next
            } while (currentAttr != nil)
        }
        return attrs
    }()
    
    lazy var children: [XMLElement] = {
        return makeXMLElementArray(self.document!, startingNode: self.xmlNode.memory.children)
    }()
}

private func makeXMLElementArray(document: XMLDocument, startingNode: xmlNodePtr) -> [XMLElement] {
    var results: [XMLElement] = []
    var currentChild = startingNode
    if currentChild != nil {
        repeat {
            if currentChild.memory.type == XML_ELEMENT_NODE {
                results.append(XMLElement(document: document, xmlNode: currentChild))
            }
            currentChild = currentChild.memory.next
        } while (currentChild != nil)
    }
    return results
}