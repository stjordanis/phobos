module std.container.slist;

import std.exception, std.range, std.traits;
public import std.container.util;

/**
   Implements a simple and fast singly-linked list.
 */
struct SList(T)
{
    private struct Node
    {
        T _payload;
        Node * _next;
        this(T a, Node* b) { _payload = a; _next = b; }
    }
    private Node * _root;

    private static Node * findLastNode(Node * n)
    {
        assert(n);
        auto ahead = n._next;
        while (ahead)
        {
            n = ahead;
            ahead = n._next;
        }
        return n;
    }

    private static Node * findLastNode(Node * n, size_t limit)
    {
        assert(n && limit);
        auto ahead = n._next;
        while (ahead)
        {
            if (!--limit) break;
            n = ahead;
            ahead = n._next;
        }
        return n;
    }

    private static Node * findNode(Node * n, Node * findMe)
    {
        assert(n);
        auto ahead = n._next;
        while (ahead != findMe)
        {
            n = ahead;
            enforce(n);
            ahead = n._next;
        }
        return n;
    }

/**
Constructor taking a number of nodes
     */
    this(U)(U[] values...) if (isImplicitlyConvertible!(U, T))
    {
        insertFront(values);
    }

/**
Constructor taking an input range
     */
    this(Stuff)(Stuff stuff)
    if (isInputRange!Stuff
            && isImplicitlyConvertible!(ElementType!Stuff, T)
            && !is(Stuff == T[]))
    {
        insertFront(stuff);
    }

/**
Comparison for equality.

Complexity: $(BIGOH min(n, n1)) where $(D n1) is the number of
elements in $(D rhs).
     */
    bool opEquals(const SList rhs) const
    {
        return opEquals(rhs);
    }

    /// ditto
    bool opEquals(ref const SList rhs) const
    {
        const(Node) * n1 = _root, n2 = rhs._root;

        for (;; n1 = n1._next, n2 = n2._next)
        {
            if (!n1) return !n2;
            if (!n2 || n1._payload != n2._payload) return false;
        }
    }

/**
Defines the container's primary range, which embodies a forward range.
     */
    struct Range
    {
        private Node * _head;
        private this(Node * p) { _head = p; }

        /// Input range primitives.
        @property bool empty() const { return !_head; }

        /// ditto
        @property ref T front()
        {
            assert(!empty, "SList.Range.front: Range is empty");
            return _head._payload;
        }

        /// ditto
        void popFront()
        {
            assert(!empty, "SList.Range.popFront: Range is empty");
            _head = _head._next;
        }

        /// Forward range primitive.
        @property Range save() { return this; }

        T moveFront()
        {
            import std.algorithm : move;

            assert(!empty, "SList.Range.moveFront: Range is empty");
            return move(_head._payload);
        }

        bool sameHead(Range rhs)
        {
            return _head && _head == rhs._head;
        }
    }

    unittest
    {
        static assert(isForwardRange!Range);
    }

/**
Property returning $(D true) if and only if the container has no
elements.

Complexity: $(BIGOH 1)
     */
    @property bool empty() const
    {
        return _root is null;
    }

/**
Duplicates the container. The elements themselves are not transitively
duplicated.

Complexity: $(BIGOH n).
     */
    @property SList dup()
    {
        return SList(this[]);
    }

/**
Returns a range that iterates over all elements of the container, in
forward order.

Complexity: $(BIGOH 1)
     */
    Range opSlice()
    {
        return Range(_root);
    }

/**
Forward to $(D opSlice().front).

Complexity: $(BIGOH 1)
     */
    @property ref T front()
    {
        assert(!empty, "SList.front: List is empty");
        return _root._payload;
    }

