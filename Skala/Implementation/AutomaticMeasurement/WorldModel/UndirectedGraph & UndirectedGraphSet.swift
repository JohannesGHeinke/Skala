//
//  UndirectedGraph.swift
//  Ruler
//
//  Created by Johannes Heinke Business on 28.09.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation

internal protocol hasUniqueKey {
    var key: Int { get }
}

extension BTree {
    internal func search(for key: Key) -> Value? {
        return self.root.search(for: key)
    }
}

internal final class UndirectedGraph<BranchValue: hasUniqueKey, EdgeValue: hasUniqueKey>: CustomStringConvertible {
    
    fileprivate typealias Branch = (value: BranchValue, connections: [(index: Int, first: Bool)])
    fileprivate typealias Edge = (value: EdgeValue, first: Int, second: Int)
    
    private final var branchesTree = BTree<Int, (listIndex: Int, UnsafeMutablePointer<Branch>)>.init()
    private final var branchesList = Array<UnsafeMutablePointer<Branch>>.init()
    
    private final var edgesTree = BTree<Int, (listIndex: Int, UnsafeMutablePointer<Edge>)>.init()
    private final var edgesList = Array<UnsafeMutablePointer<Edge>>.init()
    
    private final var mutationCount = 0
    
    deinit {
        self.branchesList.removeAll()
        self.branchesTree.removeAll()
        self.edgesList.removeAll()
        self.edgesTree.removeAll()
    }
    
    internal final var description: String {
        let branchesString =  { () -> String in 
            let result = self.branchesList.reduce(" [") { (tmp, branch) -> String in
                return tmp + "\n\t\(branch.pointee.value.key),"
            }
            if result.count > 1 {
                return result.dropLast() + "]"
            }
            return result + "]"
        }()
        let branchesTreeString = self.branchesTree.reduce("") { (tmp, arg) -> String in
            let (_, arg1) = arg
            let (listIndex, pointer) = arg1
            return tmp + "(\(listIndex), \(pointer.pointee.value.key)), "
        }
        return "UndirectedGraph Start ==>\n\t --> Branches \(branchesString)\n\t \(branchesTreeString)\n\t Connections:" + self.edgesList.reduce("", { (tmp, edge) -> String in
            return tmp + "\n\t # \(edge.pointee.first) to \(edge.pointee.second)"
        }) + "\nUndirectedGraph End ==>"
    }
    
    internal static func singleton(from startBranch: BranchValue, with edgeValue: EdgeValue, to endBranch: BranchValue) -> UndirectedGraph<BranchValue, EdgeValue> {
        let newGraph = UndirectedGraph<BranchValue, EdgeValue>.init()
        guard startBranch.key != endBranch.key else {
            let edge = (edgeValue, 0, 0)
            let edgePointer = UnsafeMutablePointer<Edge>.allocate(capacity: 1)
            edgePointer.initialize(to: edge)
            newGraph.edgesList.append(edgePointer)
            newGraph.edgesTree.insert((edgeValue.key, (0, edgePointer)))
            
            let concreteStartBranch = (value: startBranch, [(index: 0, first: true), (index: 0, first: false)])
            let startBranchPointer = UnsafeMutablePointer<Branch>.allocate(capacity: 1)
            startBranchPointer.initialize(to: concreteStartBranch)
            newGraph.branchesList.append(startBranchPointer)
            newGraph.branchesTree.insert((startBranch.key, (0, startBranchPointer)))
            return newGraph
        }
        let edge = (edgeValue, 0, 1)
        let edgePointer = UnsafeMutablePointer<Edge>.allocate(capacity: 1)
        edgePointer.initialize(to: edge)
        newGraph.edgesList.append(edgePointer)
        newGraph.edgesTree.insert((edgeValue.key, (0, edgePointer)))
        
        let concreteStartBranch = (value: startBranch, [(index: 0, first: true)])
        let startBranchPointer = UnsafeMutablePointer<Branch>.allocate(capacity: 1)
        startBranchPointer.initialize(to: concreteStartBranch)
        let concreteEndBranch = (value: endBranch, [(index: 0, first: false)])
        let endBranchPointer = UnsafeMutablePointer<Branch>.allocate(capacity: 1)
        endBranchPointer.initialize(to: concreteEndBranch)
        newGraph.branchesList.append(contentsOf: [startBranchPointer, endBranchPointer])
        newGraph.branchesTree.insert((startBranch.key, (0, startBranchPointer)))
        newGraph.branchesTree.insert((endBranch.key, (1, endBranchPointer)))
        
        newGraph.mutationCount = 1
        return newGraph
    }
    
