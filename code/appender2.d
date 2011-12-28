module code.appender2;

import core.memory;
import std.array;
import std.traits;
import std.algorithm;
import std.range;
import std.exception;
import core.bitop;

/// An ugly hack of Phobos' appender from std.array (Boost license).
/// Changes:
/// * Rewrote put method (ditched range support, added static array support)
/// * Multi-put
/// * Constructor with capacity
/// * Added assign, append and opCall operator support
/// * Added reset (like clear(this))
/// * Added getString (assumeUnique + reset)
/// * Ditched reference semantics to get rid of one level of indirection
/// * Ditched Data structure

/**
Implements an output range that appends data to an array. This is
recommended over $(D a ~= data) when appending many elements because it is more
efficient.

Example:
----
auto app = appender!string();
string b = "abcdefg";
foreach (char c; b) app.put(c);
assert(app.data == "abcdefg");

int[] a = [ 1, 2 ];
auto app2 = appender(a);
app2.put(3);
app2.put([ 4, 5, 6 ]);
assert(app2.data == [ 1, 2, 3, 4, 5, 6 ]);
----
 */
struct Appender2(A : T[], T)
{
	private
	{
		size_t _capacity;
		Unqual!(T)[] _arr;
	}

	void opAssign(U)(U item)
	{
		static if (is(typeof(_arr = item)))
		{
			// initialize to a given array.
			_arr = cast(Unqual!(T)[])item;

			if (__ctfe)
				return;

			// We want to use up as much of the block the array is in as possible.
			// if we consume all the block that we can, then array appending is
			// safe WRT built-in append, and we can use the entire block.
			auto cap = item.capacity;
			if(cap > item.length)
				item.length = cap;
			// we assume no reallocation occurred
			assert(item.ptr is _arr.ptr);
			_capacity = item.length;
		}
		else
		static if (is(typeof(_arr[] = item[])))
		{
			allocate(item.length);
			_arr = _arr.ptr[0..item.length];
			_arr[] = item[];
		}
		else
		static if (is(typeof(_arr[0] = item)))
		{
			allocate(1);
			_arr[0] = item;
		}
	}

	// Does not copy data.
	private void allocate(size_t capacity)
	{
		if (__ctfe)
		{
			_arr.length = capacity;
			_arr = _arr[0..0];
			_capacity = capacity;
			return;
		}
		auto bi = GC.qalloc(capacity * T.sizeof,
				(typeid(T[]).next.flags & 1) ? 0 : GC.BlkAttr.NO_SCAN);
		_capacity = bi.size / T.sizeof;
		_arr = (cast(Unqual!(T)*)bi.base)[0..0];
	}

/**
Construct an appender with a given array.  Note that this does not copy the
data.  If the array has a larger capacity as determined by arr.capacity,
it will be used by the appender.  After initializing an appender on an array,
appending to the original array will reallocate.
*/
	this(T[] arr)
	{
		opAssign(arr);
	}

	/// Preallocate with given capacity.
	this(size_t capacity)
	{
		allocate(capacity);
	}

	// Value semantics will probably result in undefined behavior on copy.
	// this(this) conflicts with opAssign
	//@disable this(this) {}

/**
Reserve at least newCapacity elements for appending.  Note that more elements
may be reserved than requested.  If newCapacity < capacity, then nothing is
done.
*/
	void reserve(size_t newCapacity)
	{
		if(_capacity < newCapacity)
		{
			// need to increase capacity
			immutable len = _arr.length;
			if (__ctfe)
			{
				_arr.length = newCapacity;
				_arr = _arr[0..len];
				_capacity = newCapacity;
				return;
			}
			immutable growsize = (newCapacity - len) * T.sizeof;
			auto u = GC.extend(_arr.ptr, growsize, growsize);
			if(u)
			{
				// extend worked, update the capacity
				_capacity = u / T.sizeof;
			}
			else
			{
				// didn't work, must reallocate
				auto bi = GC.qalloc(newCapacity * T.sizeof,
						(typeid(T[]).next.flags & 1) ? 0 : GC.BlkAttr.NO_SCAN);
				_capacity = bi.size / T.sizeof;
				if(len)
					memcpy(bi.base, _arr.ptr, len * T.sizeof);
				_arr = (cast(Unqual!(T)*)bi.base)[0..len];
				// leave the old data, for safety reasons
			}
		}
	}

/**
Returns the capacity of the array (the maximum number of elements the
managed array can accommodate before triggering a reallocation).  If any
appending will reallocate, $(D capacity) returns $(D 0).
 */
	@property size_t capacity()
	{
		return _capacity;
	}

/**
Returns the managed array.
 */
	@property T[] data()
	{
		return cast(typeof(return))(_arr);
	}

