//
//  NSTree.m
//  NSTree
//
//  Created by . Carlin on 10/16/13.
//  Copyright (c) 2013 Carlin Creations. All rights reserved.
//

#import "NSTree.h"

#define DEFAULT_NODE_CAPACITY 3 // Must be > 2, or can't split branches properly

#pragma mark - NSTreeNode

@implementation NSTreeNode

- (id)init
{
    self = [super init];
    if (self) {
        _data = [NSMutableArray new];
        _children = [NSMutableArray new]; 
    }
    return self;
}

/** @brief Initialize with parent node */
- (id)initWithParent:(NSTreeNode *)parent
{
    self = [super init];
    if (self) {
        _parent = parent;
        _data = [NSMutableArray new];
        _children = [NSMutableArray new];  
    }
    return self;
}

/** @brief Get index of node in children array */
- (NSUInteger)indexOfChildNode:(NSTreeNode *)child
{
    return [self.children indexOfObject:child];
    
    // Binary search method
//    [self.children indexOfObject:child 
//                          inSortedRange:NSMakeRange(0, self.children.count) 
//                                options:NSBinarySearchingFirstEqual
//                        usingComparator:^NSComparisonResult(id obj1, id obj2) {
//                            NSTreeNode *n1 = (NSTreeNode *)obj1;
//                            NSTreeNode *n2 = (NSTreeNode *)obj2; 
//                            if (n1 == n2) {
//                                return NSOrderedSame;
//                            } else {
//                                return [n1.data[0] compare:n2.data[0]];
//                            } 
//                        }];
}

/** @brief Get index of object in data array */
- (NSUInteger)indexOfDataObject:(id)object
{
    return [self.data indexOfObject:object 
                      inSortedRange:NSMakeRange(0, self.data.count) 
                            options:NSBinarySearchingFirstEqual
                    usingComparator:^NSComparisonResult(id obj1, id obj2) {
                        return [obj1 compare:obj2];
                    }];
}

- (NSString *)printTree
{
    return [self printTreeNode:self indent:1];
}

- (NSString *)printTreeNode:(NSTreeNode *)node indent:(int)indent
{
    // Build indent
    NSMutableString *padding = [NSMutableString new];
    for (int i = 0; i < indent; ++i) {
        [padding appendString:@"\t"];
    }
    
    // Build string
    NSMutableString *string = [[node description] mutableCopy];
    for (NSTreeNode *child in node.children) {
        [string appendString:[NSString stringWithFormat:@"\n%@%@", 
            padding, [self printTreeNode:child indent:indent + 1]]];
    }
    
    return string;
}

- (NSString *)description 
{
    return [[self.data valueForKey:@"description"] componentsJoinedByString:@", "];
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] alloc] init];
    
    if (copy) {
        [copy setData:[self.data copyWithZone:zone]]; 
        [copy setChildren:[self.children copyWithZone:zone]];  
    }
    
    return copy;
}

@end


#pragma mark - NSTree

@interface NSTree()
    @property (nonatomic, strong) NSTreeNode *root;
    @property (nonatomic, assign) int nodeCapacity;
    @property (nonatomic, assign) int nodeMinimum;
    @property (nonatomic, assign, readwrite) int count;
@end


@implementation NSTree


#pragma mark - Constructors

- (id)init
{
    self = [super init];
    if (self) {
        _nodeCapacity = DEFAULT_NODE_CAPACITY;
        _nodeMinimum = _nodeCapacity / 2;
        _root = [NSTreeNode new];
    }
    return self;
}

/** @brief Create tree with a certain number of allowable children */
- (id)initWithNodeCapacity:(int)nodeCapacity
{
    self = [super init];
    if (self) {
        _nodeCapacity = MAX(nodeCapacity, DEFAULT_NODE_CAPACITY);
        _nodeMinimum = _nodeCapacity / 2; 
        _root = [NSTreeNode new]; 
    }
    return self;
}