    unittest
    {
        auto s = SList!int(1, 2, 3);
        s.front = 42;
        assert(s == SList!int(42, 2, 3));
    }

/**
Returns a new $(D SList) that's the concatenation of $(D this) and its
argument. $(D opBinaryRight) is only defined if $(D Stuff) does not
define $(D opBinary).
     */
    SList opBinary(string op, Stuff)(Stuff rhs)
    if (op == "~" && is(typeof(SList(rhs))))
    {
        auto toAdd = SList(rhs);
        if (empty) return toAdd;
        // TODO: optimize
        auto result = dup;
        auto n = findLastNode(result._root);
        n._next = toAdd._root;
        return result;
    }

/**
Removes all contents from the $(D SList).

Postcondition: $(D empty)

Complexity: $(BIGOH 1)
     */
    void clear()
    {
        _root = null;
    }

/**
Inserts $(D stuff) to the front of the container. $(D stuff) can be a
value convertible to $(D T) or a range of objects convertible to $(D
T). The stable version behaves the same, but guarantees that ranges
iterating over the container are never invalidated.

Returns: The number of elements inserted

Complexity: $(BIGOH m), where $(D m) is the length of $(D stuff)
     */
    size_t insertFront(Stuff)(Stuff stuff)
    if (isInputRange!Stuff && isImplicitlyConvertible!(ElementType!Stuff, T))
    {
        size_t result;
        Node * n, newRoot;
        foreach (item; stuff)
        {
            auto newNode = new Node(item, null);
            (newRoot ? n._next : newRoot) = newNode;
            n = newNode;
            ++result;
        }
        if (!n) return 0;
        // Last node points to the old root
        n._next = _root;
        _root = newRoot;
        return result;
    }

    /// ditto
    size_t insertFront(Stuff)(Stuff stuff)
    if (isImplicitlyConvertible!(Stuff, T))
    {
        auto newRoot = new Node(stuff, _root);
        _root = newRoot;
        return 1;
    }

/// ditto
    alias insert = insertFront;

/// ditto
    alias stableInsert = insert;

    /// ditto
    alias stableInsertFront = insertFront;

/**
Picks one value from the front of the container, removes it from the
container, and returns it.

Precondition: $(D !empty)

Returns: The element removed.

Complexity: $(BIGOH 1).
     */
    T removeAny()
    {
        import std.algorithm : move;

        assert(!empty, "SList.removeAny: List is empty");
        auto result = move(_root._payload);
        _root = _root._next;
        return result;
    }
    /// ditto
    alias stableRemoveAny = removeAny;

/**
Removes the value at the front of the container. The stable version
behaves the same, but guarantees that ranges iterating over the
container are never invalidated.

Precondition: $(D !empty)

Complexity: $(BIGOH 1).
     */
    void removeFront()
    {
        assert(!empty, "SList.removeFront: List is empty");
        _root = _root._next;
    }

    /// ditto
    alias stableRemoveFront = removeFront;

/**
Removes $(D howMany) values at the front or back of the
container. Unlike the unparameterized versions above, these functions
do not throw if they could not remove $(D howMany) elements. Instead,
if $(D howMany > n), all elements are removed. The returned value is
the effective number of elements removed. The stable version behaves
the same, but guarantees that ranges iterating over the container are
never invalidated.

Returns: The number of elements removed

Complexity: $(BIGOH howMany * log(n)).
     */
    size_t removeFront(size_t howMany)
    {
        size_t result;
        while (_root && result < howMany)
        {
            _root = _root._next;
            ++result;
        }
        return result;
    }