	// ensure we can add nelems elements, resizing as necessary
	private void ensureAddable(size_t nelems)
	{
		immutable len = _arr.length;
		immutable reqlen = len + nelems;
		if (reqlen > _capacity)
		{
			if (__ctfe)
			{
				_arr.length = reqlen;
				_arr = _arr[0..len];
				_capacity = reqlen;
				return;
			}
			// Time to reallocate.
			// We need to almost duplicate what's in druntime, except we
			// have better access to the capacity field.
			auto newlen = newCapacity(reqlen);
			// first, try extending the current block
			auto u = GC.extend(_arr.ptr, nelems * T.sizeof, (newlen - len) * T.sizeof);
			if(u)
			{
				// extend worked, update the capacity
				_capacity = u / T.sizeof;
			}
			else
			{
				// didn't work, must reallocate
				auto bi = GC.qalloc(newlen * T.sizeof,
						(typeid(T[]).next.flags & 1) ? 0 : GC.BlkAttr.NO_SCAN);
				_capacity = bi.size / T.sizeof;
				if(len)
					memcpy(bi.base, _arr.ptr, len * T.sizeof);
				_arr = (cast(Unqual!(T)*)bi.base)[0..len];
				// leave the old data, for safety reasons
			}
		}
	}

	private static size_t newCapacity(size_t newlength)
	{
		long mult = 100 + (1000L) / (bsr(newlength * T.sizeof) + 1);
		// limit to doubling the length, we don't want to grow too much
		if(mult > 200)
			mult = 200;
		auto newext = cast(size_t)((newlength * mult + 99) / 100);
		return newext > newlength ? newext : newlength;
	}
/+
/**
Appends one item to the managed array.
 */
	void put(U)(U item) if (isImplicitlyConvertible!(U, T) ||
			isSomeChar!T && isSomeChar!U)
	{
		static if (isSomeChar!T && isSomeChar!U && T.sizeof < U.sizeof)
		{
			// must do some transcoding around here
			Unqual!T[T.sizeof == 1 ? 4 : 2] encoded;
			auto len = std.utf.encode(encoded, item);
			put(encoded[0 .. len]);
		}
		else
		{
			ensureAddable(1);
			immutable len = _arr.length;
			_arr.ptr[len] = cast(Unqual!T)item;
			_arr = _arr.ptr[0 .. len + 1];
		}
	}

	// Const fixing hack.
	void put(Range)(Range items)
	if(isInputRange!(Unqual!Range) && !isInputRange!Range) {
		alias put!(Unqual!Range) p;
		p(items);
	}

/**
Appends an entire range to the managed array.
 */
	void put(Range)(Range items)
		if (isInputRange!Range && is(typeof(Appender2.init.put(items.front))))
	{
		// note, we disable this branch for appending one type of char to
		// another because we can't trust the length portion.
		static if (!(isSomeChar!T && isSomeChar!(ElementType!Range) &&
					 !is(Range == Unqual!T[]) &&
					 !is(Range == const(T)[]) &&
					 !is(Range == immutable(T)[])) &&
					is(typeof(items.length) == size_t))
		{
			// optimization -- if this type is something other than a string,
			// and we are adding exactly one element, call the version for one
			// element.
			static if(!isSomeChar!T)
			{
				if(items.length == 1)
				{
					put(items.front);
					return;
				}
			}

			// make sure we have enough space, then add the items
			ensureAddable(items.length);
			immutable len = _arr.length;
			immutable newlen = len + items.length;
			_arr = _arr.ptr[0..newlen];
			static if(is(typeof(_arr[] = items)))
			{
				_arr.ptr[len..newlen] = items;
			}
			else
			{
				for(size_t i = len; !items.empty; items.popFront(), ++i)
					_arr.ptr[i] = cast(Unqual!T)items.front;
			}
		}
		else
		{
			//pragma(msg, Range.stringof);
			// Generic input range
			for (; !items.empty; items.popFront())
			{
				put(items.front);
			}
		}
	}
+/