/** @brief Create tree with a certain number of allowable children using the given array of objects as its base data */
- (id)initWithNodeCapacity:(int)nodeCapacity withObjects:(NSArray *)data
{
    self = [super init];
    if (self) {
        _nodeCapacity = MAX(nodeCapacity, DEFAULT_NODE_CAPACITY);
        _nodeMinimum = _nodeCapacity / 2; 
        _root = [NSTreeNode new]; 
        
        // TODO
    }
    return self;
}

/** @brief Description when printed using NSLog */
- (NSString *)description 
{
    return [self printTree];    // Print whole tree
}


#pragma mark - Public Methods

/** @brief Add object to tree, true if successful */
- (bool)addObject:(id)object
{
    if (!object) {
        return false;
    }
    
    if ([self addObject:object withChild:nil toNode:
         [self getLeafNodeForObject:object inNode:self.root]]) {
        self.count++;
        return true;
    }
    return false;
}

/** @brief Remove object from tree, returns false if not in tree */
- (bool)removeObject:(id)object
{
    if (!object || self.root.data.count <= 0) {
        return false;
    }
    
    if ([self removeObject:object fromNode:
         [self getNodeThatContains:object inBranch:self.root]]) {
        self.count--;
        return true;
    }
    return false;
}

/** @brief Search for object in tree, returns false if not found */
- (bool)containsObject:(id)object
{
    if (!object || self.root.data.count <= 0) {
        return false;
    }
    
    return ([self getNodeThatContains:object inBranch:self.root] != nil); 
}

/** @brief Returns true if tree is empty */
- (bool)isEmpty
{
    return (self.root.data.count == 0);
}

/** @brief Returns minimum element, or nil if none */
- (id)minimum
{
    if (self.root.data.count) {
        NSTreeNode *node = [self getLeftMostNode:self.root];
        if (node.data && node.data.count) {
            return [node.data objectAtIndex:0];
        } else {
            NSLog(@"Warning! Non-root node with empty data!");
        }
    }
    
    return nil;
}

/** @brief Returns maximum element, or nil if none */
- (id)maximum
{
    if (self.root.data.count) {
        NSArray *data = [[self getRightMostNode:self.root] data];
        return [data objectAtIndex:data.count - 1]; 
    }
    
    return nil;
}

/** @brief Returns number of elements in tree */
- (int)trueCount
{
    static NSString *KEY_COUNT = @"total";
    
    if (self.root.data.count) {
        NSMutableDictionary *extra = [@{
            KEY_COUNT: [NSNumber numberWithInt:0]
        } mutableCopy];
        [self traverse:^bool(NSTreeNode *node, id data, id extra) {
                extra[KEY_COUNT] = [NSNumber
                    numberWithInteger:[extra[KEY_COUNT] intValue] + 1];
                return true;
            } extraData:extra onTree:self.root 
            withAlgorithm:NSTreeTraverseAlgorithmInorder];
        return [extra[KEY_COUNT] intValue];
    }
    
    return 0;
}

/** @brief Returns printout of the tree */
- (NSString *)printTree
{
    NSMutableString *result = [NSMutableString new];
    [self traverse:^bool(NSTreeNode *node, id data, id extra) {
            NSMutableString *padding = [NSMutableString new];
            for (NSTreeNode *parent = node.parent; parent; parent = parent.parent) {
                [padding appendString:@"\t"];
            }
            [extra appendString:[NSString stringWithFormat:@"%@%@\n", padding, data]];
            return true;
        } extraData:result onTree:self.root 
        withAlgorithm:NSTreeTraverseAlgorithmInorder];
    
    return result;
}

/** @brief Returns object at index, or nil if none / out of bounds */
- (id)objectAtIndex:(int)index
{
    if (index < 0) {
        return nil;
    }
   
    // TODO
    return nil;
}

