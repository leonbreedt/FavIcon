//
// FavIcon
// Copyright © 2018 Leon Breedt
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

import Foundation
import libxmlFavicon

final class XMLDocument {
    fileprivate var _document: xmlDocPtr!
    private var _children: [XMLElement]?

    convenience init(string: String) {
        self.init(data: string.data(using: .utf8)!)
    }

    init(data: Data) {
        ensureLibXMLErrorHandlingSuppressed()
        _document = data.withUnsafeBytes { (p: UnsafePointer<Int8>) -> htmlDocPtr in
            return xmlReadMemory(p, Int32(data.count), nil, nil, 0)
        }
    }

    var children: [XMLElement] {
        guard let document = _document else {
            return []
        }
        if let children = _children {
            return children
        }
        var newChildren = [XMLElement]()

        var currentChild = document.pointee.children
        while currentChild != nil {
            if currentChild?.pointee.type == XML_ELEMENT_NODE {
                newChildren.append(XMLElement(document: self, node: currentChild!))
            }
            currentChild = currentChild?.pointee.next
        }

        _children = newChildren
        return newChildren
    }

    func query(xpath: String) -> [XMLElement] {
        var results = [XMLElement]()

        guard let context = xmlXPathNewContext(_document) else {
            return results
        }
        defer { xmlXPathFreeContext(context) }

        var object: xmlXPathObjectPtr? = nil
        xpath.withCString { str in
            str.withMemoryRebound(to: UInt8.self, capacity: 1) { strp in
                object = xmlXPathEvalExpression(strp, context)
            }
        }
        guard object != nil else {
            return results
        }
        defer { xmlXPathFreeObject(object) }

        let nodeCount = object!.pointee.nodesetval.pointee.nodeNr
        for i in 0..<nodeCount {
            if let node = object!.pointee.nodesetval.pointee.nodeTab.advanced(by: Int(i)).pointee {
                results.append(XMLElement(document: self, node: node))
            }
        }

        return results
    }

    deinit {
        xmlFreeDoc(_document)
        _document = nil
    }
}

final class XMLElement {
    private var _document: XMLDocument!
    private var _node: xmlNodePtr!
    private var _name: String?
    private var _children: [XMLElement]?
    private var _attributes: [String: String]?

    init(document: XMLDocument, node: xmlNodePtr) {
        self._document = document
        self._node = node
    }

    var name: String {
        if let name = _name {
            return name
        }
        return _node.pointee.name.withMemoryRebound(to: Int8.self, capacity: 1) { ptr in
            let newName = (NSString(utf8String: ptr) ?? "") as String
            _name = newName as String
            return newName as String
        }
    }

    var attributes: [String: String] {
        if let attributes = _attributes {
            return attributes
        }
        var newAttributes = [String: String]()

        var currentAttr = _node.pointee.properties
        while currentAttr != nil {
            let name = currentAttr!.pointee.name.withMemoryRebound(to: Int8.self, capacity: 1) { ptr in
                return (NSString(utf8String: ptr) ?? "") as String
            }
            let nodeContent = xmlNodeGetContent(currentAttr?.pointee.children)
            var value: String? = nil
            if nodeContent != nil {
                value = nodeContent!.withMemoryRebound(to: Int8.self, capacity: 1) { ptr in
                    return (NSString(utf8String: ptr) ?? "") as String
                }
                xmlFree(nodeContent)
            }
            newAttributes[name] = value ?? ""
            currentAttr = currentAttr?.pointee.next
        }

        _attributes = newAttributes
        return newAttributes
    }

    var children: [XMLElement] {
        guard let node = _node else {
            return []
        }
        guard let document = _document else {
            return []
        }
        if let children = _children {
            return children
        }
        var newChildren = [XMLElement]()

        var currentChild = node.pointee.children
        while currentChild != nil {
            if currentChild?.pointee.type == XML_ELEMENT_NODE {
                newChildren.append(XMLElement(document: document, node: currentChild!))
            }
            currentChild = currentChild?.pointee.next
        }

        _children = newChildren
        return newChildren
    }

    func query(xpath: String) -> [XMLElement] {
        var results = [XMLElement]()

        guard let context = xmlXPathNewContext(_document._document) else {
            return results
        }
        defer { xmlXPathFreeContext(context) }

        var object: xmlXPathObjectPtr? = nil
        xpath.withCString { str in
            str.withMemoryRebound(to: UInt8.self, capacity: 1) { strp in
                object = xmlXPathEvalExpression(strp, context)
            }
        }
        guard object != nil else {
            return results
        }
        defer { xmlXPathFreeObject(object) }

        let nodeCount = object!.pointee.nodesetval.pointee.nodeNr
        for i in 0..<nodeCount {
            if let node = object!.pointee.nodesetval.pointee.nodeTab.advanced(by: Int(i)).pointee {
                results.append(XMLElement(document: _document, node: node))
            }
        }

        return results
    }

    deinit {
        _document = nil
        _node = nil
        _children = nil
        _attributes = nil
    }
}

private let suppress: () = {
    initGenericErrorDefaultFunc(nil)
    xmlSetStructuredErrorFunc(nil) { (data, error) in }
    xmlKeepBlanksDefault(0)
}()

func ensureLibXMLErrorHandlingSuppressed() {
    suppress
}