    /// ditto
    alias stableRemoveFront = removeFront;

/**
Inserts $(D stuff) after range $(D r), which must be a range
previously extracted from this container. Given that all ranges for a
list end at the end of the list, this function essentially appends to
the list and uses $(D r) as a potentially fast way to reach the last
node in the list. Ideally $(D r) is positioned near or at the last
element of the list.

$(D stuff) can be a value convertible to $(D T) or a range of objects
convertible to $(D T). The stable version behaves the same, but
guarantees that ranges iterating over the container are never
invalidated.

Returns: The number of values inserted.

Complexity: $(BIGOH k + m), where $(D k) is the number of elements in
$(D r) and $(D m) is the length of $(D stuff).

Examples:
--------------------
auto sl = SList!string(["a", "b", "d"]);
sl.insertAfter(sl[], "e"); // insert at the end (slowest)
assert(std.algorithm.equal(sl[], ["a", "b", "d", "e"]));
sl.insertAfter(std.range.take(sl[], 2), "c"); // insert after "b"
assert(std.algorithm.equal(sl[], ["a", "b", "c", "d", "e"]));
--------------------
     */

    size_t insertAfter(Stuff)(Range r, Stuff stuff)
    {
        if (!_root)
        {
            enforce(!r._head);
            return insertFront(stuff);
        }
        enforce(r._head);
        auto n = findLastNode(r._head);
        SList tmp;
        auto result = tmp.insertFront(stuff);
        n._next = tmp._root;
        return result;
    }

/**
Similar to $(D insertAfter) above, but accepts a range bounded in
count. This is important for ensuring fast insertions in the middle of
the list.  For fast insertions after a specified position $(D r), use
$(D insertAfter(take(r, 1), stuff)). The complexity of that operation
only depends on the number of elements in $(D stuff).

Precondition: $(D r.original.empty || r.maxLength > 0)

Returns: The number of values inserted.

Complexity: $(BIGOH k + m), where $(D k) is the number of elements in
$(D r) and $(D m) is the length of $(D stuff).
     */
    size_t insertAfter(Stuff)(Take!Range r, Stuff stuff)
    {
        auto orig = r.source;
        if (!orig._head)
        {
            // Inserting after a null range counts as insertion to the
            // front
            return insertFront(stuff);
        }
        enforce(!r.empty);
        // Find the last valid element in the range
        foreach (i; 1 .. r.maxLength)
        {
            if (!orig._head._next) break;
            orig.popFront();
        }
        // insert here
        SList tmp;
        tmp._root = orig._head._next;
        auto result = tmp.insertFront(stuff);
        orig._head._next = tmp._root;
        return result;
    }

/// ditto
    alias stableInsertAfter = insertAfter;

/**
Removes a range from the list in linear time.

Returns: An empty range.

Complexity: $(BIGOH n)
     */
    Range linearRemove(Range r)
    {
        if (!_root)
        {
            enforce(!r._head);
            return this[];
        }
        if (_root == r._head)
        {
            clear();
        }
        else
        {
            auto n = findNode(_root, r._head);
            n._next = null;
        }
        return Range(null);
    }

/**
Removes a $(D Take!Range) from the list in linear time.

Returns: A range comprehending the elements after the removed range.

Complexity: $(BIGOH n)
     */
    Range linearRemove(Take!Range r)
    {
        auto orig = r.source;
        // We have something to remove here
        if (orig._head == _root)
        {
            // remove straight from the head of the list
            for (; !r.empty; r.popFront())
            {
                removeFront();
            }
            return this[];
        }
        if (!r.maxLength)
        {
            // Nothing to remove, return the range itself
            return orig;
        }
        // Remove from somewhere in the middle of the list
        enforce(_root);
        auto n1 = findNode(_root, orig._head);
        auto n2 = findLastNode(orig._head, r.maxLength);
        n1._next = n2._next;
        return Range(n1._next);
    }

/// ditto
    alias stableLinearRemove = linearRemove;
}

unittest
{
    auto s = SList!int(1, 2, 3);
    auto n = s.findLastNode(s._root);
    assert(n && n._payload == 3);
}

unittest
{
    auto s = SList!int(1, 2, 5, 10);
    assert(walkLength(s[]) == 4);
}

unittest
{
    auto src = take([0, 1, 2, 3], 3);
    auto s = SList!int(src);
    assert(s == SList!int(0, 1, 2));
}

