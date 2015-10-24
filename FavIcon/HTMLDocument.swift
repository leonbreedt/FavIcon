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

class HTMLElement {
    var htmlNode: htmlNodePtr
    
    private init(htmlNode: htmlNodePtr) {
        self.htmlNode = htmlNode
    }
    
    lazy var name: String = {
        return String.fromCString(UnsafePointer(self.htmlNode.memory.name)) ?? ""
    }()
    
    lazy var attributes: [String: String] = {
        var currentAttr = self.htmlNode.memory.properties
        var attrs: [String: String] = [:]
        if currentAttr != nil {
            repeat {
                let namePtr = currentAttr.memory.name
                let name = String.fromCString(UnsafePointer(namePtr))
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
    
    lazy var children: [HTMLElement] = {
        return makeHTMLElementArray(self.htmlNode.memory.children)
    }()
}

class HTMLDocument {
    var htmlDocument: htmlDocPtr
    
    private init(htmlDocument: htmlDocPtr) {
        self.htmlDocument = htmlDocument
    }
    
    init(data: NSData) {
        self.htmlDocument =
            htmlReadMemory(
                UnsafePointer(data.bytes),
                Int32(data.length),
                "",
                nil,
                Int32(HTML_PARSE_NOWARNING.rawValue) | Int32(HTML_PARSE_NOERROR.rawValue))
    }
    
    convenience init(string: String) {
        self.init(data: string.dataUsingEncoding(NSUTF8StringEncoding)!)
    }

    lazy var children: [HTMLElement] = {
        return makeHTMLElementArray(self.htmlDocument.memory.children)
    }()
    
    func query(xpath: String) -> [HTMLElement] {
        var context = xmlXPathNewContext(htmlDocument)
        if context == nil { return [] }
        defer { xmlXPathFreeContext(context) }
        
        var object = xmlXPathEvalExpression(xpath, context)
        if object == nil { return [] }
        defer { xmlXPathFreeObject(object) }
        
        var elements: [HTMLElement] = []
        
        let nodes = object.memory.nodesetval
        if nodes == nil { return [] }
        for i in 0..<(nodes.memory.nodeNr) {
            let node = nodes.memory.nodeTab[Int(i)]
            elements.append(HTMLElement(htmlNode: node))
        }
        
        return elements
    }
    
    deinit {
        xmlFreeDoc(htmlDocument)
    }
}

private func makeHTMLElementArray(startingNode: xmlNodePtr) -> [HTMLElement] {
    var results: [HTMLElement] = []
    var currentChild = startingNode
    if currentChild != nil {
        repeat {
            if currentChild.memory.type == XML_ELEMENT_NODE {
                results.append(HTMLElement(htmlNode: currentChild))
            }
            currentChild = currentChild.memory.next
        } while (currentChild != nil)
    }
    return results
}