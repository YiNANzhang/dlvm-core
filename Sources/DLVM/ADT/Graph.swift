//
//  Graph.swift
//  DLVM
//
//  Copyright 2016-2017 Richard Wei.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

/// Graph node that defines its successors
public protocol ForwardGraphNode {
    associatedtype SuccessorCollection: Collection where SuccessorCollection.Element == Self
    var successors: SuccessorCollection { get }
}

/// Graph node that defines its predecessors
public protocol BackwardGraphNode {
    associatedtype PredecessorCollection: Collection where PredecessorCollection.Element == Self
    var predecessors: PredecessorCollection { get }
}

// MARK: - Property predicates
public extension ForwardGraphNode {
    var isLeaf: Bool {
        return successors.isEmpty
    }
}

// MARK: - Property predicates
public extension BackwardGraphNode {
    var isSource: Bool {
        return predecessors.isEmpty
    }
}

/// Graph node that defines both it's succssors and predecessors
public typealias BidirectionalGraphNode = ForwardGraphNode & BackwardGraphNode

/// Transpose of a bidirectional graph node
public struct TransposeGraphNode<Base : BidirectionalGraphNode> : BidirectionalGraphNode {
    public let base: Base

    public init(base: Base) {
        self.base = base
    }

    public var successors: [TransposeGraphNode<Base>] {
        return base.predecessors.map{$0.transpose}
    }

    public var predecessors: [TransposeGraphNode<Base>] {
        return base.successors.map{$0.transpose}
    }
}

// MARK: - Transpose
public extension ForwardGraphNode where Self : BackwardGraphNode {
    var transpose: TransposeGraphNode<Self> {
        return TransposeGraphNode(base: self)
    }
}

/// Graph representation storing all forward and backward edges
public protocol BidirectionalEdgeSet {
    associatedtype Node : HashableByReference
    func predecessors(of node: Node) -> ObjectSet<Node>
    func successors(of node: Node) -> ObjectSet<Node>
}

// MARK: - Transpose
extension BidirectionalEdgeSet {
    public var transpose: TransposeEdgeSet<Self> {
        return TransposeEdgeSet(base: self)
    }
}

/// Transpose edge set
public struct TransposeEdgeSet<Base : BidirectionalEdgeSet> : BidirectionalEdgeSet {

    public typealias Node = Base.Node

    public let base: Base

    public func predecessors(of node: Node) -> ObjectSet<Node> {
        return base.successors(of: node)
    }

    public func successors(of node: Node) -> ObjectSet<Node> {
        return base.predecessors(of: node)
    }

}

/// Directed graph
public struct DirectedGraph<Node : HashableByReference> : BidirectionalEdgeSet {
    public struct Entry {
        public var successors: ObjectSet<Node> = []
        public var predecessors: ObjectSet<Node> = []
    }

    fileprivate var entries: [Node : Entry] = [:]
    public init() {}
}

// MARK: - Mutation
public extension DirectedGraph {
    /// Insert node to the graph
    mutating func insertNode(_ node: Node) {
        if contains(node) { return }
        entries[node] = Entry()
    }

    /// Insert edge to the graph
    mutating func insertEdge(from src: Node, to dest: Node) {
        insertNode(src)
        entries[src]!.successors.insert(dest)
        insertNode(dest)
        entries[dest]!.predecessors.insert(src)
    }

    /// Remove everything from the graph
    mutating func removeAll() {
        entries.removeAll()
    }

    /// Predecessors of the node
    func predecessors(of node: Node) -> ObjectSet<Node> {
        return self[node].predecessors
    }

    /// Successors of the node
    func successors(of node: Node) -> ObjectSet<Node> {
        return self[node].successors
    }

    /// Returns the graph node entry for the node
    subscript(node: Node) -> Entry {
        guard let entry = entries[node] else {
            preconditionFailure("Node not in the graph")
        }
        return entry
    }

    /// Does the graph contain this node?
    func contains(_ node: Node) -> Bool {
        return entries.keys.contains(node)
    }