/** @brief Traverse the tree in sorted order while executing block on every element */
- (bool)traverse:(NSTreeTraverseBlock)block extraData:(id)extra onTree:(NSTreeNode *)root withAlgorithm:(NSTreeTraverseAlgorithm)algo
{
    // Return condition
    if (!root) {
        return true;
    }
    
    // If Breadth First traversal
    if (algo == NSTreeTraverseAlgorithmBreadthFirst)
    {
        // Go through data
        for (int i = 0; i < root.data.count; ++i) {
            if (!block(root, root.data[i], extra)) {
                return false;   // If block cuts traversal short
            }
        } 
        
        // Go to next sibling node, or next level's leftmost node
        if (root.next) {
            if (![self traverse:block extraData:extra onTree:root.next withAlgorithm:algo]) {
                return false;   // If block cuts traversal short 
            }
        } 
        else  // Find next level's leftmost node
        {
            // Go to leftmost node in current level
            NSTreeNode *node = root;
            while (node.previous) {
                node = node.previous;   
            }
            
            // Start traversal on it's leftmost child
            if (node.children.count) {
                if (![self traverse:block extraData:extra onTree:node.children[0] withAlgorithm:algo]) {
                    return false;   // Traversal cut short
                }
            } else {
                NSLog(@"End of Breadth First Traversal");
                return true;
            }
        }
    }
    else    // Depth First traversal
    {
        if (algo == NSTreeTraverseAlgorithmPostorder) 
        {
            for (int i = 0; i < root.children.count; ++i) {
                if (![self traverse:block extraData:extra onTree:root.children[i] withAlgorithm:algo]) {
                    return false;   // Traversal cut short 
                }
            }
        }
      
        // Process data, note the <= count for subtree traversal
        for (int i = 0; i <= root.data.count; ++i)
        {
            // Process subtrees in order
            if (algo == NSTreeTraverseAlgorithmInorder 
                && i < root.children.count) {
                if (![self traverse:block extraData:extra onTree:root.children[i] withAlgorithm:algo]) {
                    return false;   // Traversal cut short  
                }
            }
            
            // Process data in order
            if (i < root.data.count) {
                if (!block(root, root.data[i], extra)) {
                    return false;   // Traversal cut short   
                }
            }
        }
      
        if (algo == NSTreeTraverseAlgorithmPreorder) 
        {
            for (int i = 0; i < root.children.count; ++i) {
                if (![self traverse:block extraData:extra onTree:root.children[i] withAlgorithm:algo]) {
                    return false;   // Traversal cut short    
                }
            }
        }
    }
    
    return true;    // Made it through traversal
}


#pragma mark - Tree Methods

- (bool)addObject:(id)object withChild:(NSTreeNode *)child toNode:(NSTreeNode *)node
{
    if (!object || !node) {
        return false;
    }
   
    // Find index where we should put it, and add it
    int index = [node.data indexOfObject:object 
                           inSortedRange:NSMakeRange(0, node.data.count) 
                                 options:NSBinarySearchingInsertionIndex 
                         usingComparator:^NSComparisonResult(id obj1, id obj2) {
                             return [obj1 compare:obj2];
                         }];
    [node.data insertObject:object atIndex:index];
    
    // Add child if exists, need to add right after data insertion
    if (child) 
    {
        if (index+1 > node.children.count) {
            NSLog(@"Warning! Adding child at index greater than children count for child: %@", child);
        }
        
        // Insert & change parent pointer
        [node.children insertObject:child atIndex:index+1];
        child.parent = node;
        
        // Switch up sibling pointers
        NSTreeNode *sibling = node.children[index];
        if (sibling) {
            child.next = sibling.next;
            child.previous = sibling;
            sibling.next = child;
        } 
        else    // This shouldn't happen, but check other side
        {
            NSLog(@"Warning! Checking next sibling pointer while adding child: %@", child);
            if (node.children.count < index+2) {
                sibling = node.children[index+2];
                if (sibling) {
                    child.previous = sibling.previous;
                    child.next = sibling;
                    sibling.previous = child;
                }
            }
        }
    }
    
    // Rebalance as needed
    [self rebalanceNode:node];
    
    return true; 
}