	/// Single-put
	void put(U)(U item)
	{
		static if (is(typeof(_arr[0   ] = item      )))
		{
			ensureAddable(1);
			immutable len = _arr.length;
			_arr.ptr[len] = item;
			_arr = _arr.ptr[0 .. len + 1];
		}
		else
		static if (is(typeof(_arr[0..1] = item[0..1])))
		{
			ensureAddable(item.length);
			immutable len = _arr.length;
			immutable newlen = len + item.length;
			_arr = _arr.ptr[0..newlen];
			_arr.ptr[len..newlen] = item;
		}
		else
		static if (isSomeChar!T && isSomeChar!U && T.sizeof < U.sizeof)
		{
			Unqual!T[T.sizeof == 1 ? 4 : 2] encoded;
			auto len = std.utf.encode(encoded, item);
			put(encoded[0 .. len]);
		}
		else
			static assert(0, "Can't append " ~ typeof(item).stringof);
	}

	/// Multi-put
	void put(U...)(U items) //if ( isOutputRange!(Unqual!T[],U) )
		if (U.length > 1 && CanPutAll!U)
	{
		size_t totalLength;
		foreach (item; items)
			static if (is(typeof(_arr[0   ] = item      )))
				totalLength += 1;
			else
			static if (is(typeof(_arr[0..1] = item[0..1])))
				totalLength += item.length;
			else
				static assert(0, "Can't append " ~ typeof(item).stringof);

		ensureAddable(totalLength);

		auto len = _arr.length;
		auto p = _arr.ptr + len;
		_arr = _arr.ptr[0..len + totalLength];

		foreach (item; items)
		{
			static if (is(typeof(_arr[0] = item)))
				*p++ = item;
			else
			{
				p[0..item.length] = item;
				p += item.length;
			}
		}
	}

	template CanPutAll(U...)
	{
		static if (U.length==0)
			enum CanPutAll = true;
		else
			enum CanPutAll = is(typeof(put!(U[0]))) && CanPutAll!(U[1..$]);
	}

	// only allow overwriting data on non-immutable and non-const data
	static if(!is(T == immutable) && !is(T == const))
	{
/**
Clears the managed array.  This allows the elements of the array to be reused
for appending.

Note that clear is disabled for immutable or const element types, due to the
possibility that $(D Appender2) might overwrite immutable data.
*/
		void clear()
		{
			_arr = _arr.ptr[0..0];
		}

/**
Shrinks the managed array to the given length.  Passing in a length that's
greater than the current array length throws an enforce exception.
*/
		void shrinkTo(size_t newlength)
		{
			enforce(newlength <= _arr.length);
			_arr = _arr.ptr[0..newlength];
		}
	}

	void reset()
	{
		_arr = null;
		_capacity = 0;
	}

	// VP 2011.12.02
	void opOpAssign(string op, U)(U item)
		if (op=="~" && is(typeof(put!U)))
	{
		put(item);
	}

	/+ blocked by http://d.puremagic.com/issues/show_bug.cgi?id=6036
	void opCall(U...)(U items)
		if (is(typeof(put(items))))
	{
		put(items);
	}
    +/

	@property size_t length()
	{
		return _arr.length;
	}

	static if(is(T == immutable(char)))
	string toString()
	{
		return data;
	}

	static if (is(T == char))
	string getString()
	{
		auto result = data;
		reset();
		return assumeUnique(result);
	}
}

alias Appender2!(char[]) StringBuilder;

private:

string test2()
{
	StringBuilder a;
	a = " ";
	a.clear();
	a.put("He", "llo");
	char[2] x = [',', ' '];
	a.put(x);
	a.put("world");
	//a ~= x;
	auto result = a.data;
	return assumeUnique(result);
}