    /// Does the graph contain this edge?
    func containsEdge(from src: Node, to dest: Node) -> Bool {
        return successors(of: src).contains(dest)
    }

    /// Does this node immediately precede the other?
    func immediatelyPrecedes(_ firstNode: Node, _ secondNode: Node) -> Bool {
        return predecessors(of: secondNode).contains(firstNode)
    }

    /// Does this node immediately succeed the other?
    func immediatelySucceeds(_ firstNode: Node, _ secondNode: Node) -> Bool {
        return successors(of: secondNode).contains(secondNode)
    }

    /// Does this node succeed the other?
    func precedes(_ firstNode: Node, _ secondNode: Node) -> Bool {
        guard contains(firstNode) else { return false }
        let secondPreds = predecessors(of: secondNode)
        return secondPreds.contains(firstNode)
    //        || secondPreds.contains(where: { precedes($0, secondNode) })
    }

    /// Does this node succeed the other?
    func succeeds(_ firstNode: Node, _ secondNode: Node) -> Bool {
        guard contains(secondNode) else { return false }
        let secondSuccs = successors(of: secondNode)
        return secondSuccs.contains(firstNode)
    //        || secondSuccs.contains(where: { succeeds(firstNode, $0) })
    }

    /// Is this node a source?
    func isSource(_ node: Node) -> Bool {
        return predecessors(of: node).isEmpty
    }

    /// Is this node a leaf?
    func isLeaf(_ node: Node) -> Bool {
        return successors(of: node).isEmpty
    }
    
}

/// - TODO: Fix SR-4956 and restore these as initializers
public extension DirectedGraph where Node : ForwardGraphNode {

    static func bag<S : Sequence>(of nodes: S) -> DirectedGraph where S.Element == Node {
        var graph = self.init()
        for node in nodes {
            for succ in node.successors {
                graph.insertEdge(from: node, to: succ)
            }
        }
        return graph
    }

    static func graph<S : Sequence>(fromSources sources: S) -> DirectedGraph where S.Element == Node {
        var graph = self.init()
        for src in sources {
            graph.insertAll(fromSource: src)
        }
        return graph
    }

}

/// - TODO: Fix SR-4956 and restore these as initializers
public extension DirectedGraph where Node : BackwardGraphNode {

    static func bag<S : Sequence>(of nodes: S) -> DirectedGraph where S.Element == Node {
        var graph = self.init()
        for node in nodes {
            for pred in node.predecessors {
                graph.insertEdge(from: pred, to: node)
            }
        }
        return graph
    }

    static func graph<S : Sequence>(fromLeaves leaves: S) -> DirectedGraph where S.Element == Node {
        var graph = self.init()
        for leaf in leaves {
            graph.insertAll(fromLeaf: leaf)
        }
        return graph
    }
    
}

// MARK: - Initializer from source nodes that store successors
public extension DirectedGraph where Node : ForwardGraphNode {

    /// Recursively insert all vertices and edges to the graph by traversing
    /// forward from a source vertex
    ///
    /// - Parameter node: source vertex
    mutating func insertAll(fromSource node: Node) {
        var visited: ObjectSet<Node> = []
        func insertAll(fromSource node: Node) {
            for succ in node.successors where !visited.contains(succ) {
                visited.insert(succ)
                insertEdge(from: node, to: succ)
                insertAll(fromSource: succ)
            }
        }
        insertAll(fromSource: node)
    }
}

// MARK: - Initializer from leaves that store predecessors
public extension DirectedGraph where Node : BackwardGraphNode {

    /// Recursively insert all vertices and edges to the graph by traversing 
    /// backward from a leaf vertex
    ///
    /// - Parameter node: leaf vertex
    mutating func insertAll(fromLeaf node: Node) {
        var visited: ObjectSet<Node> = []
        func insertAll(fromLeaf node: Node) {
            for pred in node.predecessors {
                visited.insert(pred)
                insertEdge(from: node, to: node)
                insertAll(fromLeaf: pred)
            }
        }
        insertAll(fromLeaf: node)
    }

}