- (bool)removeObject:(id)object fromNode:(NSTreeNode *)node
{
    if (!object || !node || node.data.count <= 0) {
        return false;
    }
    
    // If leaf node, simple remove
    if (!node.children.count) 
    {
        if ([node.data containsObject:object]) 
        {
            [node.data removeObject:object];
            
            // Rebalance as needed
            [self rebalanceNode:node];  
            
            return true;
        } 
        else {    // This shouldn't happen
            NSLog(@"Warning! Removing object from node that doesn't contain the object: %@", object);
            return false;
        }
    }
    else    // Deal with replacing separator
    {
        int index = [node indexOfDataObject:object];
        if (index == NSNotFound) {
            NSLog(@"Warning! Could not find index of object for removal: %@", object);
            return false;
        }
        
        // Replace with largest value from left subtree
        NSTreeNode *child = [self getRightMostNode:node.children[index]];
        id replacementObject = child.data[child.data.count - 1];
        [node.data replaceObjectAtIndex:index withObject:replacementObject];
        [child.data removeObjectAtIndex:child.data.count - 1];
        
        // Rebalance child node if needed
        [self rebalanceNode:child];
        
        return true;
    }
}

- (NSTreeNode *)getNodeThatContains:(id)object inBranch:(NSTreeNode *)node
{
    if (!object || !node || !node.data.count) {
        return nil;
    }
    
    // Search for item in node data
    int index = [node.data indexOfObject:object 
                           inSortedRange:NSMakeRange(0, node.data.count) 
                                 options:NSBinarySearchingInsertionIndex 
                         usingComparator:^NSComparisonResult(id obj1, id obj2) {
                             return [obj1 compare:obj2];
                         }];
    
    // If within bounds of data (note the <= count due to subtree indexing)
    if (index >= 0 && index <= node.data.count) 
    {
        // Check if item is equal at index 
        if (index < node.data.count && [node.data[index] isEqual:object]) {
            return node;
        }
        
        // If subtree doesn't exist at that index
        if (index >= node.children.count) {
            return nil;
        }
        
        // Need to search subtree
        return [self getNodeThatContains:object inBranch:node.children[index]];
    } 
    
    return nil;
}

- (NSTreeNode *)getLeafNodeForObject:(id)object inNode:(NSTreeNode *)node
{
    if (!object || !node) {
        return nil;
    }
    
    // If there are children, go farther down
    if (node.children.count)
    {
        // Search for item in node data
        int index = [node.data indexOfObject:object 
                               inSortedRange:NSMakeRange(0, node.data.count) 
                                     options:NSBinarySearchingInsertionIndex 
                             usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                 return [obj1 compare:obj2];
                             }];
        
        // If within bounds of children
        if (index >= 0 && index < node.children.count) {
            return [self getLeafNodeForObject:object 
                                       inNode:node.children[index]];  
        } else {
            NSLog(@"Warning: could not find leaf node for object: %@", object);
            return nil;     // This shouldn't happen!
        }
    }
    else {  // Found the node
        return node;
    }
}

- (NSTreeNode *)getLeftMostNode:(NSTreeNode *)node
{
    while (node.children.count) {
        node = node.children[0];
    }
    
    return node;
}

- (NSTreeNode *)getRightMostNode:(NSTreeNode *)node
{
    while (node.children.count) {
        node = node.children[node.children.count-1];
    }
    
    return node;
}