    internal enum InsertionResult {
        case noAnkerFound
        case startAnkerFound(Index)
        case endAnkerFound(Index)
        case edgeInserted
        case selfEdgeInserted
    }
    
    internal struct Index {
        private let value: Int
        
        fileprivate init(value: Int) {
            self.value = value
        }
    }
    
    fileprivate final func forceFormUnion(from startBranch: BranchValue, with edgeValue: EdgeValue, to endBranch: BranchValue, in undirectedGraph: UndirectedGraph<BranchValue, EdgeValue>) {
        undirectedGraph.branchesList.forEach { (branch) in
            branch.pointee.connections = branch.pointee.connections.map({ (index, first) -> (index: Int, first: Bool) in
                return (index + self.edgesList.count, first)
            })
        }
        
        undirectedGraph.edgesList.forEach { (edge) in
            edge.pointee.first = edge.pointee.first + self.branchesList.count
            edge.pointee.second = edge.pointee.second + self.branchesList.count
        }
        
        for index in 0..<undirectedGraph.branchesTree.count {
            let currentTreeValue = undirectedGraph.branchesTree.element(atOffset: index).1
            _ = undirectedGraph.branchesTree.setValue(atOffset: index, to: (currentTreeValue.listIndex + self.branchesList.count, currentTreeValue.1))
        }
        for index in 0..<undirectedGraph.edgesTree.count {
            let currentTreeValue = undirectedGraph.edgesTree.element(atOffset: index).1
            _ = undirectedGraph.edgesTree.setValue(atOffset: index, to: (currentTreeValue.listIndex + self.edgesList.count, currentTreeValue.1))
        }
        
        self.branchesTree = self.branchesTree.union(undirectedGraph.branchesTree, by: .groupingMatches)
        self.edgesTree = self.edgesTree.union(undirectedGraph.edgesTree, by: .groupingMatches)
        self.branchesList.append(contentsOf: undirectedGraph.branchesList)
        self.edgesList.append(contentsOf: undirectedGraph.edgesList)
        
        //: Insert the connection
        _ = self.insertConnection(from: startBranch, with: edgeValue, to: endBranch)
    }
    
