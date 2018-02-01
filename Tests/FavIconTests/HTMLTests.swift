//
//  HTMLTests.swift
//  FavIcon-macOSTests
//
//  Created by Leon Breedt on 1/02/18.
//

import Foundation
import XCTest
@testable import FavIcon

class HTMLDocumentTests: XCTestCase {
    func testHTMLFragment() {
        let document = HTMLDocument(string: "<html></html>")
        let elements = document.query(xpath: "/html")

        XCTAssertEqual(1, elements.count)
        XCTAssertEqual("html", elements[0].name)
        XCTAssertEqual(0, elements[0].children.count)
    }

    func testHTMLElementAttributes() {
        let document = HTMLDocument(string: "<html lang='en-us'></html>")

        XCTAssertEqual(1, document.children.count)

        let html = document.children[0]

        XCTAssertEqual(1, html.attributes.count)
        XCTAssertEqual("en-us", html.attributes["lang"])
    }

    func testHTMLElementsShouldNotBeCreatedMultipleTimes() {
        let document = HTMLDocument(string: "<html><head></head><body></body></html>")

        let children1 = document.children
        let children2 = document.children

        XCTAssertTrue(children1[0] === children2[0])
    }

    func testHTMLElementWithChildren() {
        let document = HTMLDocument(string: "<html><body><p id='test'>some text</p></html>")
        let elements = document.query(xpath: "/html/body")

        XCTAssertEqual(1, elements.count)
        XCTAssertEqual("body", elements[0].name)
        XCTAssertEqual(1, elements[0].children.count)
        XCTAssertEqual("p", elements[0].children[0].name)
    }

    func testMalformedHTML() {
        let document = HTMLDocument(string: "<html <body><p id='test'>some text</p></body>")
        let elements = document.query(xpath: "//body")

        XCTAssertEqual(1, elements.count)
        XCTAssertEqual("body", elements[0].name)
        XCTAssertEqual(1, elements[0].children.count)
        XCTAssertEqual("p", elements[0].children[0].name)
    }

    func testGoogleHTML() {
        // swiftlint:disable line_length
        let document = HTMLDocument(string: "<!doctype html><html lang=\"en-NZ\"><head><meta content=\"/images/branding/googleg/1x/googleg_standard_color_128dp.png\" itemprop=\"image\"><link href=\"/images/branding/product/ico/googleg_lodp.ico\" rel=\"shortcut icon\">")
        // swiftlint:enable line_length
        let links = document.query(xpath: "/html/head/link")

        XCTAssertEqual(1, links.count)
        XCTAssertEqual("link", links[0].name)
        XCTAssertEqual(2, links[0].attributes.count)
        XCTAssertEqual("/images/branding/product/ico/googleg_lodp.ico", links[0].attributes["href"])
        XCTAssertEqual("shortcut icon", links[0].attributes["rel"])
    }
}