- (void)rebalanceNode:(NSTreeNode *)node
{
    // If node is at capacity, need to split
    if (node.data.count >= self.nodeCapacity)
    {
        NSLog(@"Rebalance Node with Max Capacity: %@", node);
        NSLog(@"Tree Before: \n%@", [self printTree]);

        // Create right node to be efficient about removing from arrays
        NSTreeNode *newRightNode = [[NSTreeNode alloc] initWithParent:node.parent];
        int middle = node.data.count / 2;
        int childIndex = ceil(node.data.count / 2.0); 
        id object = node.data[middle];

        // Iterate through data & children from middle + 1 and add to new node
        for (int i = middle + 1; i < node.data.count; ++i) {
            [newRightNode.data addObject:node.data[i]];
        }
        for (int i = childIndex; i < node.children.count; ++i) {
            [newRightNode.children addObject:node.children[i]];
            [node.children[i] setParent:newRightNode]; 
        } 

        // Remove old items from left node, including middle item
        [node.data removeObjectsInRange:
            NSMakeRange(middle, node.data.count - middle)];

        // Remove old children from left node if exists, including middle
        if (node.children.count) {
            [node.children removeObjectsInRange:
                NSMakeRange(childIndex, node.children.count - childIndex)]; 
        }
        
        // Change sibling pointers
        newRightNode.next = node.next;
        newRightNode.previous = node;
        node.next = newRightNode;
        
        // Add to parent, if exists
        if (node.parent) {
            [self addObject:object withChild:newRightNode toNode:node.parent];
        }
        else    // Root node, need to create new root
        {
            NSTreeNode *newRootNode = [NSTreeNode new];
            
            // Set current node's new parent, add as child to new parent
            node.parent = newRootNode;
            [newRootNode.children addObject:node];
            
            // Add data and new right branch to new parent
            [self addObject:object withChild:newRightNode toNode:newRootNode];
            
            // Set new root
            self.root = newRootNode;
        }

        NSLog(@"Tree After: \n%@", [self printTree]); 
    }

    // If node is below min capacity (and not the root), need to join
    else if (node != self.root && node.data.count < self.nodeMinimum)
    {
        NSLog(@"Rebalance Node with Min Capacity: %@", node); 
        NSLog(@"Tree Before: \n%@", [self printTree]);  
           
        // If right sibling has more than min elements, rotate left
        if (node.next && node.next.parent == node.parent
            && node.next.data.count > self.nodeMinimum) {
            [self rotateNode:node toRight:false];
        }

        // If left sibling has more than min elements, rotate right
        else if (node.previous && node.previous.parent == node.parent
            && node.previous.data.count > self.nodeMinimum) {
            [self rotateNode:node toRight:true]; 
        }

        // Otherwise, need to merge node with one of its siblings
        else {
            [self mergeSiblingWithNode:node];
        }

        NSLog(@"Tree After: \n%@", [self printTree]);   
    }
}

- (void)rotateNode:(NSTreeNode *)node toRight:(bool)direction
{
    NSLog(@"Rotate %@", (direction ? @"Right" : @"Left"));

    // Can't rotate if no node, no siblings in direction to rotate, 
    //  or no data in sibling, or siblings not from same parent
    if (!node || !node.parent || !node.parent.data.count
        || (!direction && (!node.next 
            || node.next.parent != node.parent 
            || !node.next.data.count)) 
        || (direction && (!node.previous
            || node.previous.parent != node.parent 
            || !node.previous.data.count))) {
        return;
    }
    
    // Get index of node in children array of parent
    int indexOfChild = [node.parent indexOfChildNode:node];
    if (indexOfChild == NSNotFound) {
        NSLog(@"Warning! Could not find index of child in parent: %@", node);
        return;
    }
    
    // Insert parent data that is next to the node
    int indexOfParentData = indexOfChild - direction;
    int indexOfInsert = (direction ? 0 : node.data.count);
    [node.data insertObject:node.parent.data[indexOfParentData] 
                    atIndex:indexOfInsert];
    
    // Replace parent data with data from sibling
    NSTreeNode *sibling = (direction ? node.previous : node.next);
    int indexOfRemove = (direction ? sibling.data.count - 1 : 0); 
    [node.parent.data replaceObjectAtIndex:indexOfParentData 
                                withObject:sibling.data[indexOfRemove]];
    [sibling.data removeObjectAtIndex:indexOfRemove];
    
    // Also move corresponding child of sibling to node if needed
    if (sibling.children.count) 
    {
        indexOfRemove += (direction ? 1 : 0);   // +1 if rotating right
        NSTreeNode *child = sibling.children[indexOfRemove];
        
        // Move to node
        indexOfInsert += (direction ? 0 : 1);   // +1 if rotating left
        [node.children insertObject:child atIndex:indexOfInsert];
        child.parent = node;    // Change parents, but siblings are the same 
        
        // Remove from sibling
        [sibling.children removeObjectAtIndex:indexOfRemove];
    }
}