    internal final func insertConnection(from startBranch: BranchValue, with edgeValue: EdgeValue, to endBranch: BranchValue) -> InsertionResult {
        guard startBranch.key != endBranch.key else {
            guard let knownIndex = self.branchesTree.search(for: startBranch.key)?.listIndex else {
                return .noAnkerFound
            }
            let edgeIndex = self.edgesList.count
            let edge = (edgeValue, knownIndex, knownIndex)
            let edgePointer = UnsafeMutablePointer<Edge>.allocate(capacity: 1)
            edgePointer.initialize(to: edge)
            self.edgesList.append(edgePointer)
            self.edgesTree.insert((edgeValue.key, (edgeIndex, edgePointer)))
            
            self.branchesList[knownIndex].pointee.connections.append((edgeIndex, true))
            self.branchesList[knownIndex].pointee.connections.append((edgeIndex, false))
            return .selfEdgeInserted
        }
        if let knownStartIndex = self.branchesTree.search(for: startBranch.key)?.listIndex {
            self.mutationCount += 1
            guard let knownEndIndex = self.branchesTree.search(for: endBranch.key)?.listIndex else {
                let endBranchIndex = self.branchesList.count
                let edge = (edgeValue, knownStartIndex, endBranchIndex)
                let edgeIndex = self.edgesList.count
                let edgePointer = UnsafeMutablePointer<Edge>.allocate(capacity: 1)
                edgePointer.initialize(to: edge)
                self.edgesList.append(edgePointer)
                self.edgesTree.insert((edgeValue.key, (edgeIndex, edgePointer)))
                
                let concreteEndBranch = (value: endBranch, [(index: edgeIndex, first: false)])
                let endBranchPointer = UnsafeMutablePointer<Branch>.allocate(capacity: 1)
                endBranchPointer.initialize(to: concreteEndBranch)
                self.branchesList.append(endBranchPointer)
                self.branchesTree.insert((endBranch.key, (endBranchIndex, endBranchPointer)))
                
                self.branchesList[knownStartIndex].pointee.connections.append((edgeIndex, true))
                return .startAnkerFound(Index.init(value: knownStartIndex))
            }
            let edgeIndex = self.edgesList.count
            let edge = (edgeValue, knownStartIndex, knownEndIndex)
            let edgePointer = UnsafeMutablePointer<Edge>.allocate(capacity: 1)
            edgePointer.initialize(to: edge)
            self.edgesList.append(edgePointer)
            self.edgesTree.insert((edgeValue.key, (edgeIndex, edgePointer)))
            
            self.branchesList[knownStartIndex].pointee.connections.append((edgeIndex, true))
            self.branchesList[knownEndIndex].pointee.connections.append((edgeIndex, false))
            return .edgeInserted
        } else {
            guard let knownEndIndex = self.branchesTree.search(for: endBranch.key)?.listIndex else {
                return .noAnkerFound
            }
            self.mutationCount += 1
            let startBranchIndex = self.branchesList.count
            let edge = (edgeValue, startBranchIndex, knownEndIndex)
            let edgeIndex = self.edgesList.count
            let edgePointer = UnsafeMutablePointer<Edge>.allocate(capacity: 1)
            edgePointer.initialize(to: edge)
            self.edgesList.append(edgePointer)
            self.edgesTree.insert((endBranch.key, (edgeIndex, edgePointer)))
            
            let concreteStartBranch = (value: startBranch, [(index: edgeIndex, first: true)])
            let startBranchPointer = UnsafeMutablePointer<Branch>.allocate(capacity: 1)
            startBranchPointer.initialize(to: concreteStartBranch)
            self.branchesList.append(startBranchPointer)
            self.branchesTree.insert((startBranch.key, (startBranchIndex, startBranchPointer)))
            
            self.branchesList[knownEndIndex].pointee.connections.append((edgeIndex, false))
            return .endAnkerFound(Index.init(value: knownEndIndex))
        }
    }
    
    internal final func createWorker(for branch: BranchValue) -> BranchWorker? {
        guard let concreteBranch = self.branchesTree.search(for: branch.key)?.1 else {
            return nil
        }
        return BranchWorker.init(graph: self, _branch: concreteBranch, mutationCount: self.mutationCount)
    }
    
    internal struct BranchWorker {
        fileprivate let graph: UndirectedGraph<BranchValue, EdgeValue>
        fileprivate let _branch: UnsafeMutablePointer<Branch>
        fileprivate let mutationCount: Int
        
        internal var branch: BranchValue {
            return self._branch.pointee.value
        }
        
        internal var isValid: Bool {
            return self.mutationCount == self.graph.mutationCount
        }
        
        internal func replaceConnections(_ replacing: (_ startBranch: BranchValue, _ edge: EdgeValue, _ endBranch: BranchValue) -> EdgeValue) {
            self._branch.pointee.connections.forEach { (index, first) in
                let newEdge: EdgeValue
                if first {
                    newEdge = replacing(self._branch.pointee.value, self.graph.edgesList[index].pointee.value,
                                        self.graph.branchesList[self.graph.edgesList[index].pointee.second].pointee.value)
                } else {
                    newEdge = replacing(self._branch.pointee.value, self.graph.edgesList[index].pointee.value,
                                        self.graph.branchesList[self.graph.edgesList[index].pointee.first].pointee.value)
                }
                self.graph.edgesList[index].pointee.value = newEdge
            }
        }
        
        internal func replace(with newValue: BranchValue) -> BranchValue {
            let oldValue = self._branch.pointee.value
            self._branch.pointee.value = newValue
            return oldValue
        }
        