unittest
{
    auto a = SList!int(1, 2, 3);
    auto b = SList!int(4, 5, 6);
    // @@@BUG@@@ in compiler
    //auto c = a ~ b;
    auto d = [ 4, 5, 6 ];
    auto e = a ~ d;
    assert(e == SList!int(1, 2, 3, 4, 5, 6));
}

unittest
{
    auto a = SList!int(1, 2, 3);
    auto c = a ~ 4;
    assert(c == SList!int(1, 2, 3, 4));
}

unittest
{
    auto s = SList!int(1, 2, 3, 4);
    s.insertFront([ 42, 43 ]);
    assert(s == SList!int(42, 43, 1, 2, 3, 4));
}

unittest
{
    auto s = SList!int(1, 2, 3);
    assert(s.removeAny() == 1);
    assert(s == SList!int(2, 3));
    assert(s.stableRemoveAny() == 2);
    assert(s == SList!int(3));
}

unittest
{
    import std.algorithm : equal;

    auto s = SList!int(1, 2, 3);
    s.removeFront();
    assert(equal(s[], [2, 3]));
    s.stableRemoveFront();
    assert(equal(s[], [3]));
}

unittest
{
    auto s = SList!int(1, 2, 3, 4, 5, 6, 7);
    assert(s.removeFront(3) == 3);
    assert(s == SList!int(4, 5, 6, 7));
}

unittest
{
    auto a = SList!int(1, 2, 3);
    auto b = SList!int(1, 2, 3);
    assert(a.insertAfter(a[], b[]) == 3);
}

unittest
{
    auto s = SList!int(1, 2, 3, 4);
    auto r = take(s[], 2);
    assert(s.insertAfter(r, 5) == 1);
    assert(s == SList!int(1, 2, 5, 3, 4));
}

unittest
{
    import std.algorithm;

    // insertAfter documentation example
    auto sl = SList!string(["a", "b", "d"]);
    sl.insertAfter(sl[], "e"); // insert at the end (slowest)
    assert(std.algorithm.equal(sl[], ["a", "b", "d", "e"]));
    sl.insertAfter(std.range.take(sl[], 2), "c"); // insert after "b"
    assert(std.algorithm.equal(sl[], ["a", "b", "c", "d", "e"]));
}

unittest
{
    auto s = SList!int(1, 2, 3, 4, 5);
    auto r = s[];
    popFrontN(r, 3);
    auto r1 = s.linearRemove(r);
    assert(s == SList!int(1, 2, 3));
    assert(r1.empty);
}

unittest
{
    auto s = SList!int(1, 2, 3, 4, 5);
    auto r = s[];
    auto r1 = s.linearRemove(r);
    assert(s == SList!int());
    assert(r1.empty);
}

unittest
{
    import std.algorithm : equal;

    auto s = SList!int(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    auto r = s[];
    popFrontN(r, 3);
    auto r1 = take(r, 4);
    assert(equal(r1, [4, 5, 6, 7]));
    auto r2 = s.linearRemove(r1);
    assert(s == SList!int(1, 2, 3, 8, 9, 10));
    assert(equal(r2, [8, 9, 10]));
}

unittest
{
    auto lst = SList!int(1, 5, 42, 9);
    assert(!lst.empty);
    assert(lst.front == 1);
    assert(walkLength(lst[]) == 4);

    auto lst2 = lst ~ [ 1, 2, 3 ];
    assert(walkLength(lst2[]) == 7);

    auto lst3 = lst ~ [ 7 ];
    assert(walkLength(lst3[]) == 5);
}

unittest
{
    auto s = make!(SList!int)(1, 2, 3);
}

unittest
{
    // 5193
    static struct Data
    {
        const int val;
    }
    SList!Data list;
}

unittest
{
    auto s = SList!int([1, 2, 3]);
    s.front = 5; //test frontAssign
    assert(s.front == 5);
    auto r = s[];
    r.front = 1; //test frontAssign
    assert(r.front == 1);
}