- (void)mergeSiblingWithNode:(NSTreeNode *)node
{
    // TODO
    NSLog(@"Merge on node: %@", node);
    
    // Sanity checks: need siblings or node to exist
    if (!node || (!node.previous && !node.next)) {
        NSLog(@"Warning! Merge called on node with no siblings!");
        return;
    }
    
    // Setup for merge
    NSTreeNode *leftNode, *rightNode, *parent;
    
    // Merge with right node if possible
    if (node.next && node.next.parent == node.parent)
    {
        leftNode = node;
        rightNode = node.next;
    }
    // If we can't merge with right node, merge left
    else if (node.previous && node.previous.parent == node.parent)
    {
        leftNode = node.previous;
        rightNode = node;
    }
    // This shouldn't happen
    else {
        NSLog(@"Warning! Reached end of merge with no siblings!");
        return;
    }
    
    // Find index of separator object in parent
    parent = leftNode.parent;
    int index = [parent indexOfChildNode:leftNode];
    
    // Transfer data & children over from parent / right node
    [leftNode.data addObject:parent.data[index]];
    for (int i = 0; i < rightNode.data.count; ++i) {
        [leftNode.data addObject:rightNode.data[i]];
    } 
    for (int i = 0; i < rightNode.children.count; ++i) {
        [leftNode.children addObject:rightNode.children[i]];
        [rightNode.children[i] setParent:leftNode]; 
    }
    
    // Clean up parent / right node
    [parent.data removeObjectAtIndex:index];
    [parent.children removeObjectAtIndex:index + 1];
    leftNode.next = rightNode.next;
    if (rightNode.next) {
        rightNode.next.previous = leftNode;
    }
    rightNode.next = rightNode.previous = rightNode.parent = nil;
    [rightNode.children removeAllObjects];
    [rightNode.data removeAllObjects]; 
    
    // Rebalance parent if needed
    if (parent.data.count < self.nodeMinimum)
    {
        // If parent is empty root, make leftNode new root
        if (parent == self.root && parent.data.count == 0)
        {
            parent.previous = parent.next = parent.parent = nil;
            [parent.children removeAllObjects];
            leftNode.parent = nil; 
            self.root = leftNode;
        }
        else {
            [self rebalanceNode:parent];
        }
    }
}


#pragma mark - NSFastEnumeration

typedef enum {
    NSTreeFastEnumerationStateMutations,
    NSTreeFastEnumerationStateCurrentNode,  
    NSTreeFastEnumerationStateCurrentNodeIndex
} NSTreeFastEnumerationState;

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id *)stackbuf count:(NSUInteger)len
{
    // First-time setup
    if (state->state == 0)
    {
        state->mutationsPtr = &state->extra[NSTreeFastEnumerationStateMutations];
        state->extra[NSTreeFastEnumerationStateCurrentNode] 
            = (unsigned long)[self getLeftMostNode:self.root];
        state->extra[NSTreeFastEnumerationStateCurrentNodeIndex] = 0;
    }
   
    // Get current node
    NSTreeNode *currentNode = (__bridge NSTreeNode *)((void *)state->extra[NSTreeFastEnumerationStateCurrentNode]);   
    
    // Loop as long as currentNode exists
    if (currentNode)
    {
        // Keep track of # items returned, index for iterating
        NSUInteger i = state->extra[NSTreeFastEnumerationStateCurrentNodeIndex]; 
        NSUInteger count = 0; 
        
        // Get current node, iterate and fill stackbuf
        while ((currentNode != nil) && (count < len))
        {
            stackbuf[count] = currentNode.data[i++];
            state->state++;
            count++;
            
            // If we reach end of data array, hop to next node
            if (i >= currentNode.data.count) {
                currentNode = currentNode.next; 
                i = 0;
            }
        }
        
        // Store state back for next loop
        state->extra[NSTreeFastEnumerationStateCurrentNode] = (unsigned long)currentNode;
        state->extra[NSTreeFastEnumerationStateCurrentNodeIndex] = i;
        
        // Set items returned to stackbuf, return count of items
        state->itemsPtr = stackbuf; 
        return count;
    }
    
    return 0;   // Done iterating
}


#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] alloc] init];
    
    if (copy) {
        [copy setRoot:[self.root copyWithZone:zone]];
        [copy setNodeCapacity:self.nodeCapacity]; 
        [copy setNodeMinimum:self.nodeMinimum]; 
    }
    
    return copy;
}


@end