        internal var endingBranches: [BranchValue] {
            return self._branch.pointee.connections.reduce([BranchValue].init(), { (tmp, arg1) -> [BranchValue] in
                let (index, first) = arg1
                guard first else {
                    return tmp + [self.graph.branchesList[self.graph.edgesList[index].pointee.first].pointee.value]
                }
                return tmp + [self.graph.branchesList[self.graph.edgesList[index].pointee.second].pointee.value]
            })
        }
        
        internal var connections: [EdgeValue] {
            return self._branch.pointee.connections.reduce([EdgeValue].init(), { (tmp, arg1)  -> [EdgeValue] in
                let (index, _) = arg1
                return tmp + [self.graph.edgesList[index].pointee.value]
            })
        }
        
        internal var lines: [(edge: EdgeValue, endBranch: BranchValue)] {
            return self._branch.pointee.connections.reduce([(edge: EdgeValue, endBranch: BranchValue)].init(), { (tmp, arg1) -> [(edge: EdgeValue, endBranch: BranchValue)] in
                let (index, first) = arg1
                let candidate: UnsafeMutablePointer<Branch>
                if first {
                    candidate = self.graph.branchesList[self.graph.edgesList[index].pointee.second]
                } else {
                    candidate = self.graph.branchesList[self.graph.edgesList[index].pointee.first]
                }
                guard candidate.pointee.connections.count == 1 else {
                    return tmp
                }
                return tmp + [(self.graph.edgesList[index].pointee.value, candidate.pointee.value)]
            })
        }
        
        internal var triangles: [(firstEdge: EdgeValue, firstBranch: BranchValue, secondEdge: EdgeValue, secondBranch: BranchValue, thirdEdge: EdgeValue)] {
            let endingBranches = self._branch.pointee.connections.reduce([(connection: EdgeValue, Branch)].init(), { (tmp, arg1) -> [(connection: EdgeValue, Branch)] in
                let (index, first) = arg1
                guard first else {
                    return tmp + [(self.graph.edgesList[index].pointee.value, self.graph.branchesList[self.graph.edgesList[index].pointee.first].pointee)]
                }
                return tmp + [(self.graph.edgesList[index].pointee.value, self.graph.branchesList[self.graph.edgesList[index].pointee.second].pointee)]
            })
            return endingBranches.reduce((triangles: [(firstEdge: EdgeValue, firstBranch: BranchValue, secondEdge: EdgeValue, secondBranch: BranchValue, thirdEdge: EdgeValue)].init()
                , targets: endingBranches), { (tmp, arg1) -> (triangles: [(firstEdge: EdgeValue, firstBranch: BranchValue, secondEdge: EdgeValue, secondBranch: BranchValue, thirdEdge: EdgeValue)], targets: [(connection: EdgeValue, Branch)]) in
                    let (firstConnection, currentBranch) = arg1
                    let members = tmp.targets.dropFirst().reduce([(firstEdge: EdgeValue, firstBranch: BranchValue, secondEdge: EdgeValue, secondBranch: BranchValue, thirdEdge: EdgeValue)].init(), { (tmp2, arg2) -> [(firstEdge: EdgeValue, firstBranch: BranchValue, secondEdge: EdgeValue, secondBranch: BranchValue, thirdEdge: EdgeValue)] in
                        let (secondConnection, secondBranch) = arg2
                        guard let thirdConnectionIndex = secondBranch.connections.first(where: { (index, _) -> Bool in
                            return currentBranch.connections.contains(where: { (index2, _) -> Bool in
                                return index == index2
                            })
                        }) else {
                            return tmp2
                        }
                        return tmp2 + [(firstEdge: firstConnection, firstBranch: currentBranch.value, secondEdge: secondConnection, secondBranch: secondBranch.value, thirdEdge: self.graph.edgesList[thirdConnectionIndex.index].pointee.value)]
                    })
                    
                    return (triangles: tmp.triangles + members, targets: Array(tmp.targets.dropFirst()))
            }).triangles
        }
    }
}

internal struct UndirectedGraphSet<BranchValue: hasUniqueKey, EdgeValue: hasUniqueKey>: CustomStringConvertible {
    
