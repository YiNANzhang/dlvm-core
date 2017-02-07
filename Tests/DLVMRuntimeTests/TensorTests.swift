//
//  TensorTests.swift
//  DLVM
//
//  Created by Richard Wei on 2/5/17.
//
//

import XCTest
import DLVM
@testable import DLVMRuntime

class TensorTests: XCTestCase {

    func testIndexCalculation() {
        let shape: TensorShape = [1, 2, 3] // 6
        let index: TensorIndex = [0, 0, 1]
        let contIndex = index.contiguousIndex(in: shape)
        XCTAssertEqual(contIndex, 1)
    }

    func testAddressing() {
        let shape: TensorShape = [1, 2, 3]
        let tensor = Tensor<Int>(shape: shape, repeating: 0)
        XCTAssertEqual(tensor[].shape, shape)
        XCTAssertEqual(tensor[0].shape, shape.dropFirst())
        XCTAssertEqual(tensor[0, 1].shape, shape.dropFirst(2))
        XCTAssertEqual(tensor[0][1].shape, shape.dropFirst(2))
        XCTAssertEqual(tensor[0, 1, 2].shape, .scalar)
        XCTAssertEqual(tensor[0][1][2].shape, .scalar)
        for subTensor in tensor[0] {
            XCTAssertEqual(subTensor.shape, shape.dropFirst(2))
            XCTAssertEqual(subTensor.items, [0, 0, 0])
        }
    }

    func testInit() {
        let scalar = Tensor<Int>(shape: [], items: [1])
        XCTAssertEqual(scalar.shape, .scalar)

        let highScalar = scalar.reshaped(as: [1, 1, 1])!
        XCTAssertTrue(highScalar.shape ~ .scalar)

        var tensor = Tensor<Int>(elementShape: [4, 3])
        tensor.append(contentsOf: Tensor<Int>(shape: [2, 4, 3],
                                              itemsIncreasingFrom: 0))
        tensor.append(contentsOf: Tensor<Int>(shape: [3, 4, 3],
                                              itemsIncreasingFrom: 0))
        XCTAssertEqual(tensor.items, ArraySlice((0..<24).map{$0} + (0..<36).map{$0}))

        let scalars = Tensor<Int>(scalarElementsIn: 0..<10)
        XCTAssertEqual(scalars.items, ArraySlice((0..<10).map{$0}))
        for scalar in scalars {
            XCTAssertEqual(scalar.shape, .scalar)
        }
    }

    func testEquality() {
        let highTensor = Tensor<Int>(shape: [1, 4, 3], itemsIncreasingFrom: 0)
        let lowTensor = Tensor<Int>(shape: [4, 3], itemsIncreasingFrom: 0)
        XCTAssertTrue(highTensor.itemsEqual(lowTensor))
        XCTAssertFalse(highTensor.elementsEqual(lowTensor))
        XCTAssertTrue(highTensor.shape ~ lowTensor.shape)
        XCTAssertTrue(highTensor.isSimilar(to: lowTensor))
        XCTAssertFalse(highTensor.isIsomorphic(to: lowTensor))

        let scalar = Tensor<Int>(shape: [], items: [1])
        let highScalar = Tensor<Int>(shape: [1, 1, 1], items: [100])
        XCTAssertTrue(highScalar.isSimilar(to: scalar))
        XCTAssertTrue(highScalar[0].isSimilar(to: scalar))
        XCTAssertFalse(highScalar.isIsomorphic(to: scalar))
        XCTAssertFalse(highScalar[0].isIsomorphic(to: scalar))
    }

    static var allTests : [(String, (TensorTests) -> () throws -> Void)] {
        return [
        ]
    }

}
