//
//  Gradient.swift
//  DLVM
//
//  Created by Richard Wei on 12/20/16.
//
//

open class GradientPass : ExtensionGenerationPass {
    public static let extensionType: BasicBlock.ExtensionType = .backpropagation
    open var body: BasicBlock

    public required init(body: BasicBlock) {
        self.body = body
    }

    open func run() -> PassResult {
        let result = PassResult(changed: false)
        return result
    }
}