    private var graphs = ContiguousArray<UndirectedGraph<BranchValue, EdgeValue>>.init()
    private var branchNodeTree = BTree<Int, Int>.init()
    private var edgeNodeTree = BTree<Int, Int>.init()
    
    internal var description: String {
        return "\nUndirectedGraphSet Start ==> " + self.graphs.reduce("", { (tmp, graph) -> String in
            return tmp + "\n\(graph)"
        }) + "\nUndirectedGraphSet End ==>"
    }
    
    internal subscript(index: Int) -> UndirectedGraph<BranchValue, EdgeValue> {
        return self.graphs[index]
    }
    
    internal var count: Int {
        return self.graphs.count
    }
    
    internal mutating func insertConnection(from startNode: BranchValue, with edgeNode: EdgeValue, to endNode: BranchValue) {
        
        if let possibleStartNodeGraph = self.branchNodeTree.search(for: startNode.key) {
            guard let possibleEndNodeGraph = self.branchNodeTree.search(for: endNode.key) else {
                _ = self.graphs[possibleStartNodeGraph].insertConnection(from: startNode, with: edgeNode, to: endNode)
                self.branchNodeTree.insert((endNode.key, possibleStartNodeGraph))
                self.edgeNodeTree.insert((edgeNode.key, possibleStartNodeGraph))
                return
            }
            guard possibleEndNodeGraph != possibleStartNodeGraph else {
                _ = self.graphs[possibleStartNodeGraph].insertConnection(from: startNode, with: edgeNode, to: endNode)
                self.edgeNodeTree.insert((edgeNode.key, possibleStartNodeGraph))
                return
            }
            //: Form Union
            self.graphs[possibleStartNodeGraph].forceFormUnion(from: startNode, with: edgeNode, to: endNode, in: self.graphs[possibleEndNodeGraph])
            self.graphs.remove(at: possibleEndNodeGraph)
            for index in 0..<self.branchNodeTree.count {
                let currentValue = self.branchNodeTree.element(atOffset: index)
                switch currentValue.1 {
                case let value where value == possibleEndNodeGraph:
                    _ = self.branchNodeTree.setValue(atOffset: index, to: possibleStartNodeGraph)
                case let value where value > possibleEndNodeGraph:
                    _ = self.branchNodeTree.setValue(atOffset: index, to: currentValue.1 - 1)
                default:
                    continue
                }
            }
            for index in 0..<self.edgeNodeTree.count {
                let currentValue = self.edgeNodeTree.element(atOffset: index)
                switch currentValue.1 {
                case let value where value == possibleEndNodeGraph:
                    _ = self.edgeNodeTree.setValue(atOffset: index, to: possibleStartNodeGraph)
                case let value where value > possibleEndNodeGraph:
                    _ = self.edgeNodeTree.setValue(atOffset: index, to: currentValue.1 - 1)
                default:
                    continue
                }
            }
            self.edgeNodeTree.insert((edgeNode.key, possibleStartNodeGraph))
        } else {
            guard let possibleEndNodeGraph = self.branchNodeTree.search(for: endNode.key) else {
                let graphIndex = self.graphs.count
                self.branchNodeTree.insert((startNode.key, graphIndex))
                self.branchNodeTree.insert((endNode.key, graphIndex))
                self.edgeNodeTree.insert((edgeNode.key, graphIndex))
                self.graphs.append(UndirectedGraph<BranchValue, EdgeValue>.singleton(from: startNode, with: edgeNode, to: endNode))
                return
            }
            _ = self.graphs[possibleEndNodeGraph].insertConnection(from: endNode, with: edgeNode, to: startNode)
            self.branchNodeTree.insert((startNode.key, possibleEndNodeGraph))
            self.edgeNodeTree.insert((edgeNode.key, possibleEndNodeGraph))
        }
    }
    
    internal nonmutating func getWorker(for branch: BranchValue) -> UndirectedGraph<BranchValue, EdgeValue>.BranchWorker? {
        guard let graphIndex = self.branchNodeTree.search(for: branch.key)
            , let worker = self.graphs[graphIndex].createWorker(for: branch) else {
            return nil
        }
        return worker
    }
}
